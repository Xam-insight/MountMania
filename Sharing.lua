local function sendInfo(info, messageType, target)
	local targetChan = getChatChannel()
	if target or targetChan == "SAY" then
		local targetToSend = target
		if not targetToSend then
			local name, realm = UnitFullName("target")
			targetToSend = name and MountMania_addRealm(name, realm)
		end
		
		if targetToSend then
			MountMania:SendCommMessage(MountManiaGlobal_CommPrefix, (info and messageType.."#"..info) or messageType.."#NoData", "WHISPER", targetToSend)
		end
	else
		MountMania:SendCommMessage(MountManiaGlobal_CommPrefix, (info and messageType.."#"..info) or messageType.."#NoData", targetChan)
	end
end

function MountMania_sendData(mountID, isTheEnd, target)
	local info = {}
	local spellID
	if mountID then
		_, spellID  = C_MountJournal.GetMountInfoByID(mountID)
	end
	info.spell = spellID
	info.isTheEnd = isTheEnd
	info.data = getPlayerMountData()
	local s = MountMania:Serialize(info)
	sendInfo(s, "Data", target)
	
	if not target then
		for k in pairs(MountDataInvitedPlayers) do
			sendInfo(s, "Data", k)
		end
	end
end

function MountMania_askToJoin(master)
	MountMania:SendCommMessage(MountManiaGlobal_CommPrefix, "JoinGame#NoData", "WHISPER", master)
end

local playerClassFileName
function MountMania_sendPlayerSuccess(master)
	local info = {}
	
	if not playerClassFileName then
		local _, englishClass = UnitClass("player")
		playerClassFileName = englishClass	
	end
	
	info.classFileName = playerClassFileName
	local s = MountMania:Serialize(info)
	sendInfo(s, "PlayerSuccess", master)
end

function MountMania_quitGame(master)
	MountMania:SendCommMessage(MountManiaGlobal_CommPrefix, "QuitGame#NoData", "WHISPER", master)
end

function MountMania:ReceiveDataFrame_OnEvent(prefix, message, distribution, sender)
	if prefix == MountManiaGlobal_CommPrefix then
		local senderFullName = MountMania_addRealm(sender)
		--MountMania:Print(time().." - Received message from "..senderFullName..".")
		local messageType, messageMessage = strsplit("#", message, 2)
		if not MountMania_isPlayerCharacter(senderFullName) then
			if messageType == "Data" then
				local success, o = self:Deserialize(messageMessage)
				if success == false then
					MountMania:Print(time().." - Received corrupted data from "..senderFullName..".")
				else
					if o.spell then
						local mountID = C_MountJournal.GetMountFromSpell(o.spell)
						MountManiaProcessReceivedMount(senderFullName, mountID)
					end
					if o.data then
						MountManiaProcessReceivedData(senderFullName, o.data)
					end
					if o.isTheEnd then
						MountManiaProcessReceivedEnd(senderFullName, o.isTheEnd == "WINNER")
					end
				end
			elseif messageType == "PlayerSuccess" then
				local classFileName
				local success, o = self:Deserialize(messageMessage)
				if success then
					classFileName = o.classFileName
				end
				MountMania_RecordPlayerData(senderFullName, classFileName)
			elseif messageType == "JoinGame" then
				MountManiaInvitePlayer(senderFullName)
			elseif messageType == "QuitGame" then
				MountDataInvitedPlayers[senderFullName] = nil
			end
		end
	end
end
