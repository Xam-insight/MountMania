local L = LibStub("AceLocale-3.0"):GetLocale("MountMania", true)

-- MountManiaWindow
if not MountManiaWindow then
	MountManiaWindow = {}
end
if not MountManiaWindow["MountManiaFrameAlpha"] then
	MountManiaWindow["MountManiaFrameAlpha"] = 0.7
end

function MountMania_doTableContainsElements(table)
	if table then
		for _ in pairs(table) do
			return true
		end
	end
	return false
end

function MountMania_GetAchievementDetails(achievementID)
    local _, name, points, _, _, _, _, description, _, icon, _, _, _, _ = GetAchievementInfo(achievementID)
    return {
        name = name,
        description = description,
        icon = icon,
        points = points
    }
end
