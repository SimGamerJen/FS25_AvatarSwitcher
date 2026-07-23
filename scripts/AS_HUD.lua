-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.1
-- File: AS_HUD.lua
-- BuildTag: 20260513.6

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
    { name = "ASZ_HUD", callback = "onHudToggleInput", textKey = "input_ASZ_HUD", text = "Open Avatar Switcher", alwaysActive = true }
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
            pcall(g_inputBinding.setActionEventText, g_inputBinding, eventId, mod:getText("input_ASZ_HUD", tostring(text or actionName)))
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

    -- v0.5.6+: the AvatarSwitcher selector now uses a native GIANTS/FS25
    -- dialog instead of a raw drawFilledRect HUD. This gives us the same
    -- fullscreen dialog background, three-part panel, SmoothList rows,
    -- sliders, focus handling and button profiles used by the base game.
    if self.guiDialog ~= nil then
        self:closeDialog()
    elseif self.openDialog ~= nil then
        self:openDialog()
    end

    self:updateHudInputVisibility()
end

function AvatarSwitcher:closeHud()
    if self.closeDialog ~= nil and self.guiDialog ~= nil then
        self:closeDialog()
    end
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

local AS_STYLE = {
    scrim = {0.0, 0.0, 0.0, 0.44},
    shadow = {0.0, 0.0, 0.0, 0.62},
    panel = {0.030, 0.033, 0.036, 0.97},
    panelTop = {0.060, 0.066, 0.072, 0.98},
    panelInner = {0.050, 0.055, 0.060, 0.96},
    field = {0.015, 0.017, 0.019, 0.96},
    fieldBorder = {0.135, 0.145, 0.150, 1.00},
    border = {0.165, 0.172, 0.178, 1.00},
    accent = {0.560, 0.720, 0.260, 1.00},
    accentSoft = {0.230, 0.330, 0.120, 0.92},
    button = {0.095, 0.102, 0.108, 0.98},
    buttonBorder = {0.220, 0.230, 0.235, 1.00},
    buttonPrimary = {0.170, 0.270, 0.090, 0.98},
    buttonDanger = {0.290, 0.085, 0.070, 0.98},
    text = {0.96, 0.96, 0.92, 1.00},
    muted = {0.70, 0.72, 0.70, 1.00},
    label = {0.82, 0.84, 0.82, 1.00},
    warning = {1.00, 0.78, 0.42, 1.00}
}

local function AS_col(name)
    local c = AS_STYLE[name] or AS_STYLE.text
    return c[1], c[2], c[3], c[4]
end

local function AS_drawRect(x, y, w, h, r, g, b, a)
    if drawFilledRect ~= nil then
        pcall(drawFilledRect, x, y, w, h, r, g, b, a)
    end
end

local function AS_drawStyleRect(x, y, w, h, styleName)
    AS_drawRect(x, y, w, h, AS_col(styleName))
end

local function AS_drawBorder(x, y, w, h, thickness, styleName)
    thickness = thickness or 0.002
    AS_drawStyleRect(x, y + h - thickness, w, thickness, styleName or "border")
    AS_drawStyleRect(x, y, w, thickness, styleName or "border")
    AS_drawStyleRect(x, y, thickness, h, styleName or "border")
    AS_drawStyleRect(x + w - thickness, y, thickness, h, styleName or "border")
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

local function AS_drawTextStyle(x, y, size, text, styleName)
    AS_drawText(x, y, size, text, AS_col(styleName or "text"))
end

local function AS_pointInRect(px, py, rect)
    return rect ~= nil and px >= rect.x and px <= rect.x + rect.w and py >= rect.y and py <= rect.y + rect.h
end

local function AS_drawField(x, y, w, h, label, value, subText)
    AS_drawStyleRect(x, y, w, h, "field")
    AS_drawBorder(x, y, w, h, 0.0015, "fieldBorder")
    AS_drawTextStyle(x + 0.010, y + h - 0.021, 0.0125, tostring(label or ""), "muted")
    AS_drawTextStyle(x + 0.010, y + 0.020, 0.0160, tostring(value or ""), "text")
    if subText ~= nil and subText ~= "" then
        AS_drawTextStyle(x + 0.010, y + 0.006, 0.0108, tostring(subText), "muted")
    end
end

function AvatarSwitcher:setHudMouseCursorVisible(visible)
    if g_inputBinding ~= nil and g_inputBinding.setShowMouseCursor ~= nil then
        pcall(g_inputBinding.setShowMouseCursor, g_inputBinding, visible == true, visible == true)
    end
end

function AvatarSwitcher:addHudButton(id, label, x, y, w, h, style)
    self.HUD.buttons = self.HUD.buttons or {}
    local rect = { id = id, label = label, x = x, y = y, w = w, h = h }
    table.insert(self.HUD.buttons, rect)

    style = style or "normal"
    local fill = "button"
    local border = "buttonBorder"
    if style == "primary" then
        fill = "buttonPrimary"
        border = "accent"
    elseif style == "danger" then
        fill = "buttonDanger"
        border = "warning"
    elseif style == "nav" then
        fill = "panelInner"
        border = "fieldBorder"
    end

    AS_drawStyleRect(x, y, w, h, fill)
    AS_drawStyleRect(x, y + h - 0.003, w, 0.003, border)
    AS_drawBorder(x, y, w, h, 0.0014, border)
    AS_drawTextStyle(x + 0.008, y + h * 0.32, 0.0132, label, "text")
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
    if self.useLegacyRawHud ~= true then
        return false
    end
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

    AS_drawRect(0, 0, 1, 1, 0, 0, 0, 0.70)

    local boxW = 0.360
    local boxH = 0.170
    local boxX = 0.5 - (boxW * 0.5)
    local boxY = 0.5 - (boxH * 0.5)

    AS_drawStyleRect(boxX - 0.008, boxY - 0.010, boxW + 0.016, boxH + 0.020, "shadow")
    AS_drawStyleRect(boxX, boxY, boxW, boxH, "panel")
    AS_drawStyleRect(boxX, boxY + boxH - 0.034, boxW, 0.034, "panelTop")
    AS_drawStyleRect(boxX, boxY + boxH - 0.005, boxW, 0.005, "accent")
    AS_drawBorder(boxX, boxY, boxW, boxH, 0.0018, "border")

    AS_drawTextStyle(boxX + 0.018, boxY + boxH - 0.025, 0.0165, self:getText("as_delete_appearance", "Delete Appearance"), "text")
    AS_drawTextStyle(boxX + 0.018, boxY + 0.092, 0.0138, self:getText("as_delete_confirm_body", "This will remove the selected AvatarSwitcher preset."), "label")
    AS_drawTextStyle(boxX + 0.018, boxY + 0.066, 0.0145, tostring(preset.name or preset.id), "warning")
    AS_drawTextStyle(boxX + 0.018, boxY + 0.046, 0.0118, self:getText("as_delete_current_unchanged", "The current in-game appearance will not be changed."), "muted")

    self:addHudButton("deleteConfirm", self:getText("as_delete", "Delete"), boxX + boxW - 0.184, boxY + 0.014, 0.082, 0.034, "danger")
    self:addHudButton("deleteCancel", self:getText("as_cancel", "Cancel"), boxX + boxW - 0.092, boxY + 0.014, 0.082, 0.034, "normal")
end

function AvatarSwitcher:update(dt)
    -- Input registration is handled by AS_InputEvents.lua.
end

function AvatarSwitcher:draw()
    -- Native dialog mode is now the primary UI. Keep the legacy raw HUD draw
    -- code below as a dormant fallback only.
    if self.useLegacyRawHud ~= true then
        return
    end
    if self.HUD == nil or not self.HUD.visible then
        return
    end

    local categories = self.HUD.categories or { "all" }
    local category = categories[self.HUD.categoryIndex or 1] or "all"
    local preset = self.HUD.filteredPresets ~= nil and self.HUD.filteredPresets[self.HUD.presetIndex or 1] or nil
    local presetName = preset ~= nil and tostring(preset.name or preset.id) or self:getText("as_no_presets_found", "No presets found")
    local presetId = preset ~= nil and tostring(preset.id or "") or "-"
    local presetCount = #(self.HUD.filteredPresets or {})

    local x = 0.300
    local y = 0.615
    local w = 0.430
    local h = 0.330
    self.HUD.buttons = {}

    AS_drawStyleRect(0, 0, 1, 1, "scrim")
    AS_drawStyleRect(x - 0.010, y - 0.012, w + 0.020, h + 0.024, "shadow")
    AS_drawStyleRect(x, y, w, h, "panel")
    AS_drawBorder(x, y, w, h, 0.0018, "border")

    local headerH = 0.052
    AS_drawStyleRect(x, y + h - headerH, w, headerH, "panelTop")
    AS_drawStyleRect(x, y + h - 0.006, w, 0.006, "accent")
    AS_drawTextStyle(x + 0.018, y + h - 0.034, 0.0205, self:getText("as_title", "Avatar Switcher"), "text")
    AS_drawTextStyle(x + 0.018, y + h - 0.050, 0.0118, self:getText("as_saved_player_appearances", "Saved player appearances"), "muted")

    local contentX = x + 0.018
    local contentW = w - 0.036
    local rowH = 0.064
    local navW = 0.034
    local valueW = contentW - (navW * 2) - 0.016

    local catY = y + 0.196
    AS_drawField(contentX + navW + 0.008, catY, valueW, rowH, self:getText("as_category", "Category"), self:getCategoryDisplayName(category), tostring(self.HUD.categoryIndex or 0) .. "/" .. tostring(#categories))
    self:addHudButton("catPrev", "<", contentX, catY + 0.015, navW, 0.034, "nav")
    self:addHudButton("catNext", ">", contentX + navW + 0.008 + valueW + 0.008, catY + 0.015, navW, 0.034, "nav")

    local presetY = y + 0.116
    AS_drawField(contentX + navW + 0.008, presetY, valueW, rowH, self:getText("as_appearance", "Appearance"), presetName, self:getText("as_preset_id", "Preset ID") .. ": " .. presetId .. "     " .. tostring(self.HUD.presetIndex or 0) .. "/" .. tostring(presetCount))
    self:addHudButton("presetPrev", "<", contentX, presetY + 0.015, navW, 0.034, "nav")
    self:addHudButton("presetNext", ">", contentX + navW + 0.008 + valueW + 0.008, presetY + 0.015, navW, 0.034, "nav")

    local buttonY = y + 0.054
    self:addHudButton("apply", self:getText("as_apply", "Apply"), contentX, buttonY, 0.102, 0.038, "primary")
    self:addHudButton("delete", self:getText("as_delete", "Delete"), contentX + 0.116, buttonY, 0.088, 0.038, "danger")
    self:addHudButton("close", self:getText("as_close", "Close"), contentX + contentW - 0.088, buttonY, 0.088, 0.038, "normal")

    AS_drawStyleRect(x, y, w, 0.032, "panelInner")
    AS_drawTextStyle(contentX, y + 0.010, 0.0108, self:getText("as_hud_hint", "Use the mapped Open Avatar Switcher control, then select with the mouse."), "muted")

    if self.HUD.deleteConfirm == true then
        self:drawHudDeleteConfirm(x, y, w)
    end

    if setTextColor ~= nil then
        pcall(setTextColor, 1, 1, 1, 1)
    end
end
