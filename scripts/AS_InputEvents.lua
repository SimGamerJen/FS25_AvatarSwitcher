-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.1
-- File: AS_InputEvents.lua
-- BuildTag: 20260513.1
-- HelperProfiles-style duplicate-safe input registration for player and vehicle contexts.
-- Opens the AvatarSwitcher HUD without drawing a custom button into the in-game pause menu.

AvatarSwitcher = AvatarSwitcher or {}

local LOG = "[FS25_AvatarSwitcher/InputEvents] "
local _loggedVehicleHud = false

local function AS_inputAction(actionName)
    if InputAction ~= nil and InputAction[actionName] ~= nil then
        return InputAction[actionName]
    end
    return nil
end

local function AS_isPress(inputValue, callbackState)
    if type(inputValue) == "number" then
        return inputValue > 0
    elseif type(inputValue) == "boolean" then
        return inputValue == true
    end
    local v = tonumber(callbackState)
    return v ~= nil and v > 0
end

local function AS_onHudToggle(_, actionName, inputValue, callbackState, isAnalog)
    if not AS_isPress(inputValue, callbackState) then return end
    if AvatarSwitcher ~= nil and AvatarSwitcher.toggleHud ~= nil then
        AvatarSwitcher:toggleHud()
    end
end

local function AS_setActionEventLowPriority(id, visible)
    if id == nil or g_inputBinding == nil then return end
    if g_inputBinding.setActionEventTextPriority ~= nil then
        pcall(g_inputBinding.setActionEventTextPriority, g_inputBinding, id, GS_PRIO_VERY_LOW)
    end
    if g_inputBinding.setActionEventText ~= nil and AvatarSwitcher ~= nil and AvatarSwitcher.getText ~= nil then
        pcall(g_inputBinding.setActionEventText, g_inputBinding, id, AvatarSwitcher:getText("input_ASZ_HUD", "Open Avatar Switcher"))
    end
    if g_inputBinding.setActionEventTextVisibility ~= nil then
        pcall(g_inputBinding.setActionEventTextVisibility, g_inputBinding, id, visible ~= false)
    end
end

local function AS_registerPlayerAction(field, actionName, target, callback, label)
    if AvatarSwitcher[field] ~= nil then return end
    if g_inputBinding == nil or g_inputBinding.registerActionEvent == nil then
        print(LOG .. "Failed to register " .. tostring(label) .. " (player): g_inputBinding unavailable")
        return
    end

    local inputAction = AS_inputAction(actionName)
    if inputAction == nil then
        print(LOG .. "Failed to register " .. tostring(label) .. " (player): input action unavailable")
        return
    end

    local ok, registered, eventId = pcall(g_inputBinding.registerActionEvent, g_inputBinding, inputAction, target, callback, false, true, false, true)
    if ok and registered == true and eventId ~= nil then
        AvatarSwitcher[field] = eventId
        AS_setActionEventLowPriority(eventId, true)
        print(LOG .. "Registered " .. tostring(label) .. " (player)")
    elseif ok and registered ~= nil and eventId == nil then
        -- Some FS builds/mod contexts return (true, eventId) rather than (registered, eventId).
        AvatarSwitcher[field] = registered
        AS_setActionEventLowPriority(registered, true)
        print(LOG .. "Registered " .. tostring(label) .. " (player)")
    else
        print(LOG .. "Failed to register " .. tostring(label) .. " (player) | " .. tostring(registered))
    end
end

local function AS_unregisterPlayerAction(field, label)
    local id = AvatarSwitcher[field]
    if id ~= nil and g_inputBinding ~= nil and g_inputBinding.removeActionEvent ~= nil then
        pcall(g_inputBinding.removeActionEvent, g_inputBinding, id)
        AvatarSwitcher[field] = nil
        print(LOG .. "Unregistered " .. tostring(label) .. " (player)")
    end
end

local function AS_registerPlayerActions()
    AS_registerPlayerAction("_asPlayerHudId", "ASZ_HUD", AvatarSwitcher, AS_onHudToggle, "ASZ_HUD")
end

local function AS_unregisterPlayerActions()
    AS_unregisterPlayerAction("_asPlayerHudId", "ASZ_HUD")
end

if PlayerInputComponent ~= nil and PlayerInputComponent.registerGlobalPlayerActionEvents ~= nil and Utils ~= nil and Utils.appendedFunction ~= nil then
    PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(
        PlayerInputComponent.registerGlobalPlayerActionEvents,
        function(self, controlling)
            AS_registerPlayerActions()
        end
    )
end

if PlayerInputComponent ~= nil and PlayerInputComponent.removeGlobalPlayerActionEvents ~= nil and Utils ~= nil and Utils.appendedFunction ~= nil then
    PlayerInputComponent.removeGlobalPlayerActionEvents = Utils.appendedFunction(
        PlayerInputComponent.removeGlobalPlayerActionEvents,
        function(self)
            AS_unregisterPlayerActions()
        end
    )
end

local function AS_ensureVehicleSpec(vehicle)
    vehicle.spec_avatarSwitcher = vehicle.spec_avatarSwitcher or {}
    local spec = vehicle.spec_avatarSwitcher
    spec.actionEvents = spec.actionEvents or {}
    return spec
end

local function AS_addVehicleAction(vehicle, spec, actionName, target, callback, label)
    if vehicle == nil or vehicle.addActionEvent == nil then return nil end

    local inputAction = AS_inputAction(actionName)
    if inputAction == nil then
        print(LOG .. "Failed to register " .. tostring(label) .. " (vehicle): input action unavailable")
        return nil
    end

    local _, id = vehicle:addActionEvent(spec.actionEvents, inputAction, target, callback, false, true, false, true)
    if id ~= nil then
        AS_setActionEventLowPriority(id, true)
        if not _loggedVehicleHud then
            print(LOG .. "Registered " .. tostring(label) .. " (vehicle)")
            _loggedVehicleHud = true
        end
    else
        print(LOG .. "Failed to register " .. tostring(label) .. " (vehicle)")
    end
    return id
end

local function AS_registerVehicleActions(vehicle, isActiveForInput)
    if not isActiveForInput or vehicle == nil then return end
    local spec = AS_ensureVehicleSpec(vehicle)

    if vehicle.clearActionEventsTable ~= nil then
        vehicle:clearActionEventsTable(spec.actionEvents)
    end

    AS_addVehicleAction(vehicle, spec, "ASZ_HUD", AvatarSwitcher, AS_onHudToggle, "ASZ_HUD")
end

local function AS_unregisterVehicleActions(vehicle)
    if vehicle == nil or vehicle.spec_avatarSwitcher == nil or vehicle.spec_avatarSwitcher.actionEvents == nil then return end
    if vehicle.clearActionEventsTable ~= nil then
        vehicle:clearActionEventsTable(vehicle.spec_avatarSwitcher.actionEvents)
    end
end

if Vehicle ~= nil and Vehicle.registerActionEvents ~= nil and Utils ~= nil and Utils.appendedFunction ~= nil then
    Vehicle.registerActionEvents = Utils.appendedFunction(
        Vehicle.registerActionEvents,
        function(self, isActiveForInput, isActiveForGUI)
            AS_registerVehicleActions(self, isActiveForInput)
        end
    )
end

if Vehicle ~= nil and Vehicle.removeActionEvents ~= nil and Utils ~= nil and Utils.appendedFunction ~= nil then
    Vehicle.removeActionEvents = Utils.appendedFunction(
        Vehicle.removeActionEvents,
        function(self)
            AS_unregisterVehicleActions(self)
        end
    )
end

function AvatarSwitcher:debugInputEventStatus()
    self:initialize()
    self:log("[InputEventsDebug] Version: " .. tostring(self.VERSION))
    self:log("[InputEventsDebug] ASZ_HUD InputAction available: " .. tostring(AS_inputAction("ASZ_HUD") ~= nil))
    self:log("[InputEventsDebug] player HUD event id: " .. tostring(self._asPlayerHudId))
    self:log("[InputEventsDebug] g_inputBinding available: " .. tostring(g_inputBinding ~= nil))
end
