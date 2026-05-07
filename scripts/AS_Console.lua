-- FS25_AvatarSwitcher
-- ModVersion: 0.1.1-alpha
-- File: AS_Console.lua
-- BuildTag: 20260507.5

AvatarSwitcher = AvatarSwitcher or {}

-- GIANTS console commands registered with a target table pass that target as the
-- first argument. These wrappers deliberately accept selfTarget first so command
-- arguments do not get shifted into the wrong slot.

function AvatarSwitcher.consoleAvatarList(selfTarget, category)
    if type(selfTarget) ~= "table" then
        category = selfTarget
    end
    AvatarSwitcher:listPresets(category)
end

function AvatarSwitcher.consoleAvatarUse(selfTarget, presetId)
    if type(selfTarget) ~= "table" then
        presetId = selfTarget
    end
    AvatarSwitcher:applyPreset(presetId)
end

function AvatarSwitcher.consoleAvatarCurrent(selfTarget)
    AvatarSwitcher:showCurrentStyle()
end

function AvatarSwitcher.consoleAvatarSaveCurrent(selfTarget, presetId, ...)
    if type(selfTarget) ~= "table" then
        AvatarSwitcher:saveCurrentAsPreset(selfTarget, presetId, ...)
    else
        AvatarSwitcher:saveCurrentAsPreset(presetId, ...)
    end
end

function AvatarSwitcher.consoleAvatarReload(selfTarget)
    AvatarSwitcher:reloadPresets()
end

function AvatarSwitcher.consoleAvatarProbe(selfTarget)
    AvatarSwitcher:probeRuntimeAvatarObjects()
end

function AvatarSwitcher.consoleAvatarRefresh(selfTarget)
    local style = AvatarSwitcher:getCurrentStyleFromGameSettings()
    if style == nil then
        AvatarSwitcher:warn("Could not read current style for runtime refresh")
        return
    end
    AvatarSwitcher:tryRefreshActivePlayer(style, true)
end

local function AS_registerConsoleCommands()
    if AvatarSwitcher.consoleCommandsRegistered then
        return
    end

    addConsoleCommand("avatarList", "List AvatarSwitcher presets. Optional: avatarList <category>", "consoleAvatarList", AvatarSwitcher)
    addConsoleCommand("avatarUse", "Apply AvatarSwitcher preset: avatarUse <presetId>", "consoleAvatarUse", AvatarSwitcher)
    addConsoleCommand("avatarCurrent", "Show current gameSettings.xml lastPlayerStyle", "consoleAvatarCurrent", AvatarSwitcher)
    addConsoleCommand("avatarSaveCurrent", "Save current lastPlayerStyle as preset: avatarSaveCurrent <presetId> <display name>", "consoleAvatarSaveCurrent", AvatarSwitcher)
    addConsoleCommand("avatarReload", "Reload AvatarSwitcher presets from XML", "consoleAvatarReload", AvatarSwitcher)
    addConsoleCommand("avatarProbe", "Probe runtime avatar/player methods for live refresh debugging", "consoleAvatarProbe", AvatarSwitcher)
    addConsoleCommand("avatarRefresh", "Attempt to refresh active player from gameSettings.xml", "consoleAvatarRefresh", AvatarSwitcher)

    addConsoleCommand("asList", "Alias for avatarList", "consoleAvatarList", AvatarSwitcher)
    addConsoleCommand("asUse", "Alias for avatarUse", "consoleAvatarUse", AvatarSwitcher)
    addConsoleCommand("asCurrent", "Alias for avatarCurrent", "consoleAvatarCurrent", AvatarSwitcher)
    addConsoleCommand("asSaveCurrent", "Alias for avatarSaveCurrent", "consoleAvatarSaveCurrent", AvatarSwitcher)
    addConsoleCommand("asReload", "Alias for avatarReload", "consoleAvatarReload", AvatarSwitcher)
    addConsoleCommand("asProbe", "Alias for avatarProbe", "consoleAvatarProbe", AvatarSwitcher)
    addConsoleCommand("asRefresh", "Alias for avatarRefresh", "consoleAvatarRefresh", AvatarSwitcher)

    AvatarSwitcher.consoleCommandsRegistered = true
    AvatarSwitcher:log("Console commands registered")
end

AS_registerConsoleCommands()
