local L = LibStub("AceLocale-3.0"):GetLocale("MountMania", true)

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
end

function updateMountManiaList(playerData)
	if playerData then
		-- Characters sorting
		local charNames = {}
		for k in pairs(playerData) do
			charNames[ #charNames + 1 ] = string.format("%03d", 1000-playerData[k]["successes"]).."#"..playerData[k]["name"].."#"..k
		end
		table.sort(charNames)

		MountManiaList = {}

		for k,v in pairs(charNames) do
			local successes, charName, charId = strsplit("#", v, 3)
				table.insert(MountManiaList, charId)
		end
	end
end

function updateMountManiaFrame()
	if MountManiaFrame and MountManiaFrame:IsShown() then
		updateMountManiaList(getPlayerMountData())
		local numItems = MountMania_countTableElements(MountManiaList)
		if numItems > 10 then
			MountManiaLineHeight = 10
		else
			MountManiaLineHeight = 15
		end
	
		local nbLignes = 0
		for index,aMountManiaLine in pairs(MountManiaLines) do
			if aMountManiaLine and MountManiaList[index] then
				aMountManiaLine:SetHeight(MountManiaLineHeight)
				createMountManiaLine(index, MountManiaList[index], aMountManiaLine)
				aMountManiaLine:Show()
				nbLignes = nbLignes + 1
			else
				aMountManiaLine:Hide()
			end
		end
		MountManiaFrame:SetHeight(58 + nbLignes * MountManiaLineHeight)
	end
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

local maxSuccesses = 0
local function GetSuccessColor(successes)
    local clampedSuccesses = math.max(0, math.min(successes, maxSuccesses)) -- Ensure the value is between 0 and maxSuccesses
    local color = {
        r = (maxSuccesses - clampedSuccesses) / maxSuccesses, -- Red decreases as successes increase
        g = clampedSuccesses / maxSuccesses, -- Green increases as successes increase
        b = 0
    }
    return color
end

function createMountManiaLine(indexCharac, GUID, aMountManiaLine)
	
	local ligneWidth = MountMania_ALLCOLS_WIDTH

	aMountManiaLine:SetAttribute("GUID", GUID)
	
	local fontstringLabel = "PlayerLabel"
	local fontstring = getFontStringFromMountManiaFramePool(indexCharac, fontstringLabel, "MountManiaPlayerLabelTemplate", aMountManiaLine)
	local color = RAID_CLASS_COLORS[getPlayerMountData(GUID, "classFileName")]
	fontstring:SetTextColor(color.r, color.g, color.b, 1.0)
	local charName = getPlayerMountData(GUID, "name")
	fontstring:SetText(charName)
	fontstring:SetPoint("LEFT", aMountManiaLine, "LEFT", MountManiaGlobal_BetweenObjectsGap, 0)

	local successes = getPlayerMountData(GUID, "successes")
	maxSuccesses = max(successes, maxSuccesses)
	local fontstringLabelSuccesses = "SuccessesLabel"
	local fontstringSuccesses = getFontStringFromMountManiaFramePool(indexCharac, fontstringLabelSuccesses, "MountManiaPlayerSuccessesTemplate", aMountManiaLine)
	color = GetSuccessColor(successes)
	fontstringSuccesses:SetTextColor(color.r, color.g, color.b, 1.0)
	fontstringSuccesses:SetText(successes)
	fontstringSuccesses:SetPoint("RIGHT", aMountManiaLine, "RIGHT", 0, 0)

	aMountManiaLine:SetWidth(ligneWidth)
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
