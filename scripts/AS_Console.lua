-- FS25_AvatarSwitcher
-- ModVersion: 0.5.3-alpha
-- File: AS_Console.lua
-- BuildTag: 20260513.4

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

function AvatarSwitcher.consoleAvatarDelete(selfTarget, presetId)
    if type(selfTarget) ~= "table" then
        presetId = selfTarget
    end
    AvatarSwitcher:deletePreset(presetId)
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

function AvatarSwitcher.consoleAvatarHud(selfTarget)
    if AvatarSwitcher.toggleHud ~= nil then
        AvatarSwitcher:toggleHud()
    else
        AvatarSwitcher:warn("HUD module is not loaded")
    end
end

function AvatarSwitcher.consoleAvatarHudNext(selfTarget)
    if AvatarSwitcher.cycleHudPreset ~= nil then
        AvatarSwitcher:cycleHudPreset(1)
    end
end

function AvatarSwitcher.consoleAvatarHudPrev(selfTarget)
    if AvatarSwitcher.cycleHudPreset ~= nil then
        AvatarSwitcher:cycleHudPreset(-1)
    end
end

function AvatarSwitcher.consoleAvatarHudApply(selfTarget)
    if AvatarSwitcher.applyHudSelection ~= nil then
        AvatarSwitcher:applyHudSelection()
    else
        AvatarSwitcher:warn("HUD module is not loaded")
    end
end

function AvatarSwitcher.consoleAvatarHudDebug(selfTarget)
    if AvatarSwitcher.debugHudStatus ~= nil then
        AvatarSwitcher:debugHudStatus()
    else
        AvatarSwitcher:warn("HUD module is not loaded")
    end
end

function AvatarSwitcher.consoleAvatarInputDebug(selfTarget)
    if AvatarSwitcher.debugHudInputStatus ~= nil then
        AvatarSwitcher:debugHudInputStatus()
    end
    if AvatarSwitcher.debugInputEventStatus ~= nil then
        AvatarSwitcher:debugInputEventStatus()
    end
    if AvatarSwitcher.debugHudInputStatus == nil and AvatarSwitcher.debugInputEventStatus == nil then
        AvatarSwitcher:warn("HUD input debug is not available")
    end
end

function AvatarSwitcher.consoleAvatarMenuDebug(selfTarget)
    if AvatarSwitcher.debugMenuEntryStatus ~= nil then
        AvatarSwitcher:debugMenuEntryStatus()
    else
        AvatarSwitcher:warn("Menu-entry diagnostics are not available")
    end
end

function AvatarSwitcher.consoleAvatarWardrobeDebug(selfTarget)
    if AvatarSwitcher.debugWardrobeStatus ~= nil then
        AvatarSwitcher:debugWardrobeStatus()
    else
        AvatarSwitcher:warn("Wardrobe diagnostics are not available")
    end
end

local function AS_registerConsoleCommands()
    if AvatarSwitcher.consoleCommandsRegistered then
        return
    end

    addConsoleCommand("avatarList", "List AvatarSwitcher presets. Optional: avatarList <category>", "consoleAvatarList", AvatarSwitcher)
    addConsoleCommand("avatarUse", "Apply AvatarSwitcher preset: avatarUse <presetId>", "consoleAvatarUse", AvatarSwitcher)
    addConsoleCommand("avatarCurrent", "Show current gameSettings.xml lastPlayerStyle", "consoleAvatarCurrent", AvatarSwitcher)
    addConsoleCommand("avatarSaveCurrent", "Save current lastPlayerStyle as preset: avatarSaveCurrent <presetId> <display name>", "consoleAvatarSaveCurrent", AvatarSwitcher)
    addConsoleCommand("avatarDelete", "Delete AvatarSwitcher preset: avatarDelete <presetId>", "consoleAvatarDelete", AvatarSwitcher)
    addConsoleCommand("avatarReload", "Reload AvatarSwitcher presets from XML", "consoleAvatarReload", AvatarSwitcher)
    addConsoleCommand("avatarProbe", "Probe runtime avatar/player methods for live refresh debugging", "consoleAvatarProbe", AvatarSwitcher)
    addConsoleCommand("avatarRefresh", "Attempt to refresh active player from gameSettings.xml", "consoleAvatarRefresh", AvatarSwitcher)
    addConsoleCommand("avatarHud", "Toggle the AvatarSwitcher HUD", "consoleAvatarHud", AvatarSwitcher)
    addConsoleCommand("avatarHudNext", "Move AvatarSwitcher HUD to the next preset", "consoleAvatarHudNext", AvatarSwitcher)
    addConsoleCommand("avatarHudPrev", "Move AvatarSwitcher HUD to the previous preset", "consoleAvatarHudPrev", AvatarSwitcher)
    addConsoleCommand("avatarHudApply", "Apply the current AvatarSwitcher HUD selection", "consoleAvatarHudApply", AvatarSwitcher)
    addConsoleCommand("avatarHudDebug", "Print AvatarSwitcher HUD diagnostics", "consoleAvatarHudDebug", AvatarSwitcher)
    addConsoleCommand("avatarInputDebug", "Print AvatarSwitcher input action diagnostics", "consoleAvatarInputDebug", AvatarSwitcher)
    addConsoleCommand("avatarMenuDebug", "Print AvatarSwitcher in-game menu-entry diagnostics", "consoleAvatarMenuDebug", AvatarSwitcher)
    addConsoleCommand("avatarWardrobeDebug", "Print AvatarSwitcher wardrobe integration diagnostics", "consoleAvatarWardrobeDebug", AvatarSwitcher)

    addConsoleCommand("asList", "Alias for avatarList", "consoleAvatarList", AvatarSwitcher)
    addConsoleCommand("asUse", "Alias for avatarUse", "consoleAvatarUse", AvatarSwitcher)
    addConsoleCommand("asCurrent", "Alias for avatarCurrent", "consoleAvatarCurrent", AvatarSwitcher)
    addConsoleCommand("asSaveCurrent", "Alias for avatarSaveCurrent", "consoleAvatarSaveCurrent", AvatarSwitcher)
    addConsoleCommand("asDelete", "Alias for avatarDelete", "consoleAvatarDelete", AvatarSwitcher)
    addConsoleCommand("asReload", "Alias for avatarReload", "consoleAvatarReload", AvatarSwitcher)
    addConsoleCommand("asProbe", "Alias for avatarProbe", "consoleAvatarProbe", AvatarSwitcher)
    addConsoleCommand("asRefresh", "Alias for avatarRefresh", "consoleAvatarRefresh", AvatarSwitcher)
    addConsoleCommand("asHud", "Alias for avatarHud", "consoleAvatarHud", AvatarSwitcher)
    addConsoleCommand("asHudNext", "Alias for avatarHudNext", "consoleAvatarHudNext", AvatarSwitcher)
    addConsoleCommand("asHudPrev", "Alias for avatarHudPrev", "consoleAvatarHudPrev", AvatarSwitcher)
    addConsoleCommand("asHudApply", "Alias for avatarHudApply", "consoleAvatarHudApply", AvatarSwitcher)
    addConsoleCommand("asHudDebug", "Alias for avatarHudDebug", "consoleAvatarHudDebug", AvatarSwitcher)
    addConsoleCommand("asInputDebug", "Alias for avatarInputDebug", "consoleAvatarInputDebug", AvatarSwitcher)
    addConsoleCommand("asMenuDebug", "Alias for avatarMenuDebug", "consoleAvatarMenuDebug", AvatarSwitcher)
    addConsoleCommand("asWardrobeDebug", "Alias for avatarWardrobeDebug", "consoleAvatarWardrobeDebug", AvatarSwitcher)

    AvatarSwitcher.consoleCommandsRegistered = true
    AvatarSwitcher:log("Console commands registered")
end

AS_registerConsoleCommands()
