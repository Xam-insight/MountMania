MountMania = LibStub("AceAddon-3.0"):NewAddon("MountMania", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MountMania", true)
local ACD = LibStub("AceConfigDialog-3.0")

MountManiaGlobal_CommPrefix = "MountMania"

MOUNTMANIA_WINS = "Wins"

MountManiaAchievements = {
	[MOUNTMANIA_WINS] = { ["value"] = 1, ["label"] = L["MOUNTMANIA_ACHIEVEMENT_WINS"], ["desc"] = L["MOUNTMANIA_ACHIEVEMENT_WINS_DESC"], ["icon"] = 413588, ["points"] = 10 },
	--[MOUNTMANIA_WINS]        = { ["value"] = 1, ["label"] = L["MOUNTMANIA_ACHIEVEMENT_WINS"], ["desc"] = string.format(L["MOUNTMANIA_ACHIEVEMENT_WINS_DESC"], 1), ["icon"] = 134211, ["points"] = 10 },
}

function MountMania:OnInitialize()
	-- Called when the addon is loaded
	
	--MountMania:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "CheckNearbyMounts") -- Detects successful spell casts
end

-- Table to track player mount matches
local defaultData = {
	["name"] = "Unknown",
	["classFileName"] = "ROGUE",
}
local playerMountData = {}

function getPlayerMountData(GUID, data)
    if not GUID then
        -- If no GUID is provided, return the entire table
        return playerMountData
    end

    -- Return specific data for the given GUID if it exists
    if playerMountData[GUID] and playerMountData[GUID][data] then
        return playerMountData[GUID][data]
    end
    
    -- Return default data if available
    if defaultData and defaultData[data] then
        return defaultData[data]
    end
    
    return nil
end

function MountMania:OnEnable()
	self:RegisterChatCommand("mnt", "MountManiaChatCommand")
	self:Print(L["MOUNTMANIA_WELCOME"])
	
	if not MountManiaFrame then
        createMountManiaFrame()
    end
	if not MountManiaWindow["MountManiaHidden"] then
		MountManiaFrame:Show()
	end
	
	MountManiaMountSummoner:Hide()
	MountManiaMountSummoner:SetParent(MountManiaFrame)
	MountManiaMountSummoner:ClearAllPoints()
	MountManiaMountSummoner:SetScale(0.5)
	MountManiaMountSummoner:SetPoint("TOPLEFT", MountManiaFrame, "TOPLEFT", 10, -5)
	MountManiaMountSummoner:SetAlpha(1.0)
	MountManiaMountSummoner:Show()
	
	MountManiaEnder:Hide()
	MountManiaEnder:SetParent(MountManiaFrame)
	MountManiaEnder:ClearAllPoints()
	MountManiaEnder:SetScale(0.5)
	MountManiaEnder:SetPoint("LEFT", MountManiaMountSummoner, "RIGHT", MountManiaGlobal_BetweenObjectsGap, 0)
	MountManiaEnder:SetAlpha(1.0)
	
	if CustomAchiever then
		CustAc_CreateOrUpdateCategory("MountMania", nil, "Mount Mania")
		for k,v in pairs(MountManiaAchievements) do
			CustAc_CreateOrUpdateAchievement(k, "MountMania", v["icon"], v["points"], v["label"], v["desc"])
		end
	end

end


	--MountManiaMountSummoner:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 35, -30)
	--MountManiaMountSummoner:SetAlpha(MountManiaWindow["MountManiaFrameAlpha"])




function MountMania:MountManiaChatCommand(param)
	if param == "options" then
		MountMania_OpenOptions()
	elseif MountManiaFrame:IsShown() then
		MountManiaFrame:Hide()
	else
		MountManiaFrame:Show()
	end
end

function MountMania_OpenOptions()
	if not MountManiaOptionsLoaded then
		loadMountManiaOptions()
	end
	ACD:Open("MountMania")
end

-- Variable to store the player's current mount ID
local myCurrentMountID = nil
local alreadySummoned = {}
local successCounted = {}

-- Function to record data when a player summons the same mount
local function RecordPlayerData(unitGUID, playerName, classFileName)
    -- Initialize player data if not already tracked
    if not playerMountData[unitGUID] then
        playerMountData[unitGUID] = {
            name = playerName,
            successes = 0,
			classFileName = classFileName,
        }
    end

    -- Increment the number of successes
    playerMountData[unitGUID].successes = playerMountData[unitGUID].successes + 1

    -- Print a message with the updated information
    MountMania:Print(playerName .. " has now matched " .. playerMountData[unitGUID].successes .. " mount(s) with you!")
	
	-- Update the frame with the new data
    updateMountManiaFrame()
end

function GetMountNameByMountID(mountID)
    if not mountID then return "Unknown Mount" end
    
    local name, spellID = C_MountJournal.GetMountInfoByID(mountID)
    return name or "Unknown Mount"
end

-- Function to compare another player's mount with the player's current mount
function MountMania:CheckNearbyMounts(event, unit, _, spellID)
    if not myCurrentMountID then
        return -- Skip if the player has no mount currently set
    end

    -- Check if the spell cast is related to a mount
    local mountID = C_MountJournal.GetMountFromSpell(spellID)
    if mountID and mountID == myCurrentMountID then
		local unitGUID = UnitGUID(unit)
		if not successCounted[unitGUID] then
			successCounted[unitGUID] = true
			if unit == "player" or unitGUID == UnitGUID("player") then
				MountManiaSendChatMessage(string.format(L["MOUNTMANIA_QUOTE_MOUNT"], GetMountNameByMountID(mountID)))
				alreadySummoned[myCurrentMountID] = true
				C_Timer.After(2, function()
					DoEmote("MOUNTSPECIAL")
				end)
				return
			end
			local playerName = MountMania_fullName(unit)
			local _, englishClass = UnitClass(unit)
			local classFileName = englishClass	

			-- Record the player's data
			RecordPlayerData(unitGUID, playerName, classFileName)
			MountManiaEnder:Show()
		end
    end
end

function MountManiaSummonMount()
    -- Check if the player is in an environment where mounting is allowed
    if not IsOutdoors() or UnitOnTaxi("player") then
        MountMania:Print(L["MOUNTMANIA_WARN_ENVIRONMENT"])
        return
    end

    -- Get a list of the player's usable mounts
    local mountIDs = C_MountJournal.GetMountIDs()
    local usableMounts = {}

	local usableCount = 0
	local alreadySummonedCount = 0
    for _, mountID in ipairs(mountIDs) do
		local _, _, _, _, isUsable, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
		if isUsable and isCollected then
			usableCount = usableCount + 1
			if alreadySummoned[mountID] then
				alreadySummonedCount = alreadySummonedCount + 1
			else
				table.insert(usableMounts, mountID)
			end
		end
    end
	
    -- Summon a random mount if any are usable
    if #usableMounts > 0 then
		if not IsInGroup() and not IsInRaid() then
			MountMania:Print(L["MOUNTMANIA_WARN_PARTY"])
		end
	
        local randomIndex = math.random(1, #usableMounts)
        C_MountJournal.SummonByID(usableMounts[randomIndex])
		local message = L["MOUNTMANIA_QUOTE_GETREADY"]
		if myCurrentMountID == nil then
			playerMountData = {}
		else
			message = L["MOUNTMANIA_QUOTE_NEXT"..math.random(1, 2)]
		end
		myCurrentMountID = usableMounts[randomIndex]
		successCounted = {}
		MountMania:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "CheckNearbyMounts") -- Detects successful spell casts
		MountManiaSendChatMessage(message)
        MountMania:Print(L["MOUNTMANIA_WARN_RANDOM"])
    else
        MountMania:Print(L["MOUNTMANIA_WARN_NOMOUNT"])
		if alreadySummonedCount > 0 and alreadySummonedCount == usableCount then
			alreadySummoned = {}
		end
    end
end

function getChatChannel()
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    else
        return "SAY"
    end
end

function MountManiaSendChatMessageSecure(message, chatChannel)
    if chatChannel and  chatChannel ~= "SAY" then
        SendChatMessage(message, chatChannel)
    end
end

function MountManiaSendChatMessage(message)
    MountManiaSendChatMessageSecure(message, getChatChannel())
end

function MountManiaEndGame()
	myCurrentMountID = nil
	alreadySummoned = {}
	MountManiaEnder:Hide()
	MountMania:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	sendTopSuccessesMessage()
end

function sendTopSuccessesMessage()
    -- Prepare the player data
    local topSuccesses = {}
    local topSuccessCount = 0

    -- Iterate through playerMountData to find the top success count
    for GUID, data in pairs(playerMountData) do
        if data.successes > topSuccessCount then
            topSuccessCount = data.successes
            topSuccesses = { {name = data.name, successes = data.successes} }
        elseif data.successes == topSuccessCount then
            table.insert(topSuccesses, {name = data.name, successes = data.successes})
        end
    end

    -- If no player has any success, exit the function
    if #topSuccesses == 0 then
        return
    end

	local chatChannel = getChatChannel()

    -- Send the title as a separate line
    local message = L["MOUNTMANIA_QUOTE_WINNER"]
    MountManiaSendChatMessageSecure(message, chatChannel)
	
	C_Timer.After(5, function()
		-- Send the separator as a separate line
		message = "----------------------------"
		MountManiaSendChatMessageSecure(message, chatChannel)

		-- Add and send each player's data as a separate message
		for _, player in ipairs(topSuccesses) do
			message = player.name .. " - " .. player.successes
			MountManiaSendChatMessageSecure(message, chatChannel)
		end

		-- Send the closing separator as a separate line
		message = "----------------------------"
		MountManiaSendChatMessageSecure(message, chatChannel)
	end)

	C_Timer.After(10, function()
		-- Send the final message of encouragement
		message = L["MOUNTMANIA_QUOTE_END"]
		MountManiaSendChatMessageSecure(message, chatChannel)
	end)
end
