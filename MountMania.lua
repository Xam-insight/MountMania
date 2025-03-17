MountMania = LibStub("AceAddon-3.0"):NewAddon("MountMania", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MountMania", true)
local ACD = LibStub("AceConfigDialog-3.0")

MountManiaGlobal_CommPrefix = "MountMania"

MOUNTMANIA_WINS     = "MountManiaWins"
MOUNTMANIA_10WINS   = "MountMania10Wins"
MOUNTMANIA_MOUNT    = "MountManiaMount"
MOUNTMANIA_20MOUNTS = "MountMania20Mounts"
MOUNTMANIA_50MOUNTS = "MountMania50Mounts"

MountManiaAchievements = {
	[MOUNTMANIA_WINS]     = { ["value"] = 1,  ["label"] = L["MOUNTMANIA_ACHIEVEMENT_WINS"],    ["desc"] = L["MOUNTMANIA_ACHIEVEMENT_WINS_DESC"],                       ["icon"] = 652303, ["points"] = 10 },
	[MOUNTMANIA_10WINS]   = { ["value"] = 10, ["label"] = L["MOUNTMANIA_ACHIEVEMENT_xWINS"],   ["desc"] = string.format(L["MOUNTMANIA_ACHIEVEMENT_xWINS_DESC"], 10),   ["icon"] = 652304, ["points"] = 50, ["title"] = L["MOUNTMANIA_ACHIEVEMENT_xWINS"] },
	[MOUNTMANIA_MOUNT]    = { ["value"] = 1,  ["label"] = "OFFICIALVALUE",                     ["desc"] = L["MOUNTMANIA_ACHIEVEMENT_MOUNT_DESC"],                      ["icon"] = 652303, ["points"] = 10 },
	[MOUNTMANIA_20MOUNTS] = { ["value"] = 20, ["label"] = "OFFICIALVALUE",                     ["desc"] = string.format(L["MOUNTMANIA_ACHIEVEMENT_xMOUNTS_DESC"], 20), ["icon"] = 652305, ["points"] = 20, ["title"] = L["MOUNTMANIA_ACHIEVEMENT_xMOUNTS"] },
	[MOUNTMANIA_50MOUNTS] = { ["value"] = 50, ["label"] = L["MOUNTMANIA_ACHIEVEMENT_xMOUNTS"], ["desc"] = string.format(L["MOUNTMANIA_ACHIEVEMENT_xMOUNTS_DESC"], 50), ["icon"] = 652305, ["points"] = 50, ["title"] = L["MOUNTMANIA_ACHIEVEMENT_xMOUNTS"] },
}

MountManiaAbigailQuotes = {
	["getready"] = { quote = L["MOUNTMANIA_QUOTE_GETREADY"], sound = 6023952 },
	["comeback"] = { quote = L["MOUNTMANIA_QUOTE_END"],      sound = 6023956 },
	["whowon"]   = { quote = L["MOUNTMANIA_QUOTE_WINNER"],   sound = 6023955 },
	["1"]        = { quote = L["MOUNTMANIA_QUOTE_NEXT1"],    sound = 6023953 },
	["2"]        = { quote = L["MOUNTMANIA_QUOTE_NEXT2"],    sound = 6023954 },
}

function MountManiaQuote(quote, talkingHead, sound)
	if talkingHead then
		EZBlizzUiPop_npcDialog("ABIGAIL", MountManiaAbigailQuotes[quote].quote)
	end
	if sound then
		local willPlay -- [Sound is absent] = MountMania_PlaySoundFileId(MountManiaAbigailQuotes[quote].sound, "Dialog")
		if not willPlay then
			MountMania_PlaySoundFile(MountManiaAbigailQuotes[quote].sound, "Dialog")
		end
	end
end

function MountMania:OnInitialize()
	-- Called when the addon is loaded
	self:RegisterComm(MountManiaGlobal_CommPrefix, "ReceiveDataFrame_OnEvent")
end

-- Table to track player mount matches
local defaultData = {
	["classFileName"] = "ROGUE",
	["successes"] = 0,
}
local playerMountDataMaster
local playerMountData = {}
playerMountData.players = {}
MountDataInvitedPlayers = {}

function MountMania_Test()
	local tempMaster = playerMountDataMaster
	local tempData = {}
	tempData.difficulty = playerMountData.difficulty
	tempData.players = playerMountData.players
	
	playerMountDataMaster = MountMania_playerCharacter()
	playerMountData.difficulty = PLAYER_DIFFICULTY6
	playerMountData.players = {
		["Xamhunter"] = {
			["classFileName"] = "HUNTER",
			["successes"] = 2,
		},
		["Xamwarlock"] = {
			["classFileName"] = "WARLOCK",
			["successes"] = 4,
		},
		["Xampriest"] = {
			["classFileName"] = "PRIEST",
			["successes"] = 6,
		},
		["Xampaladin"] = {
			["classFileName"] = "PALADIN",
			["successes"] = 3,
			},
		["Xammage"] = {
			["classFileName"] = "MAGE",
			["successes"] = 8,
			},
		["Xamrogue"] = {
			["classFileName"] = "ROGUE",
			["successes"] = 1,
		},
		["Xamdruid"] = {
			["classFileName"] = "DRUID",
			["successes"] = 2,
		},
		["Xamshaman"] = {
			["classFileName"] = "SHAMAN",
			["successes"] = 9,
		},
		["Xamwarriora"] = {
			["classFileName"] = "WARRIOR",
			["successes"] = 10,
		},
		["Xamdeathknight"] = {
			["classFileName"] = "DEATHKNIGHT",
			["successes"] = 4,
		},
	}
	updateMountManiaFrame()

	C_Timer.After(20, function()
		playerMountDataMaster = tempMaster
		playerMountData.difficulty = tempData.difficulty
		playerMountData.players = tempData.players
		updateMountManiaFrame()
	end)
end

local difficultyColors = {
	[PLAYER_DIFFICULTY1]            = ITEM_QUALITY_COLORS[2].hex,
	[PLAYER_DIFFICULTY2]            = ITEM_QUALITY_COLORS[3].hex,
	[PLAYER_DIFFICULTY6]            = ITEM_QUALITY_COLORS[4].hex,
	[PLAYER_DIFFICULTY_MYTHIC_PLUS] = ITEM_QUALITY_COLORS[5].hex,
}

function MountMania_PlayerMaster()
	return playerMountDataMaster
end

function MountMania_HasPlayersData()
	return playerMountData.players and next(playerMountData.players) ~= nil
end

function getMountManiaGameTitle()
	if playerMountDataMaster then
		local title = string.format(L["MOUNTMANIA_GAME_MASTER"], MountMania_delRealm(playerMountDataMaster))
		if playerMountData.difficulty then
			title = difficultyColors[playerMountData.difficulty]..title.."|r ("..playerMountData.difficulty..")"
		end
		return title
	end
	return nil
end

function getPlayerMountData(player, data)
    if not player then
        -- If no player is provided, return the entire table
        return playerMountData
    end

    -- Return specific data for the given player if it exists
    if playerMountData.players and playerMountData.players[player] and playerMountData.players[player][data] then
        return playerMountData.players[player][data]
    end
    
    -- Return default data if available
    if defaultData and defaultData[data] then
        return defaultData[data]
    end
    
    return nil
end

local isPlayerDruid = false
local function MountMania_isPlayerDruid()
	local _, class = UnitClass("player")

    if class == "DRUID" then
		isPlayerDruid = true
	end
end

local function MountMania_isPlayerShapeShiftedDruid()
	if isPlayerDruid then
		local form = GetShapeshiftForm()
		if form ~= 0 and form ~= 3 then
			return true
		end
		
	end
	return false
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
	MountManiaMatcher:SetPoint("TOPRIGHT", MountManiaFrame, "TOPRIGHT", -35, -5)
	MountManiaMatcher:SetAlpha(1.0)
	
	MountManiaJoin:SetParent(MountManiaFrame)
	MountManiaJoin:ClearAllPoints()
	MountManiaJoin:SetScale(0.5)
	MountManiaJoin:SetPoint("TOPRIGHT", MountManiaFrame, "TOPRIGHT", -35, -5)
	MountManiaJoin:SetAlpha(1.0)
	
	updateMountManiaFrame()
	
	MountMania_isPlayerDruid()
	
	if CustomAchieverData then
		CustAc_CreateOrUpdateCategory("MountMania", nil, "Mount Mania")
		for k,v in pairs(MountManiaAchievements) do
			CustAc_CreateOrUpdateAchievement(k, "MountMania", v.icon, v.points, v.label, v.desc, v.title, v.title ~= nil)
		end
		
		local achievement = MountMania_GetAchievementDetails(40985) -- I Have That One! (1 Mount)
		CustAc_CreateOrUpdateAchievement(MOUNTMANIA_MOUNT, "MountMania", achievement.icon, nil, achievement.name)
		achievement = MountMania_GetAchievementDetails(40986) -- Mount Master (20 Mounts)
		CustAc_CreateOrUpdateAchievement(MOUNTMANIA_20MOUNTS, "MountMania", achievement.icon, nil, achievement.name)
	end
	
	if not MountManiaOptionsData["MountManiaIgnorePublicGames"] then
		MountMania_AddChatFilter()
	end
end

local publicGameJoined
local function MountManiaChatFilter(self, event, msg, author, ...)
	-- Check if the message starts with "[MountMania]"
	if not MountMania_isPlayerCharacter(author) then
		if string.match(msg, "^%[MountMania%]") then
			MountMania_askToJoin(author)
			publicGameJoined = author
		end
	end
	return false -- Allow the message to be displayed in chat
end
	
function MountMania_AddChatFilter()
	-- Register the filter for the SAY channel
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", MountManiaChatFilter)
end

function MountMania_RemoveChatFilter()
	-- Unregister the filter for the SAY channel
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", MountManiaChatFilter)
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
		local maxValue = MountManiaAchievements[achievementsData].value
		local newValue = min(maxValue +1, (MountManiaAchievementsData[player][achievementsData] or 0) + 1) -- +1 To limit saved value
		MountManiaAchievementsData[player][achievementsData] = newValue
		if CustomAchieverData and newValue == maxValue then
			CustAc_AddOnAwardPlayer(player, achievementsData)
		end
	end
end

-- Variable to store the player's current mount ID
local currentMountForMountManiaID = {}
local alreadySummoned = {}
local successCounted = {}

local function setValue(aTable, master, value)
	if aTable and master and value then
		if not aTable[master] then
			aTable[master]= {}
		end
		aTable[master][value] = true
	end
end

local function getValue(aTable, master, value)
	return aTable and master and aTable[master] and value and aTable[master][value]
end

local function resetTable(aTable, master)
	if aTable and master then
		aTable[master]= {}
	end
end

-- Function to record data when a player summons the same mount
function MountMania_RecordPlayerData(playerName, classFileName)
    -- Initialize player data if not already tracked
    if not playerMountData.players[playerName] then
        playerMountData.players[playerName] = {
            successes = 0,
			classFileName = classFileName,
        }
    end

    -- Increment the number of successes
    playerMountData.players[playerName].successes = playerMountData.players[playerName].successes + 1
	incrementMountManiaAchievementsData(playerName, MOUNTMANIA_MOUNT)
	incrementMountManiaAchievementsData(playerName, MOUNTMANIA_20MOUNTS)
	incrementMountManiaAchievementsData(playerName, MOUNTMANIA_50MOUNTS)

    -- Print a message with the updated information
    --MountMania:Print(playerName .. " has now matched " .. playerMountData.players[playerName].successes .. " mount(s) with you!")
	
	-- Update the frame with the new data
    updateMountManiaFrame()
end

function GetMountNameByMountID(mountID)
    if not mountID then return "Unknown Mount" end
    
    local name = C_MountJournal.GetMountInfoByID(mountID)
    return name or "Unknown Mount"
end

function MountMania_CompareMountWithCurrent(master, playerName, mountID, classFileName)
    -- Check if the spell cast is related to a mount
	local currentMount = currentMountForMountManiaID[master]
	if mountID and mountID == currentMount then
		if not getValue(successCounted, master, playerName) then
			setValue(successCounted, master, playerName)
			local isPlayerCharacter = MountMania_isPlayerCharacter(playerName)
			if isPlayerCharacter then
				setValue(alreadySummoned, master, mountID)
				C_Timer.After(2, function()
					DoEmote("MOUNTSPECIAL")
				end)
			end
			if playerMountDataMaster and playerMountDataMaster == master and playerName ~= playerMountDataMaster then
				-- Record the player's data
				MountMania_RecordPlayerData(playerName, classFileName)
			end
			if publicGameJoined and publicGameJoined == master and playerName ~= publicGameJoined then
				if isPlayerCharacter then
					MountMania_sendPlayerSuccess(publicGameJoined, mountID)
				end
			end
		end
	end
end

-- Function to compare another player's mount with the player's current mount
function MountMania:CheckNearbyMounts(event, unit, _, spellID)
    if MountMania_countTableElements(currentMountForMountManiaID) == 0 then
        return -- Skip if the player has no mount currently set
    end

    local mountID = C_MountJournal.GetMountFromSpell(spellID)
	local playerName = MountMania_fullName(unit)
	local classFileName
	if playerName ~= playerMountDataMaster then
		local _, englishClass = UnitClass(unit)
		classFileName = englishClass
	end
	for k in pairs(currentMountForMountManiaID) do
		MountMania_CompareMountWithCurrent(k, playerName, mountID, classFileName)
	end
	updateMountManiaFrame()
end


local function MountMania_testPossibleSummonning()
	if not IsOutdoors() or UnitOnTaxi("player") or IsFlying() then
		return SPELL_FAILED_NO_MOUNTS_ALLOWED
	end
	if IsPlayerMoving() then
		return ERR_NOT_WHILE_MOVING
	end
	if MountMania_isPlayerShapeShiftedDruid() then
		return ERR_MOUNT_SHAPESHIFTED 
	end
	return nil
end

local function MountManiaSetDifficulty(usableMounts, totalMounts)
	playerMountData.difficulty = nil
	if usableMounts and totalMounts then
		--local percent = usableMounts / totalMounts
		if usableMounts < 250 then --percent < 0.18 then
			playerMountData.difficulty = PLAYER_DIFFICULTY1
		elseif usableMounts < 500 then --percent < 0.5 then
			playerMountData.difficulty = PLAYER_DIFFICULTY2
		elseif usableMounts < 750 then --percent < 0.8 then
			playerMountData.difficulty = PLAYER_DIFFICULTY6
		else
			playerMountData.difficulty = PLAYER_DIFFICULTY_MYTHIC_PLUS
		end
	end
end

function MountManiaSummonMount()
    -- Check if the player is in an environment where mounting is allowed
	local alert = MountMania_testPossibleSummonning()
    if alert then
		UIErrorsFrame:AddMessage(alert, 1, 0, 0, 1)
        MountMania:Print(alert)
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
			if getValue(alreadySummoned, playerMountDataMaster, mountID) then
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
			CancelShapeshiftForm()
			C_MountJournal.SummonByID(mountToSummon)
		end)
		local message = L["MOUNTMANIA_QUOTE_GETREADY"]
		if not currentMountForMountManiaID[playerMountDataMaster] then
			playerMountData.players = {}
			MountDataInvitedPlayers = {}
			MountManiaSetDifficulty(#usableMounts, #mountIDs)
			MountManiaQuote("getready", false, true)
		else
			local randomQuote = ""..math.random(1, 2)
			message = L["MOUNTMANIA_QUOTE_NEXT"..randomQuote]
			MountManiaQuote(randomQuote, false, false)
		end
		MountManiaSendChatMessage(message, nil, nil, not currentMountForMountManiaID[playerMountDataMaster] and not IsInGroup() and not IsInRaid())
		currentMountForMountManiaID[playerMountDataMaster] = mountToSummon
		resetTable(successCounted, playerMountDataMaster)
		MountMania:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "CheckNearbyMounts") -- Detects successful spell casts
		MountManiaSendChatMessage(string.format(L["MOUNTMANIA_QUOTE_MOUNT"], GetMountNameByMountID(mountToSummon)), nil, wait + 1.5)
        MountMania:Print(L["MOUNTMANIA_WARN_RANDOM"])
    else
        MountMania:Print(L["MOUNTMANIA_WARN_NOMOUNT"])
		if alreadySummonedCount > 0 and alreadySummonedCount == usableCount then
			resetTable(alreadySummoned, playerMountDataMaster)
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
	
	
	MountManiaEnder:SetShown(playerMountDataMaster and MountMania_isPlayerCharacter(playerMountDataMaster) and MountMania_doTableContainsElements(playerMountData.players))
	
	MountManiaMatcher:SetShown(playerMountDataMaster and MountManiaMatcher:GetAttribute("Mount"))
	MountManiaButton_UpdateStatus(MountManiaMatcher)
	
	MountManiaJoin:SetShown(not playerMountDataMaster)
end

function getChatChannel()
    -- Check if in a group using the Instance category (for LFG)
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    else
        return "SAY"
    end
end

local function MountManiaSendChatMessageNoDelay(message, channel, nameAddon)
	SendChatMessage(((nameAddon and "[MountMania] ") or "")..message, channel)
end

function MountManiaSendChatMessage(message, channel, delay, forceMessage)
	if forceMessage or not MountManiaOptionsData["MountManiaChatMessagesDisabled"] then
		local chatChannel = channel or (IsInInstance() and "SAY")
		if not chatChannel or (chatChannel == "SAY" and MountManiaOptionsData["MountManiaChatMessagesInGroup"]) then
			chatChannel = getChatChannel()
		end
		if type(delay) == "number" and (chatChannel ~= "SAY" or IsInInstance()) then
			C_Timer.After(delay, function()
				MountManiaSendChatMessageNoDelay(message, chatChannel, forceMessage)
			end)
		elseif chatChannel ~= "SAY" or IsInInstance() or forceMessage then
			MountManiaSendChatMessageNoDelay(message, chatChannel, forceMessage)
		end
	end
end

local function MountManiaSendTopSuccessesMessage()
    -- Prepare the player data
    local topSuccesses = {}
    local topSuccessCount = 0

    -- Iterate through playerMountData.players to find the top success count
    for playerName, data in pairs(playerMountData.players) do
        if data.successes > topSuccessCount then
            topSuccessCount = data.successes
            topSuccesses = { {name = playerName, successes = data.successes} }
        elseif data.successes == topSuccessCount then
            table.insert(topSuccesses, {name = playerName, successes = data.successes})
        end
    end

    -- If no player has any success, exit the function
    if #topSuccesses == 0 then
        return
    end

	local chatChannel = (IsInInstance() and "SAY") or getChatChannel()

    -- Send the title as a separate line
    local message = MountManiaAbigailQuotes["whowon"].quote
    MountManiaSendChatMessage(message, chatChannel)
	MountManiaQuote("whowon", false, true)
	
	-- Send the separator as a separate line
	local separator = "----------------------------"
	MountManiaSendChatMessage(separator, chatChannel)

	-- Add and send each player's data as a separate message
	for _, player in ipairs(topSuccesses) do
		message = player.name .. " - " .. player.successes
		MountManiaSendChatMessage(message, chatChannel, 4, MountManiaOptionsData["MountManiaChatMessagesDisabled"] or (not IsInGroup() and not IsInRaid()))
		incrementMountManiaAchievementsData(player.name, MOUNTMANIA_WINS)
		incrementMountManiaAchievementsData(player.name, MOUNTMANIA_10WINS)
	end

	-- Send the closing separator as a separate line
	MountManiaSendChatMessage(separator, chatChannel, 4.5)

	-- Send the final message of encouragement
	message = MountManiaAbigailQuotes["comeback"].quote
	MountManiaSendChatMessage(message, chatChannel, 8)
	MountManiaQuote("comeback", false, false)
end

function MountManiaResetGame(keepScore)
	currentMountForMountManiaID[playerMountDataMaster] = nil
	resetTable(alreadySummoned, playerMountDataMaster)
	playerMountDataMaster = nil
	MountManiaEnder:Hide()
	if not keepScore then
		playerMountData.players = {}
	end
	MountDataInvitedPlayers = {}
	MountMania:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function MountManiaEndGame(reset)
	if MountMania_isPlayerCharacter(playerMountDataMaster) then
		MountMania_sendData(nil, reset or "WINNER")
		if not reset then
			MountManiaSendTopSuccessesMessage()
		end
	else
		MountMania_quitGame(playerMountDataMaster)
	end
	MountManiaResetGame(not reset)
end

-- Function to update the MountManiaMatcher button with the correct mount icon and ID
local notOwnedMountMessageSent
function UpdateMountManiaMatcherButton(mountID)
	if mountID then
		notOwnedMountMessageSent = nil
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
			MountManiaMatcher:SetAttribute("tooltipDetailBlue", { L["MOUNTMANIA_MATCHER_TOOLTIP_MESSAGE"] })
			MountManiaMatcher:SetAttribute("Status", "Disabled")
			MountManiaMatcher:SetAttribute("NotCollected", true)
		elseif not isUsable then
			MountManiaMatcher:SetAttribute("tooltipDetailRed", nil)
			MountManiaMatcher:SetAttribute("Status", "Disabled")
			MountManiaMatcher:SetAttribute("NotCollected", nil)
		else
			MountManiaMatcher:SetAttribute("tooltipDetailRed", nil)
			MountManiaMatcher:SetAttribute("Status", nil)
			MountManiaMatcher:SetAttribute("NotCollected", nil)
		end

		-- Store the mount ID for the click action
		MountManiaMatcher:SetAttribute("CurrentMount", mountID)
		
		MountManiaButton_Glow(MountManiaMatcher)
	else
		MountManiaMatcher:SetAttribute("Mount", nil)
		MountManiaMatcher:SetAttribute("CurrentMount", nil)
	end
	
	updateMountManiaFrame()
end

-- Function to summon the selected mount
function MountManiaSummonMatchingMount(mountID, notCollected)
    if not mountID then return end
	
	if notCollected then
		if not notOwnedMountMessageSent then
			MountManiaSendChatMessage(L["MOUNTMANIA_MATCHER_MESSAGE"])
			notOwnedMountMessageSent = true
		else
			DoEmote("cry", "target")
		end
		return
	end
	
	local alert = MountMania_testPossibleSummonning()
    if alert then
		UIErrorsFrame:AddMessage(alert, 1, 0, 0, 1)
		MountMania:Print(alert)
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
		CancelShapeshiftForm()
		C_MountJournal.SummonByID(mountID)
	end)
	
	--C_Timer.After(wait + 3.5, function()
	--	DoEmote("MOUNTSPECIAL")
	--end)
end

local frame = 2  -- Start at the second frame
local frameDuration = 0.1  -- 0.1s per frame
local numFrames = 8  -- Frames 2 to 8
local isAnimating = false

function MountManiaJoinTargetsGame(self)
    if isAnimating then return end  -- Prevent restarting mid-animation
    
	MountMania_askToJoin()
    
	isAnimating = true
	
    local elapsedTime = 0  
    self:SetScript("OnUpdate", function(self, elapsed)
        elapsedTime = elapsedTime + elapsed
        if elapsedTime >= frameDuration then
            elapsedTime = 0  -- Reset timer
            local left = (frame - 1) * 0.125
            self.Texture:SetTexCoord(left, left + 0.125, 0, 0.25)

            if frame == numFrames then
                frame = 1  -- Reset to first frame
				self.Texture:SetTexCoord(0, 0.125, 0, 0.25)
                isAnimating = false
                self:SetScript("OnUpdate", nil)  -- Stop animation
            else
                frame = frame + 1  -- Next frame
            end
        end
    end)
end

function MountManiaProcessReceivedMount(sender, mountID)
	MountMania:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "CheckNearbyMounts")
	UpdateMountManiaMatcherButton(mountID)
	if not playerMountDataMaster then
		MountManiaQuote("getready", false, true)
		playerMountDataMaster = sender
	end
	if playerMountDataMaster == sender or publicGameJoined == sender then
		currentMountForMountManiaID[sender] = mountID
		resetTable(successCounted, sender)
		updateMountManiaFrame()
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

function MountManiaProcessReceivedEnd(sender, winner)
	if playerMountDataMaster == sender or publicGameJoined == sender then
		if winner then
			MountManiaQuote("whowon", false, true)
		elseif playerMountDataMaster == sender then
			playerMountData.players = {}
		end
		currentMountForMountManiaID[sender] = nil
	end
	if playerMountDataMaster == sender then
		playerMountDataMaster = nil
	end
	if publicGameJoined == sender then
		publicGameJoined = nil
	end
	if not publicGameJoined then
		if not playerMountDataMaster or MountMania_isPlayerCharacter(playerMountDataMaster) then
			UpdateMountManiaMatcherButton()
		end
		if not playerMountDataMaster then
			MountMania:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		end
	end
	updateMountManiaFrame()
end

function MountManiaInvitePlayer(player)
	if currentMountForMountManiaID[playerMountDataMaster] then
		MountMania_sendData(currentMountForMountManiaID[playerMountDataMaster], nil, player)
		MountDataInvitedPlayers[player] = true
	end
end
