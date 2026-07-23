-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.0
-- File: AS_Runtime.lua
-- BuildTag: 20260510.11

AvatarSwitcher = AvatarSwitcher or {}

local function AS_isCallable(value)
    return type(value) == "function"
end

local function AS_safeCall(label, fn, ...)
    if not AS_isCallable(fn) then
        return false, "not callable"
    end

    local ok, result = pcall(fn, ...)
    if ok then
        return true, result
    end

    return false, tostring(result)
end

local function AS_matchName(name)
    name = tostring(name or ""):lower()
    return string.find(name, "style", 1, true) ~= nil
        or string.find(name, "wardrobe", 1, true) ~= nil
        or string.find(name, "character", 1, true) ~= nil
        or string.find(name, "player", 1, true) ~= nil
        or string.find(name, "appearance", 1, true) ~= nil
        or string.find(name, "visual", 1, true) ~= nil
        or string.find(name, "local", 1, true) ~= nil
end

function AvatarSwitcher:dumpMethodCandidates(label, object, maxCount)
    maxCount = maxCount or 80

    if object == nil then
        self:log("[RuntimeProbe] " .. tostring(label) .. " = <nil>")
        return 0
    end

    if type(object) ~= "table" then
        self:log("[RuntimeProbe] " .. tostring(label) .. " = " .. type(object) .. " | " .. tostring(object))
        return 0
    end

    local names = {}
    for key, value in pairs(object) do
        if AS_isCallable(value) and AS_matchName(key) then
            table.insert(names, tostring(key))
        end
    end

    table.sort(names)

    self:log(string.format("[RuntimeProbe] %s candidate method(s): %d", tostring(label), #names))
    for i, name in ipairs(names) do
        if i > maxCount then
            self:log(string.format("[RuntimeProbe]   ... %d more", #names - maxCount))
            break
        end
        self:log("[RuntimeProbe]   " .. name)
    end

    return #names
end

local function AS_logPlayerSummary(mod, label, player)
    if player == nil then
        mod:log("[RuntimeProbe] " .. tostring(label) .. " = <nil>")
        return
    end

    mod:log(string.format(
        "[RuntimeProbe] %s = %s | userId=%s | uniqueUserId=%s | farmId=%s | isOwner=%s | isControlled=%s | isLocallyControlled=%s | deleted=%s",
        tostring(label),
        tostring(player),
        tostring(player.userId),
        tostring(player.uniqueUserId),
        tostring(player.farmId),
        tostring(player.isOwner),
        tostring(player.isControlled),
        tostring(player.isLocallyControlled),
        tostring(player.isDeleted)
    ))
end

function AvatarSwitcher:findLocalPlayer()
    if g_currentMission == nil or g_currentMission.playerSystem == nil then
        return nil, "g_currentMission.playerSystem is nil"
    end

    local playerSystem = g_currentMission.playerSystem

    if playerSystem.localPlayer ~= nil then
        return playerSystem.localPlayer, "playerSystem.localPlayer"
    end

    if playerSystem.getPlayerCount ~= nil and playerSystem.getPlayerByIndex ~= nil then
        local count = 0
        local okCount, result = pcall(playerSystem.getPlayerCount, playerSystem)
        if okCount and result ~= nil then
            count = tonumber(result) or 0
        end

        for i = 1, count do
            local okPlayer, player = pcall(playerSystem.getPlayerByIndex, playerSystem, i)
            if okPlayer and player ~= nil and player.isOwner == true then
                return player, "playerSystem:getPlayerByIndex(" .. tostring(i) .. ") isOwner"
            end
        end

        for i = 1, count do
            local okPlayer, player = pcall(playerSystem.getPlayerByIndex, playerSystem, i)
            if okPlayer and player ~= nil and player.isLocallyControlled == true then
                return player, "playerSystem:getPlayerByIndex(" .. tostring(i) .. ") isLocallyControlled"
            end
        end

        for i = 1, count do
            local okPlayer, player = pcall(playerSystem.getPlayerByIndex, playerSystem, i)
            if okPlayer and player ~= nil and player.isControlled == true then
                return player, "playerSystem:getPlayerByIndex(" .. tostring(i) .. ") isControlled"
            end
        end
    end

    if type(playerSystem.players) == "table" then
        for i, player in ipairs(playerSystem.players) do
            if player ~= nil and player.isOwner == true then
                return player, "playerSystem.players[" .. tostring(i) .. "] isOwner"
            end
        end
        for i, player in ipairs(playerSystem.players) do
            if player ~= nil and player.isLocallyControlled == true then
                return player, "playerSystem.players[" .. tostring(i) .. "] isLocallyControlled"
            end
        end
        for i, player in ipairs(playerSystem.players) do
            if player ~= nil and player.isControlled == true then
                return player, "playerSystem.players[" .. tostring(i) .. "] isControlled"
            end
        end
    end

    return nil, "no local/owned player found in playerSystem"
end

local function AS_setConfigSelection(mod, playerStyle, configName, part)
    if playerStyle == nil or playerStyle.configs == nil or part == nil then
        return true
    end

    local config = playerStyle.configs[configName]
    if config == nil then
        mod:warn("[RuntimeStyle] No PlayerStyle config found for: " .. tostring(configName))
        return false
    end

    local ok = true

    if part.name ~= nil and tostring(part.name) ~= "" then
        local name = tostring(part.name)
        if config.setSelectedItemName ~= nil then
            local callOk, err = pcall(config.setSelectedItemName, config, name)
            if not callOk then
                mod:warn("[RuntimeStyle] setSelectedItemName failed for " .. tostring(configName) .. "=" .. name .. " | " .. tostring(err))
                ok = false
            end
        elseif config.getItemNameIndex ~= nil then
            local index = config:getItemNameIndex(name)
            if index ~= nil then
                config.selectedItemIndex = index
            else
                mod:warn("[RuntimeStyle] Could not resolve item name for " .. tostring(configName) .. ": " .. name)
                ok = false
            end
        else
            mod:warn("[RuntimeStyle] Config has no item-name setter for " .. tostring(configName))
            ok = false
        end
    end

    if part.color ~= nil then
        local colorIndex = tonumber(part.color)
        if colorIndex ~= nil then
            if config.setSelectedColorIndex ~= nil then
                local callOk, err = pcall(config.setSelectedColorIndex, config, colorIndex)
                if not callOk then
                    mod:warn("[RuntimeStyle] setSelectedColorIndex failed for " .. tostring(configName) .. "=" .. tostring(colorIndex) .. " | " .. tostring(err))
                    ok = false
                end
            else
                config.selectedColorIndex = colorIndex
            end
        end
    end

    return ok
end

function AvatarSwitcher:createPlayerStyleFromPresetStyle(style)
    if style == nil then
        self:warn("[RuntimeStyle] No style supplied")
        return nil
    end

    if PlayerStyle == nil or PlayerStyle.new == nil then
        self:warn("[RuntimeStyle] PlayerStyle class is not available")
        return nil
    end

    local playerStyle = PlayerStyle.new()

    if style.filename ~= nil and playerStyle.loadConfigurationXML ~= nil then
        local ok, err = pcall(playerStyle.loadConfigurationXML, playerStyle, style.filename)
        if not ok then
            self:warn("[RuntimeStyle] loadConfigurationXML failed for " .. tostring(style.filename) .. " | " .. tostring(err))
            return nil
        end
    elseif style.filename ~= nil then
        playerStyle.xmlFilename = style.filename
    end

    local allOk = true
    if style.parts ~= nil then
        for _, partName in ipairs(self.STYLE_PARTS or {}) do
            local part = style.parts[partName]
            if part ~= nil then
                local ok = AS_setConfigSelection(self, playerStyle, partName, part)
                allOk = allOk and ok
            end
        end
    end

    if playerStyle.updateDisabledOptions ~= nil then
        pcall(playerStyle.updateDisabledOptions, playerStyle)
    end

    if allOk then
        self:debug("[RuntimeStyle] Built PlayerStyle object from preset")
    else
        self:warn("[RuntimeStyle] Built PlayerStyle object, but one or more selections could not be resolved")
    end

    return playerStyle
end

function AvatarSwitcher:updateGameSettingsMemoryStyle(playerStyle)
    if playerStyle == nil or g_gameSettings == nil then
        return false
    end

    if g_gameSettings.lastPlayerStyle == nil and PlayerStyle ~= nil and PlayerStyle.new ~= nil then
        g_gameSettings.lastPlayerStyle = PlayerStyle.new()
    end

    if g_gameSettings.lastPlayerStyle ~= nil and g_gameSettings.lastPlayerStyle.copyFrom ~= nil then
        local ok, err = pcall(g_gameSettings.lastPlayerStyle.copyFrom, g_gameSettings.lastPlayerStyle, playerStyle)
        if ok then
            self:debug("[RuntimeStyle] Updated g_gameSettings.lastPlayerStyle in memory")
            return true
        else
            self:warn("[RuntimeStyle] Failed to copy style into g_gameSettings.lastPlayerStyle | " .. tostring(err))
        end
    end

    return false
end

function AvatarSwitcher:probeRuntimeAvatarObjects()
    self:initialize()
    self:log("[RuntimeProbe] Starting avatar runtime probe")

    self:dumpMethodCandidates("g_currentMission", g_currentMission)

    if g_currentMission ~= nil then
        self:dumpMethodCandidates("g_currentMission.player", g_currentMission.player)
        self:dumpMethodCandidates("g_currentMission.playerSystem", g_currentMission.playerSystem)
        self:dumpMethodCandidates("g_currentMission.playerFarm", g_currentMission.playerFarm)

        local ps = g_currentMission.playerSystem
        if ps ~= nil then
            local count = 0
            if ps.getPlayerCount ~= nil then
                local okCount, result = pcall(ps.getPlayerCount, ps)
                if okCount then
                    count = tonumber(result) or 0
                end
            elseif type(ps.players) == "table" then
                count = #ps.players
            end

            self:log("[RuntimeProbe] playerSystem player count: " .. tostring(count))
            AS_logPlayerSummary(self, "playerSystem.localPlayer", ps.localPlayer)

            if ps.getPlayerByIndex ~= nil then
                for i = 1, count do
                    local okPlayer, player = pcall(ps.getPlayerByIndex, ps, i)
                    if okPlayer then
                        AS_logPlayerSummary(self, "playerSystem:getPlayerByIndex(" .. tostring(i) .. ")", player)
                        self:dumpMethodCandidates("player[" .. tostring(i) .. "]", player, 40)
                    end
                end
            elseif type(ps.players) == "table" then
                for i, player in ipairs(ps.players) do
                    AS_logPlayerSummary(self, "playerSystem.players[" .. tostring(i) .. "]", player)
                    self:dumpMethodCandidates("player[" .. tostring(i) .. "]", player, 40)
                end
            end
        end
    end

    self:dumpMethodCandidates("g_gameSettings", g_gameSettings)
    if g_gameSettings ~= nil then
        self:dumpMethodCandidates("g_gameSettings.lastPlayerStyle", g_gameSettings.lastPlayerStyle)
    end

    self:dumpMethodCandidates("g_gui", g_gui)

    if g_gui ~= nil and g_gui.screenControllers ~= nil then
        for screenName, controller in pairs(g_gui.screenControllers) do
            local lower = tostring(screenName):lower()
            if string.find(lower, "wardrobe", 1, true) ~= nil or string.find(lower, "character", 1, true) ~= nil or string.find(lower, "player", 1, true) ~= nil then
                self:log("[RuntimeProbe] Found GUI screen controller: " .. tostring(screenName))
                self:dumpMethodCandidates("g_gui.screenControllers[" .. tostring(screenName) .. "]", controller)
            end
        end
    end

    self:log("[RuntimeProbe] Probe complete")
end

function AvatarSwitcher:tryRefreshActivePlayer(style, verbose)
    verbose = verbose == true
    if g_currentMission == nil then
        self:warn("[RuntimeRefresh] g_currentMission is nil")
        return false
    end

    local playerStyle = self:createPlayerStyleFromPresetStyle(style)
    if playerStyle == nil then
        self:warn("[RuntimeRefresh] Could not build PlayerStyle object")
        return false
    end

    self:updateGameSettingsMemoryStyle(playerStyle)

    local player, source = self:findLocalPlayer()
    if player == nil then
        self:warn("[RuntimeRefresh] Local player not found: " .. tostring(source))
        return false
    end

    if verbose then
        self:log("[RuntimeRefresh] Local player resolved from " .. tostring(source))
    else
        self:debug("[RuntimeRefresh] Local player resolved from " .. tostring(source))
    end

    local attempts = {
        { label = "player:setStyleAsync(playerStyle,false,nil,true)", object = player, method = "setStyleAsync", args = { playerStyle, false, nil, true } },
        { label = "player:setStyleAsync(playerStyle,false)", object = player, method = "setStyleAsync", args = { playerStyle, false } },
        { label = "player:setStyle(playerStyle)", object = player, method = "setStyle", args = { playerStyle } },
        { label = "player:setPlayerStyle(playerStyle)", object = player, method = "setPlayerStyle", args = { playerStyle } },
        { label = "player:applyPlayerStyle(playerStyle)", object = player, method = "applyPlayerStyle", args = { playerStyle } },
        { label = "player:applyStyle(playerStyle)", object = player, method = "applyStyle", args = { playerStyle } },
        { label = "player:loadStyle(playerStyle)", object = player, method = "loadStyle", args = { playerStyle } },
    }

    for _, attempt in ipairs(attempts) do
        local fn = attempt.object ~= nil and attempt.object[attempt.method] or nil
        if AS_isCallable(fn) then
            if verbose then
                self:log("[RuntimeRefresh] Trying " .. attempt.label)
            else
                self:debug("[RuntimeRefresh] Trying " .. attempt.label)
            end
            local ok, err = AS_safeCall(attempt.label, fn, attempt.object, unpack(attempt.args))
            if ok then
                if verbose then
                    self:log("[RuntimeRefresh] Success: " .. attempt.label)
                else
                    self:debug("[RuntimeRefresh] Success: " .. attempt.label)
                end
                return true
            else
                self:warn("[RuntimeRefresh] Failed: " .. attempt.label .. " | " .. tostring(err))
            end
        end
    end

    self:warn("[RuntimeRefresh] No live-refresh method succeeded. Run asProbe and paste the RuntimeProbe output.")
    return false
end
