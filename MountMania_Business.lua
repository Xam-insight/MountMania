local L = LibStub("AceLocale-3.0"):GetLocale("MountMania", true)

-- MountManiaWindow
if not MountManiaWindow then
	MountManiaWindow = {}
end
if not MountManiaWindow["MountManiaFrameAlpha"] then
	MountManiaWindow["MountManiaFrameAlpha"] = 0.7
end

function MountMania_addRealm(aName, aRealm)
	if aName and not string.match(aName, "-") then
		if aRealm and aRealm ~= "" then
			aName = aName.."-"..aRealm
		else
			local realm = GetNormalizedRealmName() or UNKNOWN
			aName = aName.."-"..realm
		end
	end
	return aName
end

function MountMania_fullName(unit)
	local fullName = nil
	if unit then
		local playerName, playerRealm = UnitNameUnmodified(unit)
		if not UnitIsPlayer(unit) then
			return playerName
		end
		if playerName and playerName ~= "" and playerName ~= UNKNOWN then
			if not playerRealm or playerRealm == "" then
				playerRealm = GetNormalizedRealmName()
			end
			if playerRealm and playerRealm ~= "" then
				fullName = playerName.."-"..playerRealm
			end
		end
	end
	return fullName
end

function MountMania_isPlayerCharacter(aName)
	return MountMania_playerCharacter() == MountMania_addRealm(aName)
end

local MountMania_pc
function MountMania_playerCharacter()
	if not MountMania_pc then
		MountMania_pc = MountMania_fullName("player")
	end
	return MountMania_pc
end

function MountMania_countTableElements(table)
	local count = 0
	if table then
		for _ in pairs(table) do
			count = count + 1
		end
	end
	return count
end

function MountMania_doTableContainsElements(table)
	if table then
		for _ in pairs(table) do
			return true
		end
	end
	return false
end

function MountMania_PlaySound(soundID, channel, forcePlay)
	if forcePlay or not MountManiaOptionsData or not MountManiaOptionsData["MountManiaSoundsDisabled"] or not (MountManiaOptionsData["MountManiaSoundsDisabled"] == true) then
		PlaySound(soundID, channel)
	end
end

function MountMania_PlaySoundFile(soundFile, channel, forcePlay)
	if forcePlay or not MountManiaOptionsData or not MountManiaOptionsData["MountManiaSoundsDisabled"] or not (MountManiaOptionsData["MountManiaSoundsDisabled"] == true) then
		if soundHandle then
			StopSound(soundHandle)
		end
		willPlay, soundHandle = PlaySoundFile("Interface\\AddOns\\MountMania\\sound\\"..soundFile.."_"..GetLocale()..".ogg", channel, _, true)
		if not willPlay then
			willPlay, soundHandle = PlaySoundFile("Interface\\AddOns\\MountMania\\sound\\"..soundFile..".ogg", channel, _, true)
		end
	end
	return soundHandle
end

function MountMania_PlaySoundFileId(soundFileId, channel, forcePlay)
	if forcePlay or not MountManiaOptionsData or not MountManiaOptionsData["MountManiaSoundsDisabled"] or not (MountManiaOptionsData["MountManiaSoundsDisabled"] == true) then
		if soundHandle then
			StopSound(soundHandle)
		end
		willPlay, soundHandle = PlaySoundFile(soundFileId, channel)
	end
	return soundHandle
end
