-- FS25_AvatarSwitcher
-- ModVersion: 0.5.3-alpha
-- File: AS_HUD.lua
-- BuildTag: 20260513.5

AvatarSwitcher = AvatarSwitcher or {}

AvatarSwitcher.HUD = AvatarSwitcher.HUD or {
    visible = false,
    categoryIndex = 1,
    presetIndex = 1,
    categories = {"all"},
    filteredPresets = {},
    deleteConfirm = false
}

local AS_HUD_ACTIONS = {
    { name = "ASZ_HUD", callback = "onHudToggleInput", text = "Avatar Switcher", alwaysActive = true }
}

local function AS_mod(value, maxValue)
    if maxValue == nil or maxValue <= 0 then
        return 1
    end
    while value < 1 do
        value = value + maxValue
    end
    while value > maxValue do
        value = value - maxValue
    end
    return value
end

local function AS_inputAction(actionName)
    if InputAction ~= nil and InputAction[actionName] ~= nil then
        return InputAction[actionName]
    end
    return actionName
end

local function AS_registerOneInput(mod, actionName, callbackName, text, alwaysActive)
    if g_inputBinding == nil or g_inputBinding.registerActionEvent == nil then
        return nil
    end

    local callback = mod[callbackName]
    if type(callback) ~= "function" then
        mod:warn("[HUD] Missing callback: " .. tostring(callbackName))
        return nil
    end

    local ok, registered, eventId = pcall(g_inputBinding.registerActionEvent, g_inputBinding, AS_inputAction(actionName), mod, callback, false, true, false, true)
    if not ok then
        mod:warn("[HUD] Could not register input action " .. tostring(actionName) .. " | " .. tostring(registered))
        return nil
    end

    if registered ~= true then
        mod:warn("[HUD] Input action did not register as active: " .. tostring(actionName) .. " | registered=" .. tostring(registered) .. " | eventId=" .. tostring(eventId))
    end

    if eventId ~= nil then
        if g_inputBinding.setActionEventText ~= nil then
            pcall(g_inputBinding.setActionEventText, g_inputBinding, eventId, tostring(text or actionName))
        end
        if g_inputBinding.setActionEventTextVisibility ~= nil then
            pcall(g_inputBinding.setActionEventTextVisibility, g_inputBinding, eventId, alwaysActive == true)
        end
        if g_inputBinding.setActionEventActive ~= nil then
            pcall(g_inputBinding.setActionEventActive, g_inputBinding, eventId, alwaysActive == true)
        end
    end

    return eventId
end

function AvatarSwitcher:registerHudInputActions()
    -- Retained for console/debug compatibility. Actual input action registration is
    -- handled by AS_InputEvents.lua using HelperProfiles-style Player/Vehicle hooks.
    self.hudInputRegistered = true
end

function AvatarSwitcher:updateHudInputVisibility()
    if g_inputBinding == nil or self.hudActionEventIds == nil then
        return
    end

    for _, action in ipairs(AS_HUD_ACTIONS) do
        local eventId = self.hudActionEventIds[action.name]
        if eventId ~= nil then
            local active = action.alwaysActive == true or self.HUD.visible == true
            local visible = active
            if g_inputBinding.setActionEventActive ~= nil then
                pcall(g_inputBinding.setActionEventActive, g_inputBinding, eventId, active)
            end
            if g_inputBinding.setActionEventTextVisibility ~= nil then
                pcall(g_inputBinding.setActionEventTextVisibility, g_inputBinding, eventId, visible)
            end
        end
    end
end

function AvatarSwitcher:rebuildHudLists()
    self.HUD = self.HUD or {}
    local previousCategory = self.HUD.categories ~= nil and self.HUD.categories[self.HUD.categoryIndex or 1] or "all"
    local previousPresetId = nil
    if self.HUD.filteredPresets ~= nil and self.HUD.presetIndex ~= nil then
        local previousPreset = self.HUD.filteredPresets[self.HUD.presetIndex]
        previousPresetId = previousPreset ~= nil and previousPreset.id or nil
    end

    local seen = { all = true }
    local categories = { "all" }

    for _, preset in ipairs(self.presets or {}) do
        local category = tostring(preset.category or "general")
        if not seen[category] then
            seen[category] = true
            table.insert(categories, category)
        end
    end

    table.sort(categories, function(a, b)
        if a == "all" then return true end
        if b == "all" then return false end
        return tostring(a) < tostring(b)
    end)

    self.HUD.categories = categories
    self.HUD.categoryIndex = 1
    for i, category in ipairs(categories) do
        if category == previousCategory then
            self.HUD.categoryIndex = i
            break
        end
    end

    self:rebuildHudFilteredPresets(previousPresetId)
end

function AvatarSwitcher:rebuildHudFilteredPresets(preferredPresetId)
    self.HUD = self.HUD or {}
    local categories = self.HUD.categories or { "all" }
    local category = categories[self.HUD.categoryIndex or 1] or "all"
    local filtered = {}

    for _, preset in ipairs(self.presets or {}) do
        if category == "all" or tostring(preset.category or "general") == category then
            table.insert(filtered, preset)
        end
    end

    self.HUD.filteredPresets = filtered
    self.HUD.presetIndex = 1

    local wantedId = preferredPresetId or self.currentPresetId
    if wantedId ~= nil then
        for i, preset in ipairs(filtered) do
            if preset.id == wantedId then
                self.HUD.presetIndex = i
                return
            end
        end
    end
end

function AvatarSwitcher:toggleHud()
    self:initialize()
    self:registerHudInputActions()

    if self.HUD == nil or self.HUD.categories == nil then
        self:rebuildHudLists()
    end

    self.HUD.visible = not self.HUD.visible
    if self.HUD.visible then
        self:rebuildHudLists()
        self:setHudMouseCursorVisible(true)
    else
        self:setHudMouseCursorVisible(false)
    end
    self:updateHudInputVisibility()
end

function AvatarSwitcher:closeHud()
    if self.HUD ~= nil and self.HUD.visible then
        self.HUD.visible = false
        self.HUD.deleteConfirm = false
        self:setHudMouseCursorVisible(false)
        self:updateHudInputVisibility()
    end
end

function AvatarSwitcher:cycleHudPreset(delta)
    if self.HUD == nil or not self.HUD.visible then
        return
    end
    local count = #(self.HUD.filteredPresets or {})
    if count <= 0 then
        return
    end
    self.HUD.presetIndex = AS_mod((self.HUD.presetIndex or 1) + delta, count)
    self.HUD.deleteConfirm = false
end

function AvatarSwitcher:cycleHudCategory(delta)
    if self.HUD == nil or not self.HUD.visible then
        return
    end
    local count = #(self.HUD.categories or {})
    if count <= 0 then
        return
    end
    self.HUD.categoryIndex = AS_mod((self.HUD.categoryIndex or 1) + delta, count)
    self:rebuildHudFilteredPresets(nil)
    self.HUD.deleteConfirm = false
end

function AvatarSwitcher:applyHudSelection()
    if self.HUD == nil or not self.HUD.visible then
        return
    end
    local preset = self:getHudSelectedPreset()
    if preset == nil then
        self:warn("[HUD] No preset selected")
        return
    end
    self:applyPreset(preset.id)
end


function AvatarSwitcher:getHudSelectedPreset()
    if self.HUD == nil then
        return nil
    end
    return self.HUD.filteredPresets ~= nil and self.HUD.filteredPresets[self.HUD.presetIndex or 1] or nil
end

function AvatarSwitcher:requestHudDeleteSelection()
    if self.HUD == nil or not self.HUD.visible then
        return
    end
    local preset = self:getHudSelectedPreset()
    if preset == nil then
        self:warn("[HUD] No preset selected for deletion")
        return
    end
    self.HUD.deleteConfirm = true
end

function AvatarSwitcher:cancelHudDeleteSelection()
    if self.HUD ~= nil then
        self.HUD.deleteConfirm = false
    end
end

function AvatarSwitcher:confirmHudDeleteSelection()
    if self.HUD == nil or not self.HUD.visible then
        return
    end
    local preset = self:getHudSelectedPreset()
    if preset == nil then
        self.HUD.deleteConfirm = false
        return
    end

    local presetId = tostring(preset.id or "")
    local ok = false
    if self.deletePreset ~= nil then
        ok = self:deletePreset(presetId) == true
    elseif self.deletePresetFromFile ~= nil then
        ok = self:deletePresetFromFile(presetId) == true
    end

    self.HUD.deleteConfirm = false
    if ok then
        self:rebuildHudLists(nil)
    else
        self:warn("[HUD] Could not delete preset: " .. tostring(presetId))
    end
end

function AvatarSwitcher:onHudToggleInput(actionName, inputValue, callbackState, isAnalog)
    self:debug("[HUD] Toggle input fired: " .. tostring(actionName) .. " value=" .. tostring(inputValue))
    self:toggleHud()
end

function AvatarSwitcher:onHudPrevPresetInput(actionName, inputValue, callbackState, isAnalog)
    self:cycleHudPreset(-1)
end

function AvatarSwitcher:onHudNextPresetInput(actionName, inputValue, callbackState, isAnalog)
    self:cycleHudPreset(1)
end

function AvatarSwitcher:onHudPrevCategoryInput(actionName, inputValue, callbackState, isAnalog)
    self:cycleHudCategory(-1)
end

function AvatarSwitcher:onHudNextCategoryInput(actionName, inputValue, callbackState, isAnalog)
    self:cycleHudCategory(1)
end

function AvatarSwitcher:onHudApplyInput(actionName, inputValue, callbackState, isAnalog)
    self:applyHudSelection()
end

function AvatarSwitcher:onHudCloseInput(actionName, inputValue, callbackState, isAnalog)
    self:closeHud()
end

local function AS_drawRect(x, y, w, h, r, g, b, a)
    if drawFilledRect ~= nil then
        pcall(drawFilledRect, x, y, w, h, r, g, b, a)
    end
end

local function AS_drawText(x, y, size, text, r, g, b, a)
    if setTextAlignment ~= nil and RenderText ~= nil and RenderText.ALIGN_LEFT ~= nil then
        pcall(setTextAlignment, RenderText.ALIGN_LEFT)
    end
    if setTextColor ~= nil then
        pcall(setTextColor, r or 1, g or 1, b or 1, a or 1)
    end
    if renderText ~= nil then
        pcall(renderText, x, y, size, tostring(text or ""))
    end
end

local function AS_pointInRect(px, py, rect)
    return rect ~= nil and px >= rect.x and px <= rect.x + rect.w and py >= rect.y and py <= rect.y + rect.h
end

function AvatarSwitcher:setHudMouseCursorVisible(visible)
    if g_inputBinding ~= nil and g_inputBinding.setShowMouseCursor ~= nil then
        pcall(g_inputBinding.setShowMouseCursor, g_inputBinding, visible == true, visible == true)
    end
end

function AvatarSwitcher:addHudButton(id, label, x, y, w, h)
    self.HUD.buttons = self.HUD.buttons or {}
    local rect = { id = id, label = label, x = x, y = y, w = w, h = h }
    table.insert(self.HUD.buttons, rect)
    AS_drawRect(x, y, w, h, 0.12, 0.12, 0.12, 0.88)
    AS_drawText(x + 0.006, y + h * 0.32, 0.014, label, 1, 1, 1, 1)
end

function AvatarSwitcher:handleHudButton(id)
    if id == "catPrev" then
        self:cycleHudCategory(-1)
    elseif id == "catNext" then
        self:cycleHudCategory(1)
    elseif id == "presetPrev" then
        self:cycleHudPreset(-1)
    elseif id == "presetNext" then
        self:cycleHudPreset(1)
    elseif id == "apply" then
        self:applyHudSelection()
    elseif id == "delete" then
        self:requestHudDeleteSelection()
    elseif id == "deleteConfirm" then
        self:confirmHudDeleteSelection()
    elseif id == "deleteCancel" then
        self:cancelHudDeleteSelection()
    elseif id == "close" then
        self:closeHud()
    end
end

function AvatarSwitcher:mouseEvent(posX, posY, isDown, isUp, button)
    if self.HUD == nil or self.HUD.visible ~= true then
        return false
    end

    local leftButton = Input ~= nil and Input.MOUSE_BUTTON_LEFT or 1
    if button ~= nil and button ~= leftButton and button ~= 1 then
        return false
    end

    -- When the delete confirmation is open it must behave as a true modal:
    -- consume all mouse input and only allow the confirmation buttons to act.
    -- This prevents clicks passing through to the normal HUD buttons behind it.
    if self.HUD.deleteConfirm == true then
        if isUp == true then
            local x = tonumber(posX) or 0
            local y = tonumber(posY) or 0
            local buttons = self.HUD.buttons or {}
            for i = #buttons, 1, -1 do
                local rect = buttons[i]
                if rect ~= nil and (rect.id == "deleteConfirm" or rect.id == "deleteCancel") and AS_pointInRect(x, y, rect) then
                    self:debug("[HUD] Mouse clicked modal button: " .. tostring(rect.id))
                    self:handleHudButton(rect.id)
                    return true
                end
            end
        end
        return true
    end

    if isUp == true then
        local x = tonumber(posX) or 0
        local y = tonumber(posY) or 0
        local buttons = self.HUD.buttons or {}
        -- Iterate top-most first. Later draw calls register later buttons.
        for i = #buttons, 1, -1 do
            local rect = buttons[i]
            if AS_pointInRect(x, y, rect) then
                self:debug("[HUD] Mouse clicked button: " .. tostring(rect.id))
                self:handleHudButton(rect.id)
                return true
            end
        end
    end

    return true
end

function AvatarSwitcher:debugHudInputStatus()
    self:initialize()
    self:log("[InputDebug] Version: " .. tostring(self.VERSION))
    self:log("[InputDebug] g_inputBinding available: " .. tostring(g_inputBinding ~= nil))
    self:log("[InputDebug] HUD input registered: " .. tostring(self.hudInputRegistered == true))
    self:log("[InputDebug] HUD actionEvents table count: " .. tostring(#(self.hudActionEvents or {})))
    for _, action in ipairs(AS_HUD_ACTIONS) do
        local ia = InputAction ~= nil and InputAction[action.name] or nil
        local eventId = self.hudActionEventIds ~= nil and self.hudActionEventIds[action.name] or nil
        self:log("[InputDebug] action=" .. tostring(action.name) .. " | InputAction=" .. tostring(ia) .. " | eventId=" .. tostring(eventId))
    end
end

function AvatarSwitcher:debugHudStatus()
    self:initialize()
    local h = self.HUD or {}
    local categories = h.categories or {}
    local filtered = h.filteredPresets or {}
    self:log("[HUDDebug] Version: " .. tostring(self.VERSION))
    self:log("[HUDDebug] HUD module loaded: true")
    self:log("[HUDDebug] HUD visible: " .. tostring(h.visible == true))
    self:log("[HUDDebug] HUD input registered: " .. tostring(self.hudInputRegistered == true))
    self:log("[HUDDebug] Total presets: " .. tostring(#(self.presets or {})))
    self:log("[HUDDebug] Category count: " .. tostring(#categories) .. " | index=" .. tostring(h.categoryIndex))
    self:log("[HUDDebug] Filtered preset count: " .. tostring(#filtered) .. " | index=" .. tostring(h.presetIndex))
    if categories[h.categoryIndex or 1] ~= nil then
        self:log("[HUDDebug] Selected category: " .. tostring(categories[h.categoryIndex or 1]))
    end
    local preset = filtered[h.presetIndex or 1]
    if preset ~= nil then
        self:log("[HUDDebug] Selected preset: " .. tostring(preset.id) .. " | " .. tostring(preset.name))
    end
end


function AvatarSwitcher:drawHudDeleteConfirm(x, y, w)
    local preset = self:getHudSelectedPreset()
    if preset == nil then
        return
    end

    -- Opaque modal treatment. The full-screen scrim makes the confirmation readable
    -- over bright menus/scenery and visually communicates that clicks are captured.
    AS_drawRect(0, 0, 1, 1, 0, 0, 0, 0.62)

    local boxX = x + 0.034
    local boxY = y + 0.116
    local boxW = w - 0.080
    local boxH = 0.128

    -- Draw a small shadow and fully opaque panel. Some FS GUI paths blend very
    -- lightly, so the duplicate black layers help keep text legible.
    AS_drawRect(boxX - 0.006, boxY - 0.006, boxW + 0.012, boxH + 0.012, 0, 0, 0, 0.85)
    AS_drawRect(boxX, boxY, boxW, boxH, 0.015, 0.015, 0.015, 1.00)
    AS_drawRect(boxX, boxY + boxH - 0.004, boxW, 0.004, 0.95, 0.62, 0.30, 1.00)

    AS_drawText(boxX + 0.012, boxY + 0.094, 0.0155, "Delete this appearance?", 1, 1, 1, 1)
    AS_drawText(boxX + 0.012, boxY + 0.067, 0.0135, tostring(preset.name or preset.id), 0.95, 0.88, 0.72, 1)
    AS_drawText(boxX + 0.012, boxY + 0.044, 0.0118, "This removes it from avatarPresets.xml.", 0.86, 0.86, 0.86, 1)

    -- Place modal buttons away from the underlying HUD button row to avoid any
    -- accidental overlap if another mod changes draw/click order.
    self:addHudButton("deleteConfirm", "Delete", boxX + boxW - 0.176, boxY + 0.012, 0.078, 0.032)
    self:addHudButton("deleteCancel", "Cancel", boxX + boxW - 0.088, boxY + 0.012, 0.078, 0.032)
end

function AvatarSwitcher:update(dt)
    -- Input registration is handled by AS_InputEvents.lua.
end

function AvatarSwitcher:draw()
    if self.HUD == nil or not self.HUD.visible then
        return
    end

    local categories = self.HUD.categories or { "all" }
    local category = categories[self.HUD.categoryIndex or 1] or "all"
    local preset = self.HUD.filteredPresets ~= nil and self.HUD.filteredPresets[self.HUD.presetIndex or 1] or nil
    local presetName = preset ~= nil and tostring(preset.name or preset.id) or "No presets found"
    local presetId = preset ~= nil and tostring(preset.id or "") or "-"
    local presetCount = #(self.HUD.filteredPresets or {})

    local x = 0.32
    local y = 0.70
    local w = 0.40
    local h = 0.285
    self.HUD.buttons = {}

    AS_drawRect(x - 0.012, y - 0.020, w, h, 0, 0, 0, 0.78)
    AS_drawText(x, y + 0.230, 0.021, "Avatar Switcher", 1, 1, 1, 1)

    AS_drawText(x, y + 0.191, 0.016, "Category:", 0.9, 0.9, 0.9, 1)
    self:addHudButton("catPrev", "<", x + 0.095, y + 0.182, 0.032, 0.030)
    AS_drawText(x + 0.140, y + 0.191, 0.016, tostring(category), 1, 1, 1, 1)
    self:addHudButton("catNext", ">", x + 0.335, y + 0.182, 0.032, 0.030)

    AS_drawText(x, y + 0.145, 0.016, "Preset:", 0.9, 0.9, 0.9, 1)
    self:addHudButton("presetPrev", "<", x + 0.095, y + 0.136, 0.032, 0.030)
    AS_drawText(x + 0.140, y + 0.145, 0.016, presetName, 1, 1, 1, 1)
    self:addHudButton("presetNext", ">", x + 0.335, y + 0.136, 0.032, 0.030)

    AS_drawText(x, y + 0.105, 0.014, "ID: " .. presetId .. "    " .. tostring(self.HUD.presetIndex or 0) .. "/" .. tostring(presetCount), 0.85, 0.85, 0.85, 1)

    self:addHudButton("apply", "Apply Preset", x, y + 0.055, 0.132, 0.034)
    self:addHudButton("delete", "Delete", x + 0.146, y + 0.055, 0.090, 0.034)
    self:addHudButton("close", "Close", x + 0.252, y + 0.055, 0.085, 0.034)

    if self.HUD.deleteConfirm == true then
        self:drawHudDeleteConfirm(x, y, w)
    end

    AS_drawText(x, y + 0.020, 0.012, "Open with asHud or map ASZ_HUD. Use mouse buttons to select/apply/delete.", 0.78, 0.78, 0.78, 1)

    if setTextColor ~= nil then
        pcall(setTextColor, 1, 1, 1, 1)
    end
end
