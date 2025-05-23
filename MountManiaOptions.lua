local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MountMania", true)

if not MountManiaOptionsData then
	MountManiaOptionsData = {}
end

function loadMountManiaOptions()
	local MountManiaOptions = {
		type = "group",
		name = format("%s |cffADFF2Fv%s|r", "MountMania", C_AddOns.GetAddOnMetadata("MountMania", "Version")),
		args = {
			general = {
				type = "group", order = 1,
				name = GENERAL,
				inline = true,
				args = {
					enableMountMania = {
						type = "toggle", order = 1,
						width = "full",
						name = L["ENABLE_MOUNTMANIA"],
						desc = L["ENABLE_MOUNTMANIA_DESC"],
						set = function(info, val) 
							MountManiaWindow["MountManiaIsHidden"] = not val
							if val then
								MountManiaFrame:Show()
							else
								MountManiaFrame:Hide()
							end
						end,
						get = function(info)
							local enabled = true
							if MountManiaWindow["MountManiaIsHidden"] ~= nil then
								enabled = not MountManiaWindow["MountManiaIsHidden"]
							end
							return enabled
						end
					},
					enableSound = {
						type = "toggle", order = 2,
						width = "full",
						name = ENABLE_SOUND,
						desc = ENABLE_SOUND,
						set = function(info, val) 
							MountManiaOptionsData["MountManiaSoundsDisabled"] = not val
						end,
						get = function(info)
							local enabled = true
							if MountManiaOptionsData["MountManiaSoundsDisabled"] ~= nil then
								enabled = not MountManiaOptionsData["MountManiaSoundsDisabled"]
							end
							return enabled
						end
					},
					alpha = {
						type = "range", order = 5,
						width = "full", descStyle = "",
						name = L["MOUNTMANIA_OPTIONS_ALPHA"],
						desc = L["MOUNTMANIA_OPTIONS_ALPHA_DESC"],
						get = function(i)
							return MountManiaWindow["MountManiaFrameAlpha"]
						end,
						set = function(i, v)
							MountManiaWindow["MountManiaFrameAlpha"] = v
							MountManiaFrame:SetAlpha(v)
						end,
						min = 0.2,
						max = 1.0,
						step = 0.05,
					},
				},
			},
			chatMessages = {
				type = "group", order = 2,
				name = L["MOUNTMANIA_OPTIONS_CHATMESSAGES"],
				inline = true,
				args = {
					enableChatMessages = {
						type = "toggle", order = 1,
						width = "full",
						name = L["MOUNTMANIA_OPTIONS_ALLCHATMESSAGES"],
						desc = L["MOUNTMANIA_OPTIONS_ALLCHATMESSAGES_DESC"],
						set = function(info, val) 
							MountManiaOptionsData["MountManiaChatMessagesDisabled"] = not val
						end,
						get = function(info)
							local enabled = true
							if MountManiaOptionsData["MountManiaChatMessagesDisabled"] ~= nil then
								enabled = not MountManiaOptionsData["MountManiaChatMessagesDisabled"]
							end
							return enabled
						end
					},
					chatMessagesInGroup = {
						type = "toggle", order = 2,
						width = "full",
						name = L["MOUNTMANIA_OPTIONS_CHATMESSAGES_INGROUP"],
						desc = L["MOUNTMANIA_OPTIONS_CHATMESSAGES_INGROUP_DESC"],
						set = function(info, val) 
							MountManiaOptionsData["MountManiaChatMessagesInGroup"] = val
						end,
						get = function(info)
							return MountManiaOptionsData["MountManiaChatMessagesInGroup"]
						end
					},
					publicGames = {
						type = "toggle", order = 3,
						width = "full",
						name = L["MOUNTMANIA_OPTIONS_PUBLIC_GAMES"],
						desc = L["MOUNTMANIA_OPTIONS_PUBLIC_GAMES_DESC"],
						set = function(info, val) 
							MountManiaOptionsData["MountManiaIgnorePublicGames"] = val
							if val then
								MountMania_RemoveChatFilter()
							else
								MountMania_AddChatFilter()
							end
						end,
						get = function(info)
							return MountManiaOptionsData["MountManiaIgnorePublicGames"]
						end
					},
				},
			},
		},
	}

	ACR:RegisterOptionsTable("MountMania", MountManiaOptions)

	MountManiaOptionsLoaded = true
	
	ACD:AddToBlizOptions("MountMania", "MountMania")
	ACD:SetDefaultSize("MountMania", 450, 340)
end
