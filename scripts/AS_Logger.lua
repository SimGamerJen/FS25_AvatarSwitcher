-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.1
-- File: AS_Logger.lua

AvatarSwitcher = AvatarSwitcher or {}

AvatarSwitcher.VERSION = "1.0.0.1"
AvatarSwitcher.MOD_NAME = "AvatarSwitcher"
AvatarSwitcher.DEBUG = false

function AvatarSwitcher:getText(key, fallback)
    key = tostring(key or "")
    local text = nil

    if g_i18n ~= nil and type(g_i18n.getText) == "function" then
        local ok, value = pcall(g_i18n.getText, g_i18n, key)
        if ok and value ~= nil then
            text = tostring(value)
        end
    end

    if text == nil or text == "" or text == key or string.sub(text, 1, 8) == "Missing " then
        return tostring(fallback or key)
    end

    return text
end

function AvatarSwitcher:formatText(key, fallback, ...)
    local template = self:getText(key, fallback)
    local ok, value = pcall(string.format, template, ...)
    if ok then
        return value
    end
    return template
end

function AvatarSwitcher:getCategoryDisplayName(category)
    local value = tostring(category or "general")
    if value == "all" then
        return self:getText("as_category_all", "All")
    elseif value == "general" then
        return self:getText("as_category_general", "General")
    elseif value == "custom" then
        return self:getText("as_category_custom", "Custom")
    end
    return value
end

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
