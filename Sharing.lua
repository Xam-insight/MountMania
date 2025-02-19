local function sendInfo(info, messageType)
	local targetChan = getChatChannel()
	if targetChan == "SAY" then
		local name, realm = UnitFullName("target")
		local target = name and MountMania_addRealm(name, realm)
		if target then
			MountMania:SendCommMessage(MountManiaGlobal_CommPrefix, (info and messageType.."#"..info) or messageType.."#NoData", "WHISPER", target)
		end
	else
		MountMania:SendCommMessage(MountManiaGlobal_CommPrefix, (info and messageType.."#"..info) or messageType.."#NoData", targetChan)
	end
end

function MountMania_sendData(mountID, isTheEnd)
	local info = {}
	local spellID
	if mountID then
		_, spellID  = C_MountJournal.GetMountInfoByID(mountID)
	end
	info.spell = spellID
	info.isTheEnd = isTheEnd
	info.data = getPlayerMountData()
	local s = MountMania:Serialize(info)
	sendInfo(s, "Data")
end

function MountMania:ReceiveDataFrame_OnEvent(prefix, message, distribution, sender)
	if prefix == MountManiaGlobal_CommPrefix then
		local senderFullName = MountMania_addRealm(sender)
		--MountMania:Print(time().." - Received message from "..sender..".")
		local messageType, messageMessage = strsplit("#", message, 2)
		if not MountMania_isPlayerCharacter(sender) then
			local success, o = self:Deserialize(messageMessage)
			if success == false then
				MountMania:Print(time().." - Received corrupted data from "..sender..".")
			else
				if o.spell then
					local mountID = C_MountJournal.GetMountFromSpell(o.spell)
					MountManiaProcessReceivedMount(senderFullName, mountID)
				end
				if o.data then
					MountManiaProcessReceivedData(senderFullName, o.data)
				end
				if o.isTheEnd then
					MountManiaProcessReceivedEnd(senderFullName)
				end
			end
		end
	end
end
