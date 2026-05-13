-- FS25_AvatarSwitcher
-- ModVersion: 0.5.3-alpha
-- File: AS_Main.lua
-- BuildTag: 20260513.4

AvatarSwitcher = AvatarSwitcher or {}
AvatarSwitcher.modDirectory = g_currentModDirectory or ""
AvatarSwitcher.presets = AvatarSwitcher.presets or {}
AvatarSwitcher.presetsById = AvatarSwitcher.presetsById or {}
AvatarSwitcher.initialized = false

function AvatarSwitcher:setupPaths()
    self.profilePath = getUserProfileAppPath()
    self.modSettingsDir = self.profilePath .. "modSettings/FS25_AvatarSwitcher/"
    self.presetsFile = self.modSettingsDir .. "avatarPresets.xml"
    self.templateFile = self.modDirectory .. "templates/avatarPresets.xml"
    self.gameSettingsFile = self.profilePath .. "gameSettings.xml"
end

function AvatarSwitcher:ensureSettingsFile()
    if not fileExists(self.modSettingsDir) then
        createFolder(self.modSettingsDir)
    end

    if not fileExists(self.presetsFile) then
        if fileExists(self.templateFile) then
            local ok = copyFile(self.templateFile, self.presetsFile, false)
            if ok then
                self:log("Seeded preset file: " .. tostring(self.presetsFile))
            else
                self:error("Failed to seed preset file: " .. tostring(self.presetsFile))
            end
        else
            self:error("Template file not found: " .. tostring(self.templateFile))
        end
    end
end

function AvatarSwitcher:initialize()
    if self.initialized then
        return
    end

    self:setupPaths()
    self:ensureSettingsFile()
    self:loadPresets()
    self.initialized = true

    self:log("Initialized v" .. tostring(self.VERSION))
    self:debug("Preset file: " .. tostring(self.presetsFile))
end

function AvatarSwitcher:loadMap(name)
    self:initialize()

    if self.rebuildHudLists ~= nil then
        self:rebuildHudLists()
    end
end

function AvatarSwitcher:deleteMap()
    self.initialized = false
end

function AvatarSwitcher:applyPreset(presetId)
    self:initialize()

    if presetId == nil or presetId == "" then
        self:warn("Usage: avatarUse <presetId>")
        return false
    end

    local preset = self.presetsById[presetId]
    if preset == nil then
        self:warn("Preset not found: " .. tostring(presetId))
        return false
    end

    local ok = self:writeStyleToGameSettings(preset.style)
    if not ok then
        return false
    end

    self.currentPresetId = preset.id

    local refreshed = false
    if self.tryRefreshActivePlayer ~= nil then
        refreshed = self:tryRefreshActivePlayer(preset.style, false)
    end

    self:notify("Avatar switched: " .. tostring(preset.name))

    if refreshed then
        self:debug("Applied preset with live runtime refresh: " .. tostring(preset.id) .. " (" .. tostring(preset.name) .. ")")
    else
        self:warn("Preset was saved, but live runtime refresh was not completed. Reopen the wardrobe/save, or run asProbe for diagnostics.")
    end

    return true
end

function AvatarSwitcher:listPresets(categoryFilter)
    self:initialize()

    local filter = categoryFilter
    if type(filter) == "table" then
        filter = nil
    elseif filter ~= nil then
        filter = tostring(filter)
    end

    if filter ~= nil and filter == "" then
        filter = nil
    end

    self:log("Available avatar presets" .. (filter ~= nil and (" [category=" .. filter .. "]") or "") .. ":")

    local count = 0
    for _, preset in ipairs(self.presets) do
        if filter == nil or preset.category == filter then
            count = count + 1
            self:log(string.format("  %s | %s | %s", tostring(preset.id), tostring(preset.category), tostring(preset.name)))
        end
    end

    self:log(string.format("Listed %d preset(s)", count))
    return count
end

function AvatarSwitcher:showCurrentStyle()
    self:initialize()

    local style = self:getCurrentStyleFromGameSettings()
    if style == nil then
        self:warn("No current lastPlayerStyle found in gameSettings.xml")
        return
    end

    self:log("Current lastPlayerStyle:")
    self:log(self:styleToLogString(style))
end

function AvatarSwitcher:saveCurrentAsPreset(id, ...)
    self:initialize()

    if id == nil or id == "" then
        self:warn("Usage: avatarSaveCurrent <presetId> <display name>")
        return false
    end

    local nameParts = {...}
    local displayName = table.concat(nameParts, " ")
    if displayName == nil or displayName == "" then
        displayName = id
    end

    if self.presetsById[id] ~= nil then
        self:warn("Preset id already exists. Not overwriting: " .. tostring(id))
        return false
    end

    local style = self:getCurrentStyleFromGameSettings()
    if style == nil then
        self:warn("Could not read current avatar style")
        return false
    end

    local ok = self:appendPresetToFile(id, displayName, "custom", style)
    if ok then
        self:notify("Avatar preset saved: " .. tostring(displayName))
    end

    return ok
end


function AvatarSwitcher:deletePreset(presetId)
    self:initialize()
    local ok, deletedName = self:deletePresetFromFile(presetId)
    if ok then
        self:notify("Avatar preset deleted: " .. tostring(deletedName or presetId))
    end
    return ok
end

function AvatarSwitcher:reloadPresets()
    self:initialize()
    local ok = self:loadPresets()
    if ok then
        if self.rebuildHudLists ~= nil then
            self:rebuildHudLists()
        end
        self:notify("Avatar presets reloaded")
    end
    return ok
end

addModEventListener(AvatarSwitcher)
