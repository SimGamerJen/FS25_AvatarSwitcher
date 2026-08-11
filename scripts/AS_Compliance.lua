-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.0
-- File: AS_Compliance.lua
-- BuildTag: 20260811.1
-- ModHub retest guards for player configuration paths captured by or loaded through AvatarSwitcher.

AvatarSwitcher = AvatarSwitcher or {}

local function ASC_normalizePlayerConfig(filename)
    if filename == nil or tostring(filename) == "" then
        return nil
    end

    filename = tostring(filename)
    if Utils ~= nil and Utils.getFilename ~= nil then
        local ok, normalized = pcall(Utils.getFilename, filename)
        if ok and normalized ~= nil and tostring(normalized) ~= "" then
            return tostring(normalized)
        end
    end

    return filename
end

local function ASC_getRegisteredPlayerConfig(filename)
    local normalized = ASC_normalizePlayerConfig(filename)
    if normalized == nil then
        return false, nil
    end

    if PlayerSystem == nil or type(PlayerSystem.PLAYER_STYLES_BY_FILENAME) ~= "table" then
        -- The registry is not available yet. Do not reject a style solely because
        -- validation cannot be performed at this point in the loading sequence.
        return nil, normalized
    end

    if PlayerSystem.PLAYER_STYLES_BY_FILENAME[normalized] ~= nil then
        return true, normalized
    end

    for registeredFilename in pairs(PlayerSystem.PLAYER_STYLES_BY_FILENAME) do
        if ASC_normalizePlayerConfig(registeredFilename) == normalized then
            return true, registeredFilename
        end
    end

    return false, normalized
end

local function ASC_getSafeCurrentPlayerConfig()
    if g_gameSettings ~= nil and g_gameSettings.lastPlayerStyle ~= nil then
        local filename = g_gameSettings.lastPlayerStyle.xmlFilename
        local known, registered = ASC_getRegisteredPlayerConfig(filename)
        if known == true then
            return registered
        end
    end

    if PlayerStyle ~= nil and PlayerStyle.defaultStyle ~= nil then
        local ok, defaultStyle = pcall(PlayerStyle.defaultStyle)
        if ok and defaultStyle ~= nil then
            local known, registered = ASC_getRegisteredPlayerConfig(defaultStyle.xmlFilename)
            if known == true then
                return registered
            end
        end
    end

    if PlayerSystem ~= nil and type(PlayerSystem.PLAYER_STYLES_BY_FILENAME) == "table" then
        return next(PlayerSystem.PLAYER_STYLES_BY_FILENAME)
    end

    return nil
end

local originalCreatePlayerStyle = AvatarSwitcher.createPlayerStyleFromPresetStyle
if originalCreatePlayerStyle ~= nil then
    function AvatarSwitcher:createPlayerStyleFromPresetStyle(style)
        if style == nil then
            self:warn("[RuntimeStyle] No style supplied")
            return nil
        end

        local known, registeredFilename = ASC_getRegisteredPlayerConfig(style.filename)
        if known == false then
            self:warn("[RuntimeStyle] Refusing unknown player configuration: " .. tostring(style.filename))
            return nil
        end

        if known == true and registeredFilename ~= nil then
            style.filename = registeredFilename
        end

        local playerStyle = originalCreatePlayerStyle(self, style)
        if playerStyle == nil then
            return nil
        end

        if playerStyle.isValid ~= nil then
            local ok, valid = pcall(playerStyle.isValid, playerStyle)
            if ok and valid ~= true then
                self:warn("[RuntimeStyle] Built PlayerStyle failed validation; live refresh cancelled")
                return nil
            end
        end

        return playerStyle
    end
end

local originalWardrobeCapture = AvatarSwitcher.getCurrentStyleForWardrobeSave
if originalWardrobeCapture ~= nil then
    function AvatarSwitcher:getCurrentStyleForWardrobeSave()
        local style = originalWardrobeCapture(self)
        if style == nil then
            return nil
        end

        local known, registeredFilename = ASC_getRegisteredPlayerConfig(style.filename)
        if known == true then
            style.filename = registeredFilename
            return style
        end

        if known == false then
            local safeFilename = ASC_getSafeCurrentPlayerConfig()
            if safeFilename == nil then
                self:warn("[Wardrobe] Captured appearance has an unknown player configuration and no safe fallback is available: " .. tostring(style.filename))
                return nil
            end

            self:warn("[Wardrobe] Replaced unknown captured player configuration '" .. tostring(style.filename) .. "' with '" .. tostring(safeFilename) .. "'")
            style.filename = safeFilename
        end

        return style
    end
end
