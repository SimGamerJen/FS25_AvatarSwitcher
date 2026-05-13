-- FS25_AvatarSwitcher
-- ModVersion: 0.5.3-alpha
-- File: AS_Logger.lua

AvatarSwitcher = AvatarSwitcher or {}

AvatarSwitcher.VERSION = "0.5.3-alpha"
AvatarSwitcher.MOD_NAME = "AvatarSwitcher"
AvatarSwitcher.DEBUG = false

function AvatarSwitcher:log(message)
    print(string.format("[AvatarSwitcher] %s", tostring(message)))
end

function AvatarSwitcher:warn(message)
    print(string.format("[AvatarSwitcher/WARN] %s", tostring(message)))
end

function AvatarSwitcher:error(message)
    print(string.format("[AvatarSwitcher/ERROR] %s", tostring(message)))
end

function AvatarSwitcher:debug(message)
    if self.DEBUG then
        self:log(message)
    end
end

function AvatarSwitcher:notify(message)
    self:log(message)

    if g_currentMission ~= nil then
        if g_currentMission.addExtraPrintText ~= nil then
            g_currentMission:addExtraPrintText(tostring(message))
        elseif g_currentMission.hud ~= nil and g_currentMission.hud.showInfoMessage ~= nil then
            g_currentMission.hud:showInfoMessage(tostring(message))
        end
    end
end
