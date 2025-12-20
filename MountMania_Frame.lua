local L = LibStub("AceLocale-3.0"):GetLocale("MountMania", true)
local XITK = LibStub("XamInsightToolKit")

MountManiaFramePool = {}

MountManiaGlobal_BetweenObjectsGap = 5

MountMania_NUM_LINES = 40
local MountMania_LINE_WIDTH = 96

local MountMania_COL1_WIDTH = 150
local MountMania_COL2_WIDTH = 30
local MountMania_ALLCOLS_WIDTH = MountMania_COL1_WIDTH
	+ MountMania_COL2_WIDTH
	+ MountManiaGlobal_BetweenObjectsGap

MountManiaLineHeight = 15

MountManiaList = {}
local MountManiaLines = {}

function createMountManiaOptionsButton(parent)
	local name = "MountManiaOptionsButton"
	local iconPath = "Interface\\GossipFrame\\BinderGossipIcon"
	local tooltip = OPTIONS
	local tooltipDetail = string.format(L["MOUNTMANIA_LEFTCLICK"], OPTIONS_MENU)
	local tooltipDetailRed = string.format(L["MOUNTMANIA_RIGHTCLICK"], CLOSE)

	local optionsButton = CreateFrame("Button", name, parent, "MountManiaOptionsButtonTemplate")
	optionsButton:SetScale(0.7)
	optionsButton:SetPoint("BOTTOM", parent.Lock, "TOP", 0, 0)
	optionsButton:SetNormalTexture(iconPath)
	optionsButton:SetAttribute("tooltip", tooltip)
	optionsButton:SetAttribute("tooltipDetail", { tooltipDetail })
	optionsButton:SetAttribute("tooltipDetailRed", { tooltipDetailRed })
	optionsButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	return optionsButton
end

function createMountManiaResetButton(parent)
	local name = "MountManiaResetButton"
	local tooltip = RESET
	local tooltipDetail = RESETGAME

	local resetButton = CreateFrame("Button", name, parent, "MountManiaResetButtonTemplate")
	resetButton:SetScale(0.7)
	resetButton:SetPoint("RIGHT", MountManiaLine1, "RIGHT", 0, -2)
	resetButton:SetNormalTexture("Interface\\AddOns\\MountMania\\art\\delete.blp")
	resetButton:SetAttribute("tooltip", tooltip)
	resetButton:SetAttribute("tooltipDetail", { tooltipDetail })

	return resetButton
end

function createMountManiaFrame()
	--NewMountManiaFrame
	MountManiaFrame = CreateFrame("Frame", "MountManiaFrame", UIParent, "MountManiaFrameTemplate")
	MountManiaFrame:SetScale(MountManiaWindow["MountManiaScale"] or 1.0)
	MountManiaFrame.alphaFunc = setMountManiaFrameAlpha
	
	local fontstring = MountManiaFrame:CreateFontString("MountManiaLabel", "ARTWORK", "MountManiaWindowTitleTemplate")
    fontstring:SetText("Mount Mania")
    fontstring:SetPoint("TOP", 0, -7)

	MountManiaFrame.Lock:SetAttribute("tooltip", L["LOCKBUTTON_TOOLTIP"])
	MountManiaFrame.Lock:SetAttribute("tooltipDetail", { L["LOCKBUTTON_TOOLTIPDETAIL"] })
	
	createMountManiaOptionsButton(MountManiaFrame)

	for i = 1, MountMania_NUM_LINES do
		local line = CreateFrame("Button", "MountManiaLine"..i, MountManiaFrame.Inset, "MountManiaLineTemplate")
		if i == 1 then
			line:SetPoint("TOPLEFT", MountManiaFrame.Inset, 0, -3)
		else
			line:SetPoint("TOPLEFT", MountManiaLines[i - 1], "BOTTOMLEFT")
		end
		line:SetSize(MountManiaFrame.Inset:GetWidth(), MountManiaLineHeight)
		line:Hide()
		line:EnableMouse(false)
		MountManiaLines[i] = line
	end
	createMountManiaResetButton(MountManiaFrame)
end

local currentGame = ""
function updateMountManiaList(playerData)
	if playerData then
		-- Characters sorting
		local charNames = {}
		for k in pairs(playerData) do
			charNames[ #charNames + 1 ] = string.format("%03d", 1000-playerData[k]["successes"]).."#"..k
		end
		table.sort(charNames)

		MountManiaList = {}
		currentGame = getMountManiaGameTitle() or (MountMania_HasPlayersData() and currentGame) or ""
		table.insert(MountManiaList, currentGame)
		for k,v in pairs(charNames) do
			local successes, charName = strsplit("#", v, 3)
				table.insert(MountManiaList, charName)
		end
	end
end

local maxSuccesses = 0
function updateMountManiaFrame()
	maxSuccesses = 0
	if MountManiaFrame and MountManiaFrame:IsShown() then
		updateMountManiaList(getPlayerMountData().players)
		local numItems = XITK.countTableElements(MountManiaList)
		if numItems > 11 then
			MountManiaLineHeight = 10
		else
			MountManiaLineHeight = 15
		end
	
		local nbLignes = 0
		for index,aMountManiaLine in pairs(MountManiaLines) do
			if nbLignes == 0 then
				createMountManiaTitleLine(index, MountManiaList[index], aMountManiaLine)
				aMountManiaLine:SetHeight(MountManiaLineHeight)
				aMountManiaLine:Show()
				if not MountManiaList[index] or MountManiaList[index] == "" then
					MountManiaResetButton:Hide()
				else
					MountManiaResetButton:Show()
				end
				nbLignes = nbLignes + 1
			else
				if aMountManiaLine and MountManiaList[index] then
					aMountManiaLine:SetHeight(MountManiaLineHeight)
					createMountManiaLine(index, MountManiaList[index], aMountManiaLine)
					aMountManiaLine:Show()
					nbLignes = nbLignes + 1
				else
					aMountManiaLine:Hide()
				end
			end
		end
		MountManiaFrame:SetHeight(58 + nbLignes * MountManiaLineHeight)
		
		MountMania_updateMountCounter()
	end
	MountManiaManageButtons()
end

function getFontStringFromMountManiaFramePool(id, name, template, aMountManiaLine)
	if not MountManiaFramePool[id] then
		MountManiaFramePool[id] = {}
	end
	if not MountManiaFramePool[id][name] then
		MountManiaFramePool[id][name] = _G[aMountManiaLine:GetName()]:CreateFontString(name, "ARTWORK", template)
	end
	return MountManiaFramePool[id][name]
end

local function GetSuccessColor(successes)
	local securedMaxSuccesses = math.max(1, maxSuccesses) -- Ensure maxSuccesses > 0
    local clampedSuccesses = math.max(0, math.min(successes, securedMaxSuccesses)) -- Ensure the value is between 0 and maxSuccesses
    local color = {
        r = (securedMaxSuccesses - clampedSuccesses) / securedMaxSuccesses, -- Red decreases as successes increase
        g = clampedSuccesses / securedMaxSuccesses, -- Green increases as successes increase
        b = 0
    }
    return color
end

function createMountManiaTitleLine(indexCharac, title, aMountManiaLine)

	aMountManiaLine:SetAttribute("player", nil)
	
	local fontstringLabel = "MountManiaTitleLabel"
	local fontstring = getFontStringFromMountManiaFramePool(indexCharac, fontstringLabel, "MountManiaPlayerLabelTemplate", aMountManiaLine)
	--fontstring:SetTextColor(color.r, color.g, color.b, 1.0)
	fontstring:SetText(title)
	fontstring:SetJustifyH("CENTER")
	fontstring:SetPoint("LEFT", aMountManiaLine, "LEFT", MountManiaGlobal_BetweenObjectsGap, 0)
	fontstring:SetWidth(MountMania_ALLCOLS_WIDTH)

	aMountManiaLine:SetWidth(MountMania_ALLCOLS_WIDTH)
end

function createMountManiaLine(indexCharac, playerName, aMountManiaLine)

	aMountManiaLine:SetAttribute("player", playerName)
	
	local fontstringLabel = "MountManiaPlayerLabel"
	local fontstring = getFontStringFromMountManiaFramePool(indexCharac, fontstringLabel, "MountManiaPlayerLabelTemplate", aMountManiaLine)
	local color = RAID_CLASS_COLORS[getPlayerMountData(playerName, "classFileName")]
	fontstring:SetTextColor(color.r, color.g, color.b, 1.0)
	local charName = playerName
	fontstring:SetText(charName)
	fontstring:SetPoint("LEFT", aMountManiaLine, "LEFT", MountManiaGlobal_BetweenObjectsGap, 0)

	local successes = getPlayerMountData(playerName, "successes")
	maxSuccesses = max(successes, maxSuccesses)
	local fontstringLabelSuccesses = "SuccessesLabel"
	local fontstringSuccesses = getFontStringFromMountManiaFramePool(indexCharac, fontstringLabelSuccesses, "MountManiaPlayerSuccessesTemplate", aMountManiaLine)
	color = GetSuccessColor(successes)
	fontstringSuccesses:SetTextColor(color.r, color.g, color.b, 1.0)
	fontstringSuccesses:SetText(successes)
	fontstringSuccesses:SetPoint("RIGHT", aMountManiaLine, "RIGHT", 0, 0)

	aMountManiaLine:SetWidth(MountMania_ALLCOLS_WIDTH)
end

function callbackMountManiaWindow(aFrame)
	if MountManiaWindow["point"] then
		aFrame:ClearAllPoints()
		aFrame:SetPoint(MountManiaWindow["point"], UIParent,
			MountManiaWindow["relativePoint"], MountManiaWindow["xOffset"], MountManiaWindow["yOffset"])
	end
end

function applyMountManiaWindowOptions()
	setMountManiaFrameAlpha()
    MountManiaFrame:SetWidth(MountMania_ALLCOLS_WIDTH + 15)
	MountManiaMatcher:SetParent(MountManiaFrame)
	MountManiaMatcher:SetPoint("TOPRIGHT", MountManiaFrame, "TOPRIGHT", -35, -5)
	
	retOK, ret = pcall(callbackMountManiaWindow, MountManiaFrame)
    
	local windowLocked = MountManiaWindow["MountManiaWindowLocked"]
	MountManiaFrameLock:SetChecked(windowLocked)
	MountManiaFrame.canMove = not windowLocked
	MountManiaFrame:EnableMouse(not windowLocked)	
end

function MountManiaSaveWindowPosition()
	local point, _, relativePoint, xOffset, yOffset = MountManiaFrame:GetPoint()
	MountManiaWindow["point"] = point
	MountManiaWindow["relativePoint"] = relativePoint
	MountManiaWindow["xOffset"] = xOffset
	MountManiaWindow["yOffset"] = yOffset
end

function setMountManiaFrameAlpha()
	if MountManiaFrame and MountManiaOptionsData and MountManiaWindow["MountManiaFrameAlpha"] then
		MountManiaFrame:SetAlpha(MountManiaWindow["MountManiaFrameAlpha"])
	end
end
