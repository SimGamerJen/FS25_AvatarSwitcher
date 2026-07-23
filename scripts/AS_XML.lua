-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.1
-- File: AS_XML.lua

AvatarSwitcher = AvatarSwitcher or {}

AvatarSwitcher.STYLE_PARTS = {
    "facegear",
    "onepiece",
    "bottom",
    "face",
    "top",
    "gloves",
    "headgear",
    "glasses",
    "footwear",
    "hairStyle",
    "beard"
}

local function as_getXMLIntOrString(xmlFile, key)
    local value = getXMLString(xmlFile, key)
    if value == nil then
        local intValue = getXMLInt(xmlFile, key)
        if intValue ~= nil then
            value = tostring(intValue)
        end
    end
    return value
end

function AvatarSwitcher:readStyleFromXML(xmlFile, baseKey)
    if xmlFile == nil or baseKey == nil then
        return nil
    end

    if not hasXMLProperty(xmlFile, baseKey) then
        return nil
    end

    local style = {
        filename = getXMLString(xmlFile, baseKey .. "#filename"),
        parts = {}
    }

    for _, partName in ipairs(self.STYLE_PARTS) do
        local partKey = baseKey .. "." .. partName
        if hasXMLProperty(xmlFile, partKey) then
            style.parts[partName] = {
                name = getXMLString(xmlFile, partKey .. "#name"),
                color = as_getXMLIntOrString(xmlFile, partKey .. "#color")
            }
        end
    end

    return style
end

function AvatarSwitcher:writeStyleToXML(xmlFile, baseKey, style)
    if xmlFile == nil or baseKey == nil or style == nil then
        return false
    end

    if style.filename ~= nil then
        setXMLString(xmlFile, baseKey .. "#filename", style.filename)
    end

    for _, partName in ipairs(self.STYLE_PARTS) do
        local part = style.parts ~= nil and style.parts[partName] or nil
        local partKey = baseKey .. "." .. partName

        if part ~= nil then
            if part.name ~= nil then
                setXMLString(xmlFile, partKey .. "#name", tostring(part.name))
            end

            if part.color ~= nil then
                local asNumber = tonumber(part.color)
                if asNumber ~= nil then
                    setXMLInt(xmlFile, partKey .. "#color", asNumber)
                else
                    setXMLString(xmlFile, partKey .. "#color", tostring(part.color))
                end
            end
        end
    end

    return true
end

function AvatarSwitcher:styleToLogString(style)
    if style == nil then
        return "<nil>"
    end

    local parts = {}
    table.insert(parts, string.format("filename=%s", tostring(style.filename)))

    for _, partName in ipairs(self.STYLE_PARTS) do
        local part = style.parts ~= nil and style.parts[partName] or nil
        if part ~= nil then
            table.insert(parts, string.format("%s{name=%s,color=%s}", partName, tostring(part.name), tostring(part.color)))
        end
    end

    return table.concat(parts, "; ")
end

function AvatarSwitcher:getPresetCount(xmlFile)
    local count = 0
    while hasXMLProperty(xmlFile, string.format("avatarSwitcher.presets.preset(%d)", count)) do
        count = count + 1
    end
    return count
end

function AvatarSwitcher:loadPresets()
    self.presets = {}
    self.presetsById = {}

    if self.presetsFile == nil or not fileExists(self.presetsFile) then
        self:warn("Preset file does not exist: " .. tostring(self.presetsFile))
        return false
    end

    local xmlFile = loadXMLFile("avatarSwitcherPresets", self.presetsFile)
    if xmlFile == nil or xmlFile == 0 then
        self:error("Could not load preset file: " .. tostring(self.presetsFile))
        return false
    end

    local i = 0
    while true do
        local presetKey = string.format("avatarSwitcher.presets.preset(%d)", i)
        if not hasXMLProperty(xmlFile, presetKey) then
            break
        end

        local id = getXMLString(xmlFile, presetKey .. "#id")
        local name = getXMLString(xmlFile, presetKey .. "#name") or id
        local category = getXMLString(xmlFile, presetKey .. "#category") or "general"
        local sortOrder = getXMLInt(xmlFile, presetKey .. "#sortOrder") or (i + 1)
        local style = self:readStyleFromXML(xmlFile, presetKey .. ".lastPlayerStyle")

        if id ~= nil and id ~= "" and style ~= nil then
            local preset = {
                id = id,
                name = name,
                category = category,
                sortOrder = sortOrder,
                style = style
            }

            table.insert(self.presets, preset)
            self.presetsById[id] = preset
        else
            self:warn(string.format("Skipped invalid preset at index %d", i))
        end

        i = i + 1
    end

    delete(xmlFile)

    table.sort(self.presets, function(a, b)
        local ac = tostring(a.category or "")
        local bc = tostring(b.category or "")
        if ac ~= bc then
            return ac < bc
        end
        local ao = tonumber(a.sortOrder or 0) or 0
        local bo = tonumber(b.sortOrder or 0) or 0
        if ao ~= bo then
            return ao < bo
        end
        return tostring(a.name or a.id or "") < tostring(b.name or b.id or "")
    end)

    self:debug(string.format("Loaded %d avatar preset(s)", #self.presets))
    return true
end

function AvatarSwitcher:getCurrentStyleFromGameSettings()
    if self.gameSettingsFile == nil or not fileExists(self.gameSettingsFile) then
        self:warn("gameSettings.xml not found: " .. tostring(self.gameSettingsFile))
        return nil
    end

    local xmlFile = loadXMLFile("avatarSwitcherGameSettingsRead", self.gameSettingsFile)
    if xmlFile == nil or xmlFile == 0 then
        self:error("Could not read gameSettings.xml")
        return nil
    end

    local style = self:readStyleFromXML(xmlFile, "gameSettings.lastPlayerStyle")
    delete(xmlFile)
    return style
end

function AvatarSwitcher:backupGameSettingsIfNeeded()
    if self.gameSettingsFile == nil or not fileExists(self.gameSettingsFile) then
        return false
    end

    local backupFile = self.profilePath .. "gameSettings.avatarSwitcherBackup.xml"
    if not fileExists(backupFile) then
        local ok = copyFile(self.gameSettingsFile, backupFile, false)
        if ok then
            self:log("Created backup: " .. tostring(backupFile))
        else
            self:warn("Could not create backup: " .. tostring(backupFile))
        end
        return ok
    end

    return true
end

function AvatarSwitcher:writeStyleToGameSettings(style)
    if style == nil then
        self:error("No style supplied")
        return false
    end

    if self.gameSettingsFile == nil or not fileExists(self.gameSettingsFile) then
        self:error("gameSettings.xml not found: " .. tostring(self.gameSettingsFile))
        return false
    end

    self:backupGameSettingsIfNeeded()

    local xmlFile = loadXMLFile("avatarSwitcherGameSettingsWrite", self.gameSettingsFile)
    if xmlFile == nil or xmlFile == 0 then
        self:error("Could not open gameSettings.xml for writing")
        return false
    end

    local ok = self:writeStyleToXML(xmlFile, "gameSettings.lastPlayerStyle", style)
    if ok then
        saveXMLFile(xmlFile)
    end

    delete(xmlFile)

    if ok then
        self:debug("Updated gameSettings.xml lastPlayerStyle")
    end

    return ok
end

function AvatarSwitcher:appendPresetToFile(id, name, category, style)
    if id == nil or id == "" or style == nil then
        return false
    end

    category = category or "general"
    name = name or id

    local xmlFile = loadXMLFile("avatarSwitcherPresetAppend", self.presetsFile)
    if xmlFile == nil or xmlFile == 0 then
        self:error("Could not open preset file for writing")
        return false
    end

    local index = self:getPresetCount(xmlFile)
    local presetKey = string.format("avatarSwitcher.presets.preset(%d)", index)

    setXMLString(xmlFile, presetKey .. "#id", id)
    setXMLString(xmlFile, presetKey .. "#name", name)
    setXMLString(xmlFile, presetKey .. "#category", category)
    setXMLInt(xmlFile, presetKey .. "#sortOrder", index + 1)
    self:writeStyleToXML(xmlFile, presetKey .. ".lastPlayerStyle", style)

    saveXMLFile(xmlFile)
    delete(xmlFile)

    self:log(string.format("Saved current avatar as preset '%s' (%s)", id, name))
    self:loadPresets()
    return true
end

function AvatarSwitcher:writePresetsToFile(presets)
    if self.presetsFile == nil then
        self:setupPaths()
    end

    if self.modSettingsDir ~= nil and not fileExists(self.modSettingsDir) then
        createFolder(self.modSettingsDir)
    end

    local xmlFile = createXMLFile("avatarSwitcherPresetRewrite", self.presetsFile, "avatarSwitcher")
    if xmlFile == nil or xmlFile == 0 then
        self:error("Could not rewrite preset file: " .. tostring(self.presetsFile))
        return false
    end

    for i, preset in ipairs(presets or {}) do
        local key = string.format("avatarSwitcher.presets.preset(%d)", i - 1)
        setXMLString(xmlFile, key .. "#id", tostring(preset.id or ""))
        setXMLString(xmlFile, key .. "#name", tostring(preset.name or preset.id or ""))
        setXMLString(xmlFile, key .. "#category", tostring(preset.category or "general"))
        setXMLInt(xmlFile, key .. "#sortOrder", tonumber(preset.sortOrder or i) or i)
        self:writeStyleToXML(xmlFile, key .. ".lastPlayerStyle", preset.style)
    end

    saveXMLFile(xmlFile)
    delete(xmlFile)
    return true
end

function AvatarSwitcher:deletePresetFromFile(presetId)
    self:initialize()

    presetId = tostring(presetId or "")
    if presetId == "" then
        self:warn("No preset id supplied for deletion")
        return false
    end

    if self.presetsById == nil or self.presetsById[presetId] == nil then
        self:warn("Preset not found: " .. tostring(presetId))
        return false
    end

    local remaining = {}
    local deletedName = nil
    for _, preset in ipairs(self.presets or {}) do
        if tostring(preset.id or "") == presetId then
            deletedName = tostring(preset.name or preset.id or presetId)
        else
            table.insert(remaining, preset)
        end
    end

    local ok = self:writePresetsToFile(remaining)
    if not ok then
        return false
    end

    if self.currentPresetId == presetId then
        self.currentPresetId = nil
    end

    self:loadPresets()
    if self.rebuildHudLists ~= nil then
        self:rebuildHudLists(nil)
    end

    self:log("Deleted avatar preset: " .. tostring(deletedName or presetId) .. " (" .. tostring(presetId) .. ")")
    return true, deletedName or presetId
end
