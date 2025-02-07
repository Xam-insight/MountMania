local L = LibStub("AceLocale-3.0"):GetLocale("MountMania", true)

function MountManiaButtonEnter(self)
	local tooltip = self:GetAttribute("tooltip")
	local tooltipDetail = self:GetAttribute("tooltipDetail")
	local tooltipDetailGreen = self:GetAttribute("tooltipDetailGreen")
	local tooltipDetailRed = self:GetAttribute("tooltipDetailRed")
	local tooltipDetailBlue = self:GetAttribute("tooltipDetailBlue")
	local tooltipDetailPurple = self:GetAttribute("tooltipDetailPurple")
	MountManiaTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	if tooltip then
		MountManiaTooltip:SetText(tooltip)
		if tooltipDetail then
			for index,value in pairs(tooltipDetail) do
				MountManiaTooltip:AddLine(value, 1.0, 1.0, 1.0)
			end
		end
		if tooltipDetailGreen then
			for index,value in pairs(tooltipDetailGreen) do
				MountManiaTooltip:AddLine(value, 0.0, 1.0, 0.0)
			end
		end
		if tooltipDetailRed then
			for index,value in pairs(tooltipDetailRed) do
				MountManiaTooltip:AddLine(value, 1.0, 0.0, 0.0)
			end
		end
		if tooltipDetailBlue then
			for index,value in pairs(tooltipDetailBlue) do
				local leftText, rightText = strsplit("#", value, 2)
				MountManiaTooltip:AddDoubleLine(leftText, rightText, 0.25, 0.78, 0.92, 0.25, 0.78, 0.92)
			end
		end
		if tooltipDetailPurple then
			for index,value in pairs(tooltipDetailPurple) do
				local leftText, rightText = strsplit("#", value, 2)
				MountManiaTooltip:AddDoubleLine(leftText, rightText, 0.74, 0.50, 0.99, 0.74, 0.50, 0.99)
			end
		end
		MountManiaTooltip:Show()
	end
end

function MountManiaButtonLeave(self)
	MountManiaTooltip:Hide()
end

function MountManiaMountSummoner_OnLoad(self)
	self:SetAttribute("tooltip", L["MOUNTMANIA_MOUNTSUMMONER"])
	self:SetAttribute("tooltipDetail", { L["MOUNTMANIA_MOUNTSUMMONER_TOOLTIP"] })
	
	MountManiaButton_UpdateStatus(self)
end

function MountManiaEnder_OnLoad(self)
	self.Icon:SetTexture("Interface\\Icons\\Inv_checkered_flag")

	self:SetAttribute("tooltip", L["MOUNTMANIA_ENDER"])
	self:SetAttribute("tooltipDetail", { L["MOUNTMANIA_ENDER_TOOLTIP"] })
	
	MountManiaButton_UpdateStatus(self)
end

function MountManiaMatcher_OnLoad(self)
	self:SetAttribute("tooltip", L["MOUNTMANIA_MATCHER"])
	
	MountManiaButton_UpdateStatus(self)
end

function MountManiaButton_UpdateStatus(self)
	if self:GetAttribute("Status") == "Warning" then
		self:ApplyVisualState(TalentButtonUtil.BaseVisualState.RefundInvalid)
	elseif self:GetAttribute("Status") == "Disabled" then
		self:ApplyVisualState(TalentButtonUtil.BaseVisualState.Disabled)
	else
		self:ApplyVisualState(TalentButtonUtil.BaseVisualState.Normal)
	end
end

function MountManiaButton_UpdateCooldown(self)
	local cooldown = self.Cooldown
	CooldownFrame_Set(cooldown, GetTime(), 10, true, true)
end

function MountManiaButton_Glow(self)
	self.shouldGlow = true;
	self:UpdateNonStateVisuals()
	C_Timer.After(1.44, function()
		self.shouldGlow = false
		self:UpdateNonStateVisuals()
	end)
end

function MountManiaWindow_OnShow(self)
	updateMountManiaFrame()
	MountManiaWindow["MountManiaHidden"] = nil
end

function MountManiaWindow_OnHide()
	MountManiaWindow["MountManiaHidden"] = true
end
