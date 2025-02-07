MountMania = LibStub("AceAddon-3.0"):NewAddon("MountMania", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MountMania", true)
local ACD = LibStub("AceConfigDialog-3.0")

MountManiaGlobal_CommPrefix = "MountMania"

MOUNTMANIA_WINS     = "MountManiaWins"
MOUNTMANIA_10WINS   = "MountMania10Wins"
MOUNTMANIA_MOUNT    = "MountManiaMount"
MOUNTMANIA_50MOUNTS = "MountMania50Mounts"

MountManiaAchievements = {
	[MOUNTMANIA_WINS]     = { ["value"] = 1,  ["label"] = L["MOUNTMANIA_ACHIEVEMENT_WINS"],    ["desc"] = L["MOUNTMANIA_ACHIEVEMENT_WINS_DESC"],                       ["icon"] = 652303, ["points"] = 10 },
	[MOUNTMANIA_10WINS]   = { ["value"] = 10, ["label"] = L["MOUNTMANIA_ACHIEVEMENT_xWINS"],   ["desc"] = string.format(L["MOUNTMANIA_ACHIEVEMENT_xWINS_DESC"], 10),   ["icon"] = 652304, ["points"] = 20, ["title"] = L["MOUNTMANIA_ACHIEVEMENT_xWINS"] },
	[MOUNTMANIA_MOUNT]    = { ["value"] = 1,  ["label"] = L["MOUNTMANIA_ACHIEVEMENT_MOUNT"],   ["desc"] = string.format(L["MOUNTMANIA_ACHIEVEMENT_MOUNT_DESC"], 10),   ["icon"] = 652303, ["points"] = 10 },
	[MOUNTMANIA_50MOUNTS] = { ["value"] = 10, ["label"] = L["MOUNTMANIA_ACHIEVEMENT_xMOUNTS"], ["desc"] = string.format(L["MOUNTMANIA_ACHIEVEMENT_xMOUNTS_DESC"], 10), ["icon"] = 652305, ["points"] = 50, ["title"] = L["MOUNTMANIA_ACHIEVEMENT_xMOUNTS"] },
}

function MountMania:OnInitialize()
	-- Called when the addon is loaded
	self:RegisterComm(MountManiaGlobal_CommPrefix, "ReceiveDataFrame_OnEvent")
end

-- Table to track player mount matches
local defaultData = {
	["name"] = "Unknown",
	["classFileName"] = "ROGUE",
}
local playerMountDataMaster
local playerMountData = {}

function getMountManiaGameTitle()
	if playerMountDataMaster then
		return string.format(L["MOUNTMANIA_GAME_MASTER"], playerMountDataMaster)
	end
	return nil
end

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
	
	if not MountManiaAchievementsData then
		MountManiaAchievementsData = {}
	end
	
	if not MountManiaFrame then
        createMountManiaFrame()
    end
	if not MountManiaWindow["MountManiaHidden"] then
		MountManiaFrame:Show()
	end
	
	MountManiaMountSummoner:SetParent(MountManiaFrame)
	MountManiaMountSummoner:ClearAllPoints()
	MountManiaMountSummoner:SetScale(0.5)
	MountManiaMountSummoner:SetPoint("TOPLEFT", MountManiaFrame, "TOPLEFT", 10, -5)
	MountManiaMountSummoner:SetAlpha(1.0)
	
	MountManiaEnder:SetParent(MountManiaFrame)
	MountManiaEnder:ClearAllPoints()
	MountManiaEnder:SetScale(0.5)
	MountManiaEnder:SetPoint("LEFT", MountManiaMountSummoner, "RIGHT", MountManiaGlobal_BetweenObjectsGap, 0)
	MountManiaEnder:SetAlpha(1.0)
	
	MountManiaMatcher:SetParent(MountManiaFrame)
	MountManiaMatcher:ClearAllPoints()
	MountManiaMatcher:SetScale(0.5)
	MountManiaMatcher:SetPoint("TOPRIGHT", MountManiaFrame, "TOPRIGHT", -30, -5)
	MountManiaMatcher:SetAlpha(1.0)
	
	updateMountManiaFrame()
	
	if CustomAchiever then
		CustAc_CreateOrUpdateCategory("MountMania", nil, "Mount Mania")
		for k,v in pairs(MountManiaAchievements) do
			CustAc_CreateOrUpdateAchievement(k, "MountMania", v.icon, v.points, v.label, v.desc, v.title, v.title ~= nil)
		end
	end

end

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

function incrementMountManiaAchievementsData(player, achievementsData)
	if player and achievementsData then
		if not MountManiaAchievementsData[player] then
			MountManiaAchievementsData[player] = {}
		end
		local newValue = (MountManiaAchievementsData[player][achievementsData] or 0) + 1
		MountManiaAchievementsData[player][achievementsData] = newValue
		if CustomAchiever and newValue == MountManiaAchievements[achievementsData].value then
			CustAc_AddOnAwardPlayer(player, achievementsData)
		end
	end
end

-- Variable to store the player's current mount ID
local currentMountForMountManiaID = nil
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
	incrementMountManiaAchievementsData(playerName, MOUNTMANIA_MOUNT)
	incrementMountManiaAchievementsData(playerName, MOUNTMANIA_50MOUNTS)

    -- Print a message with the updated information
    MountMania:Print(playerName .. " has now matched " .. playerMountData[unitGUID].successes .. " mount(s) with you!")
	
	-- Update the frame with the new data
    updateMountManiaFrame()
end

function GetMountNameByMountID(mountID)
    if not mountID then return "Unknown Mount" end
    
    local name = C_MountJournal.GetMountInfoByID(mountID)
    return name or "Unknown Mount"
end

-- Function to compare another player's mount with the player's current mount
function MountMania:CheckNearbyMounts(event, unit, _, spellID)
    if not currentMountForMountManiaID then
        return -- Skip if the player has no mount currently set
    end

    -- Check if the spell cast is related to a mount
    local mountID = C_MountJournal.GetMountFromSpell(spellID)
	if mountID and mountID == currentMountForMountManiaID then
		local unitGUID = UnitGUID(unit)
		if not successCounted[unitGUID] then
			successCounted[unitGUID] = true
			if unit == "player" or unitGUID == UnitGUID("player") then
				alreadySummoned[currentMountForMountManiaID] = true
				C_Timer.After(2, function()
					DoEmote("MOUNTSPECIAL")
				end)
				if MountMania_isPlayerCharacter(playerMountDataMaster) then
					MountManiaSendChatMessage(string.format(L["MOUNTMANIA_QUOTE_MOUNT"], GetMountNameByMountID(mountID)))
				end
			end
			local playerName = MountMania_fullName(unit)
			if playerName ~= playerMountDataMaster then
				local _, englishClass = UnitClass(unit)
				local classFileName = englishClass	

				-- Record the player's data
				RecordPlayerData(unitGUID, playerName, classFileName)
			end
		end
	end
	updateMountManiaFrame()
end

function MountManiaSummonMount()
    -- Check if the player is in an environment where mounting is allowed
    if not IsOutdoors() or UnitOnTaxi("player") then
        MountMania:Print(SPELL_FAILED_NO_MOUNTS_ALLOWED)
        return
    end

    -- Get a list of the player's usable mounts
    local mountIDs = C_MountJournal.GetMountIDs()
    local usableMounts = {}

	local usableCount = 0
	local alreadySummonedCount = 0
	local activeMountID
    for _, mountID in ipairs(mountIDs) do
		local _, _, _, isActive, isUsable, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
		if isActive then
			activeMountID = mountID
		end
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
	
		local mountToSummon = usableMounts[math.random(1, #usableMounts)]
		local wait = 0
		if IsMounted() and activeMountID and activeMountID == mountToSummon then
			wait = 1
			Dismount()
		end
		playerMountDataMaster = MountMania_playerCharacter()
		C_Timer.After(wait, function()
			MountMania_sendData(mountToSummon)
			C_MountJournal.SummonByID(mountToSummon)
		end)
		local message = L["MOUNTMANIA_QUOTE_GETREADY"]
		if currentMountForMountManiaID == nil then
			playerMountData = {}
		else
			message = L["MOUNTMANIA_QUOTE_NEXT"..math.random(1, 2)]
		end
		currentMountForMountManiaID = mountToSummon
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
	updateMountManiaFrame()
end

function MountManiaManageButtons()
	MountManiaMountSummoner:SetShown(true)
	if playerMountDataMaster and not MountMania_isPlayerCharacter(playerMountDataMaster) then
		MountManiaMountSummoner:SetAttribute("tooltipDetailRed", { L["MOUNTMANIA_MOUNTSUMMONER_TOOLTIP_RED"] })
		MountManiaMountSummoner:SetAttribute("Status", "Warning")
	else
		MountManiaMountSummoner:SetAttribute("tooltipDetailRed", nil)
		MountManiaMountSummoner:SetAttribute("Status", nil)
	end
	MountManiaButton_UpdateStatus(MountManiaMountSummoner)
	
	
	MountManiaEnder:SetShown(playerMountDataMaster and MountMania_isPlayerCharacter(playerMountDataMaster) and MountMania_doTableContainsElements(playerMountData))
	
	MountManiaMatcher:SetShown(playerMountDataMaster and MountManiaMatcher:GetAttribute("Mount"))
	MountManiaButton_UpdateStatus(MountManiaMatcher)
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

local function MountManiaSendTopSuccessesMessage()
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
			incrementMountManiaAchievementsData(player.name, MOUNTMANIA_WINS)
			incrementMountManiaAchievementsData(player.name, MOUNTMANIA_10WINS)
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

function MountManiaEndGame()
	if MountMania_isPlayerCharacter(playerMountDataMaster) then
		playerMountDataMaster = nil
		MountMania_sendData(nil, true)
		currentMountForMountManiaID = nil
		alreadySummoned = {}
		MountManiaEnder:Hide()
		MountMania:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		MountManiaSendTopSuccessesMessage()
	end
end

-- Function to update the MountManiaMatcher button with the correct mount icon and ID
function UpdateMountManiaButton(mountID)
	-- Get mount details
	local name, spellID, icon = C_MountJournal.GetMountInfoByID(mountID)
	
	if not spellID or not icon then return end -- Ensure valid mount data

	-- Set the button icon
	MountManiaMatcher.Icon:SetTexture(icon)
	MountManiaMatcher:SetAttribute("Mount", true)
	
	MountManiaMatcher:SetAttribute("tooltipDetail", { string.format(L["MOUNTMANIA_MATCHER_TOOLTIP"], name) })
	local _, _, _, _, isUsable, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
	
	if not isCollected then
		MountManiaMatcher:SetAttribute("tooltipDetailRed", { MOUNT_JOURNAL_NOT_COLLECTED })
		MountManiaMatcher:SetAttribute("Status", "Disabled")
	elseif not isUsable then
		MountManiaMatcher:SetAttribute("tooltipDetailRed", nil)
		MountManiaMatcher:SetAttribute("Status", "Disabled")
	else
		MountManiaMatcher:SetAttribute("tooltipDetailRed", nil)
		MountManiaMatcher:SetAttribute("Status", nil)
	end

	-- Store the mount ID for the click action
	MountManiaMatcher:SetAttribute("CurrentMount", mountID)
end

-- Function to summon the selected mount
function MountManiaSummonMatchingMount(mountID)
    if not mountID then return end
	
	if not IsOutdoors() or UnitOnTaxi("player") then
		MountMania:Print(SPELL_FAILED_NO_MOUNTS_ALLOWED)
		return
    end
	
	local wait = 0
	if IsMounted() then
		local _, _, _, isActive = C_MountJournal.GetMountInfoByID(mountID)
		if isActive then
			wait = 1
			Dismount()
		end
	end
	
	C_Timer.After(wait, function()
		C_MountJournal.SummonByID(mountID)
	end)
	
	--C_Timer.After(wait + 3.5, function()
	--	DoEmote("MOUNTSPECIAL")
	--end)
end

function MountManiaProcessReceivedMount(sender, mountID)
	MountMania:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "CheckNearbyMounts")
	UpdateMountManiaButton(mountID)
	if not playerMountDataMaster then
		playerMountDataMaster = sender
	end
	if playerMountDataMaster == sender then
		currentMountForMountManiaID = mountID
		successCounted = {}
	end
end

function MountManiaProcessReceivedData(sender, data)
	if not playerMountDataMaster then
		playerMountDataMaster = sender
	end
	if playerMountDataMaster == sender then
		playerMountData = data
		updateMountManiaFrame()
	end
end

function MountManiaProcessReceivedEnd(sender)
	if playerMountDataMaster == sender then
		playerMountDataMaster = nil
		currentMountForMountManiaID = nil
		MountMania:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		updateMountManiaFrame()
	end
end