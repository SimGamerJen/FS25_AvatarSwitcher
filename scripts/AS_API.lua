-- FS25_AvatarSwitcher
-- ModVersion: 0.6.0-beta
-- File: AS_API.lua
-- BuildTag: 20260513.1
-- Public bridge API for other mods such as FS25_HelperProfiles.

AvatarSwitcher = AvatarSwitcher or {}
AvatarSwitcherAPI = AvatarSwitcherAPI or {}

-- FS25 can evaluate mod extraSourceFiles in per-mod environments.  Keep an
-- explicit _G export so other mods can resolve this bridge reliably.
if _G ~= nil then
    _G.AvatarSwitcherAPI = AvatarSwitcherAPI
    _G.FS25_AvatarSwitcherAPI = AvatarSwitcherAPI
end

local function ASAPI_init()
    if AvatarSwitcher ~= nil and type(AvatarSwitcher.initialize) == "function" then
        local ok, err = pcall(function() AvatarSwitcher:initialize() end)
        if not ok then
            print("[AvatarSwitcherAPI] initialize failed: " .. tostring(err))
            return false, tostring(err)
        end
        return true, nil
    end
    return false, "initialize-missing"
end

local function ASAPI_isPlayerStyle(value)
    if type(value) ~= "table" then
        return false
    end
    if type(value.configs) == "table" then
        return type(value.copyFrom) == "function"
            or type(value.copySelectionFrom) == "function"
            or type(value.writeStream) == "function"
    end
    return type(value.faceConfig) == "table"
        and type(value.topConfig) == "table"
        and type(value.bottomConfig) == "table"
        and type(value.footwearConfig) == "table"
end

function AvatarSwitcherAPI.isAvailable()
    -- Availability should mean "the API can be called", not "all presets and
    -- runtime internals have already been hydrated". HP can then report more
    -- specific errors such as no-presets or runtime-builder-unavailable later.
    if AvatarSwitcher == nil then return false end
    if type(AvatarSwitcherAPI.getPresetsByCategory) ~= "function" then return false end
    if type(AvatarSwitcherAPI.createPlayerStyleFromPresetId) ~= "function" then return false end

    -- Best-effort initialise. Do not make availability false merely because a
    -- specific internal table is not populated at the exact moment of probing.
    ASAPI_init()
    return true
end

function AvatarSwitcherAPI.getDiagnostics()
    return {
        hasAvatarSwitcher = AvatarSwitcher ~= nil,
        hasInitialize = AvatarSwitcher ~= nil and type(AvatarSwitcher.initialize) == "function",
        hasLoadPresets = AvatarSwitcher ~= nil and type(AvatarSwitcher.loadPresets) == "function",
        hasPresets = AvatarSwitcher ~= nil and type(AvatarSwitcher.presets) == "table",
        presetCount = AvatarSwitcher ~= nil and type(AvatarSwitcher.presets) == "table" and #AvatarSwitcher.presets or -1,
        hasPresetsById = AvatarSwitcher ~= nil and type(AvatarSwitcher.presetsById) == "table",
        hasRuntimeBuilder = AvatarSwitcher ~= nil and type(AvatarSwitcher.createPlayerStyleFromPresetStyle) == "function",
        initialized = AvatarSwitcher ~= nil and AvatarSwitcher.initialized == true,
        version = AvatarSwitcher ~= nil and tostring(AvatarSwitcher.VERSION) or "?",
    }
end

function AvatarSwitcherAPI.reload()
    ASAPI_init()
    if AvatarSwitcher ~= nil and type(AvatarSwitcher.loadPresets) == "function" then
        return AvatarSwitcher:loadPresets()
    end
    return false
end

function AvatarSwitcherAPI.getPreset(presetId)
    if presetId == nil or presetId == "" then
        return nil
    end
    ASAPI_init()
    return AvatarSwitcher.presetsById and AvatarSwitcher.presetsById[tostring(presetId)] or nil
end

function AvatarSwitcherAPI.getPresets()
    ASAPI_init()
    return AvatarSwitcher.presets or {}
end

function AvatarSwitcherAPI.getPresetsByCategory(category)
    ASAPI_init()
    local results = {}
    local wanted = tostring(category or ""):lower()
    if wanted == "" then
        return results
    end

    for _, preset in ipairs(AvatarSwitcher.presets or {}) do
        if tostring(preset.category or ""):lower() == wanted then
            table.insert(results, preset)
        end
    end

    table.sort(results, function(a, b)
        local ao = tonumber(a.sortOrder or 0) or 0
        local bo = tonumber(b.sortOrder or 0) or 0
        if ao ~= bo then return ao < bo end
        return tostring(a.name or a.id or "") < tostring(b.name or b.id or "")
    end)

    return results
end

function AvatarSwitcherAPI.getPresetLabel(presetId)
    local preset = AvatarSwitcherAPI.getPreset(presetId)
    if preset == nil then
        return nil
    end
    return tostring(preset.name or preset.id or presetId)
end

function AvatarSwitcherAPI.createPlayerStyleFromPresetId(presetId)
    local preset = AvatarSwitcherAPI.getPreset(presetId)
    if preset == nil or preset.style == nil then
        return nil, "preset-not-found"
    end

    if AvatarSwitcher == nil or type(AvatarSwitcher.createPlayerStyleFromPresetStyle) ~= "function" then
        return nil, "runtime-builder-unavailable"
    end

    local ok, playerStyle = pcall(AvatarSwitcher.createPlayerStyleFromPresetStyle, AvatarSwitcher, preset.style)
    if not ok then
        return nil, tostring(playerStyle)
    end
    if not ASAPI_isPlayerStyle(playerStyle) then
        return nil, "not-playerstyle"
    end

    playerStyle.asPresetId = tostring(presetId)
    return playerStyle, nil
end

function AvatarSwitcherAPI.isPlayerStyle(value)
    return ASAPI_isPlayerStyle(value)
end

if _G ~= nil then
    _G.AvatarSwitcherAPI = AvatarSwitcherAPI
    _G.FS25_AvatarSwitcherAPI = AvatarSwitcherAPI
end
print("[AvatarSwitcherAPI] Public API registered v0.6.0-beta | global=" .. tostring(_G ~= nil and _G.AvatarSwitcherAPI ~= nil))
