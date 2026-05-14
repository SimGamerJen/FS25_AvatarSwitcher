-- FS25_AvatarSwitcher
-- ModVersion: 0.6.0-beta
-- File: AS_Wardrobe.lua
-- BuildTag: 20260514.8
-- Wardrobe integration: injects a small SAVE button while the in-game
-- player wardrobe/player-style GUI is open. The button opens the native
-- AvatarSwitcher XML save dialog so appearances can be saved without console commands.

AvatarSwitcher = AvatarSwitcher or {}

AvatarSwitcher.Wardrobe = AvatarSwitcher.Wardrobe or {
    modalVisible = false,
    buttonRect = nil,
    rects = {},
    focus = "id",
    fields = { id = "", description = "", category = "custom" },
    message = nil,
    messageTime = 0,
    detected = false,
    active = false,
    activeScreen = nil,
    hooksInstalled = false,
    drawHookInstalled = false,
    mouseHookInstalled = false,
    keyHookInstalled = false,
    hookAttempted = false,
    hookStatus = "not attempted",
    nativeButtonHookInstalled = false,
    nativeButtonInjected = false,
    nativeButtonActive = false,
    nativeButtonFallback = false,
    nativeButtonStatus = "not attempted",
    embeddedButton = nil,
    embeddedButtonActive = false,
    embeddedButtonStatus = "not attempted",
}

local function ASW_lower(v)
    return tostring(v or ""):lower()
end

local function ASW_trim(v)
    return tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function ASW_drawRect(x, y, w, h, r, g, b, a)
    if drawFilledRect ~= nil then drawFilledRect(x, y, w, h, r, g, b, a) end
end

local function ASW_setTextColor(r, g, b, a)
    if setTextColor ~= nil then setTextColor(r, g, b, a) end
end

local function ASW_setTextAlign(align)
    if setTextAlignment ~= nil then setTextAlignment(align) end
end

local function ASW_text(x, y, size, text, r, g, b, a)
    ASW_setTextColor(r or 1, g or 1, b or 1, a or 1)
    ASW_setTextAlign(RenderText ~= nil and RenderText.ALIGN_LEFT or 0)
    if renderText ~= nil then renderText(x, y, size, tostring(text or "")) end
end

local function ASW_pointInRect(px, py, r)
    return r ~= nil and px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

local function ASW_ellipsize(text, maxLen)
    text = tostring(text or "")
    maxLen = tonumber(maxLen) or 40
    if string.len(text) <= maxLen then return text end
    return string.sub(text, 1, math.max(1, maxLen - 1)) .. "…"
end

local function ASW_sanitizeId(value)
    local s = ASW_trim(value)
    s = s:gsub("%s+", "_")
    s = s:gsub("[^A-Za-z0-9_%-]", "")
    return s
end


local function ASW_shouldConsumeWardrobeInput()
    return AvatarSwitcher ~= nil
        and AvatarSwitcher.Wardrobe ~= nil
        and AvatarSwitcher.Wardrobe.modalVisible == true
end


local function ASW_getWardrobeSaveButtonInfo()
    local W = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
    if W == nil then return nil end

    if W.nativeSaveButtonInfo == nil then
        local action = nil
        if InputAction ~= nil then
            action = InputAction.MENU_EXTRA_1 or InputAction.MENU_ACTIVATE or InputAction.MENU_ACCEPT
        end
        W.nativeSaveButtonInfo = {
            showWhenPaused = true,
            inputAction = action,
            text = "SAVE",
            callback = function()
                local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
                if wardrobe ~= nil and wardrobe.openModal ~= nil then
                    wardrobe:openModal()
                end
            end
        }
    end

    return W.nativeSaveButtonInfo
end

local function ASW_buttonInfoLooksLikeSave(buttonInfo)
    if type(buttonInfo) ~= "table" then return false end
    if buttonInfo == ASW_getWardrobeSaveButtonInfo() then return true end
    local text = ASW_lower(buttonInfo.text)
    return text == "save" or text == "save to avatarswitcher"
end

local function ASW_tableContainsButtonInfo(buttonInfos, buttonInfo)
    if type(buttonInfos) ~= "table" then return false end
    for _, info in ipairs(buttonInfos) do
        if info == buttonInfo or ASW_buttonInfoLooksLikeSave(info) then return true end
    end
    return false
end

local function ASW_findButtonList(screen)
    if type(screen) ~= "table" then return nil end
    for _, key in ipairs({"menuButton", "menuButtons", "buttons", "buttonBox"}) do
        if type(screen[key]) == "table" and type(screen[key][1]) == "table" and type(screen[key][1].clone) == "function" then
            return screen[key]
        end
    end
    return nil
end

local function ASW_ensurePhysicalMenuButtons(screen, requiredCount)
    if type(screen) ~= "table" then return false end
    requiredCount = tonumber(requiredCount) or 0
    if requiredCount <= 0 then return false end

    local buttonList = ASW_findButtonList(screen)
    if type(buttonList) ~= "table" then return false end
    if #buttonList >= requiredCount then return true end

    local template = buttonList[1]
    if type(template) ~= "table" or type(template.clone) ~= "function" or template.parent == nil then return false end

    while #buttonList < requiredCount do
        local newButton = template:clone(template.parent)
        newButton.id = string.format("asWardrobeMenuButton[%d]", #buttonList + 1)
        table.insert(buttonList, newButton)
    end

    return true
end

local function ASW_injectNativeWardrobeSaveButton(screen)
    local W = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
    if W == nil or type(screen) ~= "table" then return false end

    local saveButtonInfo = ASW_getWardrobeSaveButtonInfo()
    if saveButtonInfo == nil then return false end

    if type(screen.menuButtonInfo) ~= "table" then
        W.nativeButtonActive = false
        W.nativeButtonFallback = true
        W.nativeButtonStatus = "WardrobeScreen has no menuButtonInfo table"
        return false
    end

    if not ASW_tableContainsButtonInfo(screen.menuButtonInfo, saveButtonInfo) then
        -- Keep Back/Cancel-style controls first, append SAVE to the native strip.
        table.insert(screen.menuButtonInfo, saveButtonInfo)
    end

    ASW_ensurePhysicalMenuButtons(screen, #screen.menuButtonInfo)

    if type(screen.setMenuButtonInfoDirty) == "function" then
        screen:setMenuButtonInfoDirty()
    end

    W.nativeButtonInjected = true
    W.nativeButtonActive = true
    W.nativeButtonFallback = false
    W.nativeButtonStatus = "native WardrobeScreen menuButtonInfo injection active"
    return true
end


local function ASW_isGuiButtonCandidate(element)
    return type(element) == "table"
        and type(element.clone) == "function"
        and type(element.setText) == "function"
        and type(element.setInputAction) == "function"
        and type(element.setPosition) == "function"
        and type(element.setVisible) == "function"
        and type(element.absPosition) == "table"
        and type(element.absSize) == "table"
        and element.parent ~= nil
end

local function ASW_collectGuiButtons(element, out, visited, depth)
    if type(element) ~= "table" then return end
    visited = visited or {}
    out = out or {}
    depth = tonumber(depth) or 0
    if depth > 12 or visited[element] == true then return end
    visited[element] = true

    if ASW_isGuiButtonCandidate(element) then
        local y = tonumber(element.absPosition[2]) or 1
        local h = tonumber(element.absSize[2]) or 0
        local w = tonumber(element.absSize[1]) or 0
        -- Wardrobe bottom action buttons live in the lowest strip of the screen.
        if y <= 0.12 and h >= 0.018 and h <= 0.08 and w >= 0.035 then
            table.insert(out, element)
        end
    end

    if type(element.elements) == "table" then
        for _, child in ipairs(element.elements) do
            ASW_collectGuiButtons(child, out, visited, depth + 1)
        end
    end
end

local function ASW_findWardrobeBottomButtonTemplate(screen)
    local buttons = {}
    ASW_collectGuiButtons(screen, buttons, {}, 0)
    if #buttons == 0 then return nil end

    table.sort(buttons, function(a, b)
        local ay = tonumber(a.absPosition[2]) or 1
        local by = tonumber(b.absPosition[2]) or 1
        if math.abs(ay - by) > 0.01 then return ay < by end
        return (tonumber(a.absPosition[1]) or 0) > (tonumber(b.absPosition[1]) or 0)
    end)

    -- Prefer the right-most visible bottom action button as the style template.
    for _, button in ipairs(buttons) do
        if button.getIsVisible == nil or button:getIsVisible() then
            return button
        end
    end

    return buttons[1]
end

local function ASW_installEmbeddedWardrobeSaveButton(screen)
    local W = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
    if W == nil or type(screen) ~= "table" then return false end

    if W.embeddedButton ~= nil then
        if type(W.embeddedButton.setVisible) == "function" then W.embeddedButton:setVisible(true) end
        W.embeddedButtonActive = true
        W.embeddedButtonStatus = "embedded Wardrobe GUI button active"
        return true
    end

    local template = ASW_findWardrobeBottomButtonTemplate(screen)
    if template == nil or template.parent == nil then
        W.embeddedButtonActive = false
        W.embeddedButtonStatus = "no bottom Wardrobe button template found"
        return false
    end

    local ok, newButton = pcall(function()
        return template:clone(template.parent, false, true, true)
    end)
    if not ok or newButton == nil then
        W.embeddedButtonActive = false
        W.embeddedButtonStatus = "failed to clone Wardrobe bottom button"
        return false
    end

    W.embeddedButton = newButton
    newButton.id = "asWardrobeSaveButton"
    newButton.name = "asWardrobeSaveButton"
    newButton.onClickCallback = function()
        local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
        if wardrobe ~= nil and wardrobe.openModal ~= nil then
            wardrobe:openModal()
        end
    end

    if type(newButton.setText) == "function" then newButton:setText("Save") end
    if type(newButton.setInputAction) == "function" then newButton:setInputAction("MENU_EXTRA_2") end
    if type(newButton.setDisabled) == "function" then newButton:setDisabled(false) end
    if type(newButton.setVisible) == "function" then newButton:setVisible(true) end

    -- Keep the cloned control in the bottom strip rather than the old top-right overlay.
    -- Prefer placing it immediately left of the right-most bottom action button.
    local gap = 0.012
    local tx = (type(template.position) == "table" and tonumber(template.position[1])) or 0.80
    local ty = (type(template.position) == "table" and tonumber(template.position[2])) or 0.0
    local tw = (type(template.size) == "table" and tonumber(template.size[1])) or (type(template.absSize) == "table" and tonumber(template.absSize[1])) or 0.10
    local nw = tw
    local nh = (type(template.size) == "table" and tonumber(template.size[2])) or (type(template.absSize) == "table" and tonumber(template.absSize[2])) or nil

    if type(newButton.setSize) == "function" and nw ~= nil and nh ~= nil then
        newButton:setSize(nw, nh)
    end
    if type(newButton.setPosition) == "function" then
        newButton:setPosition(math.max(0.0, tx - nw - gap), ty)
    end
    if type(newButton.updateAbsolutePosition) == "function" then newButton:updateAbsolutePosition() end

    if template.parent ~= nil then
        if type(template.parent.invalidateLayout) == "function" then pcall(template.parent.invalidateLayout, template.parent) end
        if type(template.parent.updateLayout) == "function" then pcall(template.parent.updateLayout, template.parent) end
        if type(template.parent.updateAbsolutePosition) == "function" then pcall(template.parent.updateAbsolutePosition, template.parent) end
    end

    W.embeddedButtonActive = true
    W.embeddedButtonStatus = "embedded Wardrobe GUI button cloned from bottom action row"
    return true
end

local function ASW_installNativeWardrobeButtonHook()
    local W = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
    if W == nil or W.nativeButtonHookInstalled == true then return end
    if WardrobeScreen == nil then
        W.nativeButtonStatus = "WardrobeScreen global not available yet"
        return
    end

    if type(WardrobeScreen.updateMenuButtons) == "function" then
        local oldUpdateMenuButtons = WardrobeScreen.updateMenuButtons
        WardrobeScreen.updateMenuButtons = function(screen, ...)
            local r = oldUpdateMenuButtons(screen, ...)
            ASW_injectNativeWardrobeSaveButton(screen)
            return r
        end
        W.nativeButtonHookInstalled = true
        W.nativeButtonStatus = "hooked WardrobeScreen.updateMenuButtons"
    else
        -- Some GUI screens build the button strip once onOpen rather than through
        -- updateMenuButtons. We still attempt direct injection on open/draw/update.
        W.nativeButtonHookInstalled = true
        W.nativeButtonStatus = "WardrobeScreen.updateMenuButtons not found; using direct injection fallback"
    end
end

local function ASW_installWardrobeClassModalBlockers()
    local W = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
    if W == nil or W.classBlockersInstalled == true then return end
    if WardrobeScreen == nil then return end

    W.classBlockerMethods = {}

    local function getSuperMethod(methodName)
        if type(WardrobeScreen.superClass) == "function" then
            local ok, super = pcall(WardrobeScreen.superClass, WardrobeScreen)
            if ok and type(super) == "table" and type(super[methodName]) == "function" then
                return super[methodName]
            end
        end
        return nil
    end

    local function wrapMethod(methodName, mode)
        local oldFn = WardrobeScreen[methodName]
        local superFn = nil
        if type(oldFn) ~= "function" then
            superFn = getSuperMethod(methodName)
            if type(superFn) ~= "function" then return end
            oldFn = function(screen, ...)
                return superFn(screen, ...)
            end
        end

        W.classBlockerMethods[methodName] = oldFn
        WardrobeScreen[methodName] = function(screen, ...)
            if ASW_shouldConsumeWardrobeInput() then
                local w = AvatarSwitcher.Wardrobe

                if w ~= nil and w.nativeDialogActive ~= true then
                    if methodName == "keyEvent" and w.keyEvent ~= nil then
                        local unicode, sym, modifier, isDown = ...
                        w:keyEvent(unicode, sym, modifier, isDown)
                    elseif methodName == "mouseEvent" and w.mouseEvent ~= nil then
                        local posX, posY, isDown, isUp, button = ...
                        w:mouseEvent(posX, posY, isDown, isUp, button)
                    end
                end

                -- GIANTS callbacks are not perfectly consistent:
                -- inputEvent returns eventUsed, while onClick* handlers commonly
                -- return eventUnused. Return the value that means "do not continue".
                if mode == "eventUsed" then
                    return true
                elseif mode == "eventUnused" then
                    return false
                end
                return
            end
            return oldFn(screen, ...)
        end
    end

    -- inputEvent is the important layer for GUI/action binding leakage. Backspace,
    -- Accept, Cancel and rename/change-name style actions can be routed here before
    -- keyEvent/mouseEvent wrappers see them.
    wrapMethod("inputEvent", "eventUsed")
    wrapMethod("keyEvent", "eventUsed")
    wrapMethod("mouseEvent", "eventUsed")

    -- These are TabbedMenu/ScreenElement-style callbacks used by WardrobeScreen.
    -- Returning false marks the action as consumed/handled.
    for _, methodName in ipairs({
        "onClickBack", "onClickCancel", "onClickOk", "onClickActivate",
        "onClickMenuExtra1", "onClickMenuExtra2", "onButtonBack",
        "onInputModeChanged", "onInputBindingsChanged"
    }) do
        wrapMethod(methodName, "eventUnused")
    end

    W.classBlockersInstalled = true
end


local function ASW_installWardrobeScreenHooks()
    local W = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
    if W == nil or W.hooksInstalled == true then return end
    W.hookAttempted = true

    if WardrobeScreen == nil then
        W.hookStatus = "WardrobeScreen global not available yet"
        return
    end

    ASW_installWardrobeClassModalBlockers()
    ASW_installNativeWardrobeButtonHook()

    local function onOpen(screen)
        local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
        if wardrobe ~= nil then
            wardrobe.active = true
            wardrobe.activeScreen = screen
            wardrobe.detected = true
            wardrobe.hookStatus = "WardrobeScreen hook active"
            ASW_injectNativeWardrobeSaveButton(screen)
            if wardrobe.nativeButtonActive ~= true then ASW_installEmbeddedWardrobeSaveButton(screen) end
        end
    end

    local function onClose(screen)
        local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
        if wardrobe ~= nil and wardrobe.activeScreen == screen then
            wardrobe.active = false
            wardrobe.activeScreen = nil
            wardrobe.detected = false
            wardrobe.buttonRect = nil
            if wardrobe.embeddedButton ~= nil and type(wardrobe.embeddedButton.setVisible) == "function" then wardrobe.embeddedButton:setVisible(false) end
            wardrobe.embeddedButtonActive = false
            if wardrobe.modalVisible ~= true then wardrobe.rects = {} end
            wardrobe.hookStatus = "WardrobeScreen closed"
        elseif wardrobe ~= nil then
            wardrobe.active = false
            wardrobe.activeScreen = nil
            wardrobe.detected = false
            wardrobe.buttonRect = nil
            if wardrobe.embeddedButton ~= nil and type(wardrobe.embeddedButton.setVisible) == "function" then wardrobe.embeddedButton:setVisible(false) end
            wardrobe.embeddedButtonActive = false
            wardrobe.hookStatus = "WardrobeScreen closed"
        end
    end

    local function markActive(screen)
        local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
        if wardrobe ~= nil then
            wardrobe.active = true
            wardrobe.activeScreen = screen
            wardrobe.detected = true
            if wardrobe.nativeButtonActive ~= true then
                ASW_injectNativeWardrobeSaveButton(screen)
            end
            if wardrobe.nativeButtonActive ~= true then
                ASW_installEmbeddedWardrobeSaveButton(screen)
            end
        end
    end

    if type(WardrobeScreen.draw) == "function" then
        W.drawHookInstalled = true
        local oldDraw = WardrobeScreen.draw
        WardrobeScreen.draw = function(screen, ...)
            local r = oldDraw(screen, ...)
            markActive(screen)
            local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
            if wardrobe ~= nil and wardrobe._drawingFromWardrobeScreen ~= true then
                wardrobe._drawingFromWardrobeScreen = true
                wardrobe:draw()
                wardrobe._drawingFromWardrobeScreen = false
            end
            return r
        end
    end

    if type(WardrobeScreen.mouseEvent) == "function" then
        W.mouseHookInstalled = true
        local oldMouseEvent = WardrobeScreen.mouseEvent
        WardrobeScreen.mouseEvent = function(screen, posX, posY, isDown, isUp, button, ...)
            markActive(screen)
            local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
            if wardrobe ~= nil and wardrobe:mouseEvent(posX, posY, isDown, isUp, button) == true then
                return
            end
            return oldMouseEvent(screen, posX, posY, isDown, isUp, button, ...)
        end
    end

    if type(WardrobeScreen.keyEvent) == "function" then
        W.keyHookInstalled = true
        local oldKeyEvent = WardrobeScreen.keyEvent
        WardrobeScreen.keyEvent = function(screen, unicode, sym, modifier, isDown, ...)
            markActive(screen)
            local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
            if wardrobe ~= nil then
                wardrobe._handlingWardrobeScreenKeyEvent = true
                local handled = wardrobe:keyEvent(unicode, sym, modifier, isDown)
                wardrobe._handlingWardrobeScreenKeyEvent = false
                if handled == true then
                    return
                end
            end
            return oldKeyEvent(screen, unicode, sym, modifier, isDown, ...)
        end
    end

    if Utils ~= nil and Utils.appendedFunction ~= nil then
        if WardrobeScreen.onOpen ~= nil then WardrobeScreen.onOpen = Utils.appendedFunction(WardrobeScreen.onOpen, onOpen) end
        if WardrobeScreen.onClose ~= nil then WardrobeScreen.onClose = Utils.appendedFunction(WardrobeScreen.onClose, onClose) end
    elseif ClassUtil ~= nil and ClassUtil.appendedFunction ~= nil then
        if WardrobeScreen.onOpen ~= nil then WardrobeScreen.onOpen = ClassUtil.appendedFunction(WardrobeScreen.onOpen, onOpen) end
        if WardrobeScreen.onClose ~= nil then WardrobeScreen.onClose = ClassUtil.appendedFunction(WardrobeScreen.onClose, onClose) end
    else
        local oldOpen = WardrobeScreen.onOpen
        if type(oldOpen) == "function" then
            WardrobeScreen.onOpen = function(screen, ...)
                local r = oldOpen(screen, ...)
                onOpen(screen)
                return r
            end
        end
        local oldClose = WardrobeScreen.onClose
        if type(oldClose) == "function" then
            WardrobeScreen.onClose = function(screen, ...)
                local r = oldClose(screen, ...)
                onClose(screen)
                return r
            end
        end
    end

    if WardrobeScreen.onOpen ~= nil or WardrobeScreen.onClose ~= nil then
        W.hooksInstalled = true
        W.hookStatus = "WardrobeScreen hooks installed"
    else
        W.hookStatus = "WardrobeScreen found, but no onOpen/onClose methods were hookable"
    end
end

local function ASW_isWardrobeName(name)
    local n = ASW_lower(name)
    if n == "" then return false end
    return string.find(n, "wardrobe", 1, true) ~= nil
        or string.find(n, "playerstyle", 1, true) ~= nil
        or string.find(n, "player_style", 1, true) ~= nil
        or string.find(n, "charactercreation", 1, true) ~= nil
        or string.find(n, "charactercreation", 1, true) ~= nil
        or (string.find(n, "character", 1, true) ~= nil and string.find(n, "style", 1, true) ~= nil)
        or (string.find(n, "player", 1, true) ~= nil and string.find(n, "style", 1, true) ~= nil)
end

local function ASW_isPlayerStyleObject(obj)
    return type(obj) == "table" and type(obj.configs) == "table"
end

local function ASW_findPlayerStyleObject(root, depth, seen)
    if type(root) ~= "table" or depth <= 0 then return nil end
    seen = seen or {}
    if seen[root] then return nil end
    seen[root] = true

    if ASW_isPlayerStyleObject(root) then return root end

    for key, value in pairs(root) do
        if type(value) == "table" then
            local keyText = ASW_lower(key)
            if string.find(keyText, "style", 1, true) ~= nil or string.find(keyText, "player", 1, true) ~= nil or string.find(keyText, "character", 1, true) ~= nil or string.find(keyText, "wardrobe", 1, true) ~= nil then
                local found = ASW_findPlayerStyleObject(value, depth - 1, seen)
                if found ~= nil then return found end
            end
        end
    end

    -- Second pass, shallow and conservative, catches anonymous nested GUI fields.
    if depth > 2 then
        for _, value in pairs(root) do
            if type(value) == "table" then
                local found = ASW_findPlayerStyleObject(value, depth - 1, seen)
                if found ~= nil then return found end
            end
        end
    end

    return nil
end

local function ASW_getGuiNameCandidates()
    local names = {}
    if g_gui ~= nil then
        local keys = { "currentGuiName", "currentScreenName", "currentDialogName", "currentScreen" }
        for _, key in ipairs(keys) do
            if g_gui[key] ~= nil and type(g_gui[key]) ~= "table" then table.insert(names, tostring(g_gui[key])) end
        end
        if g_gui.currentGui ~= nil then
            table.insert(names, tostring(g_gui.currentGui))
            if type(g_gui.currentGui) == "table" then
                for _, key in ipairs({"name", "className", "profile", "guiName", "screenName"}) do
                    if g_gui.currentGui[key] ~= nil and type(g_gui.currentGui[key]) ~= "table" then table.insert(names, tostring(g_gui.currentGui[key])) end
                end
            end
        end
        if g_gui.currentScreen ~= nil then
            table.insert(names, tostring(g_gui.currentScreen))
            if type(g_gui.currentScreen) == "table" then
                for _, key in ipairs({"name", "className", "profile", "guiName", "screenName"}) do
                    if g_gui.currentScreen[key] ~= nil and type(g_gui.currentScreen[key]) ~= "table" then table.insert(names, tostring(g_gui.currentScreen[key])) end
                end
            end
        end
    end
    return names
end

local function ASW_currentGuiLooksLikeWardrobe()
    ASW_installWardrobeScreenHooks()
    if AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.active == true then return true end
    if g_gui == nil then return false end

    for _, name in ipairs(ASW_getGuiNameCandidates()) do
        if ASW_isWardrobeName(name) then return true end
    end

    local roots = { g_gui.currentGui, g_gui.currentScreen, g_gui.targetScreen }
    for _, root in ipairs(roots) do
        if root ~= nil and ASW_findPlayerStyleObject(root, 4) ~= nil then return true end
    end

    if type(g_gui.screenControllers) == "table" then
        for screenName, controller in pairs(g_gui.screenControllers) do
            if ASW_isWardrobeName(screenName) and controller ~= nil then
                -- Only use this as a weak positive if it also appears to be active/open.
                if controller.isOpen == true or controller.visible == true or controller.isVisible == true or controller.isActive == true then
                    return true
                end
            end
        end
    end

    return false
end

local function ASW_getSelectedItemName(config)
    if config == nil then return nil end
    if type(config.getSelectedItemName) == "function" then
        local ok, value = pcall(config.getSelectedItemName, config)
        if ok and value ~= nil and tostring(value) ~= "" then return tostring(value) end
    end
    if config.selectedItem ~= nil and type(config.selectedItem) == "table" then
        local item = config.selectedItem
        return item.name or item.saveId or item.xmlFilename or item.filename
    end
    local index = tonumber(config.selectedItemIndex or config.selectedIndex or config.itemIndex)
    if index ~= nil and type(config.items) == "table" then
        local item = config.items[index] or config.items[index + 1]
        if type(item) == "table" then return item.name or item.saveId or item.xmlFilename or item.filename end
    end
    if config.name ~= nil and type(config.name) ~= "function" then return tostring(config.name) end
    return nil
end

local function ASW_getSelectedColorIndex(config)
    if config == nil then return nil end
    if type(config.getSelectedColorIndex) == "function" then
        local ok, value = pcall(config.getSelectedColorIndex, config)
        if ok and value ~= nil then return tostring(value) end
    end
    local value = config.selectedColorIndex or config.colorIndex or config.selectedColor
    if value ~= nil then return tostring(value) end
    return nil
end

local function ASW_styleFromPlayerStyle(mod, playerStyle)
    if not ASW_isPlayerStyleObject(playerStyle) then return nil end
    local fallback = mod:getCurrentStyleFromGameSettings()
    local style = {
        filename = playerStyle.xmlFilename or playerStyle.filename or playerStyle.configFilename or (fallback ~= nil and fallback.filename or nil),
        parts = {}
    }

    if style.filename == nil or tostring(style.filename) == "" then
        style.filename = "dataS/character/playerF/playerF.xml"
    end

    local foundAny = false
    for _, partName in ipairs(mod.STYLE_PARTS or {}) do
        local config = playerStyle.configs[partName]
        if config ~= nil then
            local name = ASW_getSelectedItemName(config)
            local color = ASW_getSelectedColorIndex(config)
            if name ~= nil or color ~= nil then
                style.parts[partName] = { name = name, color = color }
                foundAny = true
            end
        elseif fallback ~= nil and fallback.parts ~= nil and fallback.parts[partName] ~= nil then
            style.parts[partName] = fallback.parts[partName]
        end
    end

    if not foundAny and fallback ~= nil then return fallback end
    return style
end

function AvatarSwitcher:getCurrentStyleForWardrobeSave()
    self:initialize()

    local roots = {}
    if AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.activeScreen ~= nil then
        table.insert(roots, AvatarSwitcher.Wardrobe.activeScreen)
    end
    if g_gui ~= nil then
        table.insert(roots, g_gui.currentGui)
        table.insert(roots, g_gui.currentScreen)
        table.insert(roots, g_gui.targetScreen)
        if type(g_gui.screenControllers) == "table" then
            for screenName, controller in pairs(g_gui.screenControllers) do
                if ASW_isWardrobeName(screenName) then table.insert(roots, controller) end
            end
        end
    end

    for _, root in ipairs(roots) do
        local playerStyle = ASW_findPlayerStyleObject(root, 5)
        if playerStyle ~= nil then
            local style = ASW_styleFromPlayerStyle(self, playerStyle)
            if style ~= nil then
                self:debug("[Wardrobe] Captured appearance from live PlayerStyle object")
                return style
            end
        end
    end

    if g_gameSettings ~= nil and ASW_isPlayerStyleObject(g_gameSettings.lastPlayerStyle) then
        local style = ASW_styleFromPlayerStyle(self, g_gameSettings.lastPlayerStyle)
        if style ~= nil then
            self:debug("[Wardrobe] Captured appearance from g_gameSettings.lastPlayerStyle")
            return style
        end
    end

    self:debug("[Wardrobe] Falling back to gameSettings.xml lastPlayerStyle")
    return self:getCurrentStyleFromGameSettings()
end

function AvatarSwitcher:saveWardrobePreset(id, description, category)
    self:initialize()
    id = ASW_sanitizeId(id)
    description = ASW_trim(description)
    category = ASW_trim(category)

    if id == "" then return false, "ID is required" end
    if description == "" then description = id end
    if category == "" then category = "custom" end

    if self.presetsById ~= nil and self.presetsById[id] ~= nil then
        return false, "Preset ID already exists: " .. tostring(id)
    end

    local style = self:getCurrentStyleForWardrobeSave()
    if style == nil then return false, "Could not capture current wardrobe appearance" end

    local ok = self:appendPresetToFile(id, description, category, style)
    if ok then
        if self.rebuildHudLists ~= nil then self:rebuildHudLists() end
        return true, "Saved preset: " .. tostring(description)
    end

    return false, "Preset save failed"
end

function AvatarSwitcher.Wardrobe:flash(msg, secs)
    self.message = tostring(msg or "")
    self.messageTime = tonumber(secs) or 2.0
end

function AvatarSwitcher.Wardrobe:addRect(id, x, y, w, h, data)
    self.rects = self.rects or {}
    table.insert(self.rects, { id = id, x = x, y = y, w = w, h = h, data = data })
end



local function ASW_isActionEventContainerKey(key)
    local k = ASW_lower(key)
    return string.find(k, "actionevent", 1, true) ~= nil
        or string.find(k, "actionevents", 1, true) ~= nil
        or string.find(k, "inputaction", 1, true) ~= nil
        or string.find(k, "inputactions", 1, true) ~= nil
end

local function ASW_collectActionEventIds(root, depth, path, out, seen)
    if type(root) ~= "table" or depth <= 0 then return end
    seen = seen or {}
    if seen[root] == true then return end
    seen[root] = true
    out = out or {}
    path = tostring(path or "")

    for key, value in pairs(root) do
        local keyText = tostring(key or "")
        local nextPath = path .. "." .. keyText
        local keyLooksRelevant = ASW_isActionEventContainerKey(keyText) or ASW_isActionEventContainerKey(path)

        if type(value) == "number" then
            if keyLooksRelevant then
                out[value] = true
            end
        elseif type(value) == "table" then
            -- Common GIANTS patterns are either inputActionEvents[actionName] = actionEventId
            -- or inputActionEvents[actionName] = { actionEventId = n }.
            if keyLooksRelevant then
                local id = value.actionEventId or value.actionEventID or value.eventId or value.id
                if type(id) == "number" then out[id] = true end
            end
            ASW_collectActionEventIds(value, depth - 1, nextPath, out, seen)
        end
    end
end

local function ASW_setActionEventActive(id, active)
    if g_inputBinding == nil or id == nil then return false end
    if type(g_inputBinding.setActionEventActive) == "function" then
        local ok = pcall(g_inputBinding.setActionEventActive, g_inputBinding, id, active == true)
        return ok == true
    end
    return false
end

local function ASW_shouldBlockWardrobeCallback(name)
    local n = ASW_lower(name)
    if n == "keyevent" or n == "mouseevent" then return false end
    return string.sub(n, 1, 7) == "onclick"
        or string.sub(n, 1, 8) == "onbutton"
        or string.sub(n, 1, 7) == "oninput"
        or string.sub(n, 1, 6) == "onback"
        or string.sub(n, 1, 8) == "onchange"
        or string.sub(n, 1, 8) == "onselect"
        or string.find(n, "rename", 1, true) ~= nil
        or string.find(n, "changename", 1, true) ~= nil
        or string.find(n, "inputevent", 1, true) ~= nil
        or string.find(n, "textevent", 1, true) ~= nil
        or string.find(n, "textinput", 1, true) ~= nil
end

local function ASW_getInputBlockerRoots()
    local roots = {}
    local seen = {}
    local function add(obj)
        if type(obj) == "table" and seen[obj] ~= true then
            seen[obj] = true
            table.insert(roots, obj)
        end
    end

    if AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe ~= nil then
        add(AvatarSwitcher.Wardrobe.activeScreen)
    end
    if g_gui ~= nil then
        add(g_gui.currentGui)
        add(g_gui.currentScreen)
        add(g_gui.targetScreen)
        if type(g_gui.screenControllers) == "table" then
            for screenName, controller in pairs(g_gui.screenControllers) do
                if ASW_isWardrobeName(screenName) then
                    add(controller)
                end
            end
        end
    end
    return roots
end

local function ASW_installModalInputBlockerForObject(obj, label)
    local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
    if wardrobe == nil or type(obj) ~= "table" then return end
    wardrobe._modalInputBlockers = wardrobe._modalInputBlockers or {}
    if wardrobe._modalInputBlockers[obj] ~= nil then return end

    local rec = { label = tostring(label or "unknown"), callbackWrappers = {} }
    local keyFn = obj.keyEvent
    local mouseFn = obj.mouseEvent

    if type(keyFn) == "function" then
        rec.keyEvent = keyFn
        rec.keyWrapper = function(screen, unicode, sym, modifier, isDown, ...)
            local w = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
            if w ~= nil and w.modalVisible == true then
                -- Own keyboard input exclusively while the AvatarSwitcher modal is open.
                if w.keyEvent ~= nil then
                    w:keyEvent(unicode, sym, modifier, isDown)
                end
                return
            end
            return rec.keyEvent(screen, unicode, sym, modifier, isDown, ...)
        end
        obj.keyEvent = rec.keyWrapper
    end

    if type(mouseFn) == "function" then
        rec.mouseEvent = mouseFn
        rec.mouseWrapper = function(screen, posX, posY, isDown, isUp, button, ...)
            local w = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
            if w ~= nil and w.modalVisible == true then
                if w.mouseEvent ~= nil then
                    w:mouseEvent(posX, posY, isDown, isUp, button)
                end
                return
            end
            return rec.mouseEvent(screen, posX, posY, isDown, isUp, button, ...)
        end
        obj.mouseEvent = rec.mouseWrapper
    end

    -- Some Wardrobe actions are not delivered through keyEvent/mouseEvent. They are
    -- registered as GUI/input action callbacks, e.g. Backspace can trigger the
    -- underlying rename/change-name flow. Wrap the common callback methods as a
    -- second modal fence. These wrappers only block while the AS modal is visible.
    for key, fn in pairs(obj) do
        if type(fn) == "function" and ASW_shouldBlockWardrobeCallback(key) then
            local oldFn = fn
            local keyName = key
            local wrapper = function(screen, ...)
                local w = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
                if w ~= nil and w.modalVisible == true then
                    return
                end
                return oldFn(screen, ...)
            end
            rec.callbackWrappers[keyName] = { old = oldFn, wrapper = wrapper }
            obj[keyName] = wrapper
        end
    end

    if rec.keyEvent ~= nil or rec.mouseEvent ~= nil or next(rec.callbackWrappers) ~= nil then
        wardrobe._modalInputBlockers[obj] = rec
        wardrobe._modalInputBlockerCount = (wardrobe._modalInputBlockerCount or 0) + 1
    end
end

local function ASW_disableWardrobeActionEventsForRoot(root)
    local wardrobe = AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe or nil
    if wardrobe == nil or type(root) ~= "table" then return end
    wardrobe._modalDisabledActionEvents = wardrobe._modalDisabledActionEvents or {}
    local ids = {}
    ASW_collectActionEventIds(root, 6, "root", ids, {})
    for id, _ in pairs(ids) do
        if wardrobe._modalDisabledActionEvents[id] ~= true then
            if ASW_setActionEventActive(id, false) then
                wardrobe._modalDisabledActionEvents[id] = true
                wardrobe._modalDisabledActionEventCount = (wardrobe._modalDisabledActionEventCount or 0) + 1
            end
        end
    end
end

function AvatarSwitcher.Wardrobe:installModalInputBlockers()
    for _, root in ipairs(ASW_getInputBlockerRoots()) do
        ASW_installModalInputBlockerForObject(root, tostring(root))
        ASW_disableWardrobeActionEventsForRoot(root)
    end
end

function AvatarSwitcher.Wardrobe:removeModalInputBlockers()
    local blockers = self._modalInputBlockers or {}
    for obj, rec in pairs(blockers) do
        if type(obj) == "table" and type(rec) == "table" then
            if rec.keyEvent ~= nil and obj.keyEvent == rec.keyWrapper then
                obj.keyEvent = rec.keyEvent
            end
            if rec.mouseEvent ~= nil and obj.mouseEvent == rec.mouseWrapper then
                obj.mouseEvent = rec.mouseEvent
            end
            if type(rec.callbackWrappers) == "table" then
                for keyName, wrapRec in pairs(rec.callbackWrappers) do
                    if type(wrapRec) == "table" and obj[keyName] == wrapRec.wrapper then
                        obj[keyName] = wrapRec.old
                    end
                end
            end
        end
    end
    self._modalInputBlockers = {}
    self._modalInputBlockerCount = 0

    local disabled = self._modalDisabledActionEvents or {}
    for id, _ in pairs(disabled) do
        ASW_setActionEventActive(id, true)
    end
    self._modalDisabledActionEvents = {}
    self._modalDisabledActionEventCount = 0
end

function AvatarSwitcher.Wardrobe:openModal()
    if AvatarSwitcher ~= nil and AvatarSwitcher.initialize ~= nil then AvatarSwitcher:initialize() end
    ASW_installWardrobeClassModalBlockers()

    if AvatarSwitcher ~= nil and AvatarSwitcher.openWardrobeSaveDialog ~= nil then
        AvatarSwitcher:openWardrobeSaveDialog()
    else
        -- Fallback for partial loads: keep the legacy raw modal available.
        self.nativeDialogActive = false
        self.modalVisible = true
        self.focus = "id"
        self.rects = {}
        if self.fields == nil then self.fields = {} end
        self.fields.id = self.fields.id or ""
        self.fields.description = self.fields.description or ""
        self.fields.category = self.fields.category or "custom"
        self:installModalInputBlockers()
        self:flash("Save current wardrobe appearance", 1.4)
    end
end

function AvatarSwitcher.Wardrobe:closeModal(clear)
    self:removeModalInputBlockers()
    self.nativeDialogActive = false
    self.saveDialogOpen = false
    self.modalVisible = false
    self.rects = {}
    if clear == true then
        self.fields = { id = "", description = "", category = "custom" }
        self.focus = "id"
    end
end

function AvatarSwitcher.Wardrobe:drawButton()
    local w, h = 0.095, 0.036
    local x, y = 0.885, 0.91
    self.buttonRect = { id = "openWardrobeSave", x = x, y = y, w = w, h = h }
    ASW_drawRect(x, y, w, h, 0.035, 0.035, 0.04, 0.94)
    ASW_drawRect(x, y + h - 0.002, w, 0.002, 0.72, 0.82, 0.95, 0.62)
    ASW_text(x + 0.023, y + 0.011, 0.0135, "SAVE", 1, 1, 1, 1)
end

function AvatarSwitcher.Wardrobe:drawTextField(id, label, x, y, w, h, maxLen)
    local active = self.focus == id
    ASW_text(x, y + h + 0.004, 0.0115, label, 0.72, 0.82, 0.95, 1)
    ASW_drawRect(x, y, w, h, active and 0.13 or 0.075, active and 0.15 or 0.075, active and 0.19 or 0.08, 0.98)
    ASW_drawRect(x, y + h - 0.002, w, 0.002, 0.72, 0.82, 0.95, active and 0.82 or 0.32)
    local value = self.fields ~= nil and self.fields[id] or ""
    local caret = active and " |" or ""
    ASW_text(x + 0.008, y + 0.011, 0.0135, ASW_ellipsize(tostring(value or "") .. caret, maxLen or 46), 1, 1, 1, 1)
    self:addRect("field", x, y, w, h, { field = id })
end

function AvatarSwitcher.Wardrobe:drawButtonControl(id, label, x, y, w, h, enabled)
    enabled = enabled ~= false
    ASW_drawRect(x, y, w, h, enabled and 0.18 or 0.08, enabled and 0.18 or 0.08, enabled and 0.19 or 0.08, 0.94)
    ASW_drawRect(x, y + h - 0.002, w, 0.002, 0.72, 0.82, 0.95, enabled and 0.52 or 0.18)
    ASW_text(x + 0.010, y + 0.011, 0.013, label, enabled and 1 or 0.55, enabled and 1 or 0.55, enabled and 1 or 0.55, 1)
    if enabled then self:addRect(id, x, y, w, h) end
end

function AvatarSwitcher.Wardrobe:drawModal()
    self.rects = {}
    local panelW, panelH = 0.46, 0.36
    local x, y = (1 - panelW) / 2, (1 - panelH) / 2
    local pad = 0.018

    ASW_drawRect(0, 0, 1, 1, 0, 0, 0, 0.68)
    ASW_drawRect(x, y, panelW, panelH, 0.025, 0.025, 0.028, 0.98)
    ASW_drawRect(x, y + panelH - 0.046, panelW, 0.046, 0.08, 0.10, 0.13, 0.99)
    ASW_text(x + pad, y + panelH - 0.031, 0.017, "Save to AvatarSwitcher", 1, 1, 1, 1)

    local fieldX = x + pad
    local fieldW = panelW - pad * 2
    local topY = y + panelH - 0.100
    self:drawTextField("id", "Preset ID", fieldX, topY, fieldW, 0.037, 52)
    self:drawTextField("description", "Description", fieldX, topY - 0.074, fieldW, 0.037, 52)
    self:drawTextField("category", "Category", fieldX, topY - 0.148, fieldW, 0.037, 52)

    ASW_text(fieldX, y + 0.082, 0.0115, "Tip: IDs are stored without spaces; description is what you see in the picker.", 0.75, 0.80, 0.86, 1)

    if self.message ~= nil and self.message ~= "" and (self.messageTime or 0) > 0 then
        ASW_text(fieldX, y + 0.055, 0.0125, self.message, 0.95, 0.88, 0.62, 1)
    end

    local by = y + pad
    self:drawButtonControl("save", "Save", x + panelW - pad - 0.178, by, 0.078, 0.038, true)
    self:drawButtonControl("cancel", "Cancel", x + panelW - pad - 0.090, by, 0.090, 0.038, true)

    ASW_setTextColor(1, 1, 1, 1)
end

function AvatarSwitcher.Wardrobe:save()
    if AvatarSwitcher == nil or AvatarSwitcher.saveWardrobePreset == nil then
        self:flash("Save failed: AvatarSwitcher not ready", 2.5)
        return false
    end
    local ok, msg = AvatarSwitcher:saveWardrobePreset(self.fields.id, self.fields.description, self.fields.category)
    self:flash(msg, ok and 2.0 or 3.0)
    if ok then
        if AvatarSwitcher.notify ~= nil then AvatarSwitcher:notify(msg) end
        self:closeModal(true)
    end
    return ok
end

function AvatarSwitcher.Wardrobe:draw()
    if self._drawingFromWardrobeScreen ~= true and self.drawHookInstalled == true and self.active == true then
        -- When WardrobeScreen.draw is hooked, that path owns the overlay render to keep it above wardrobe controls.
        return
    end
    local wardrobeOpen = ASW_currentGuiLooksLikeWardrobe()
    self.detected = wardrobeOpen

    if self.modalVisible == true then
        if self.nativeDialogActive ~= true then
            self:drawModal()
        end
        return
    end

    if wardrobeOpen then
        if self.activeScreen ~= nil and self.nativeButtonActive ~= true then
            ASW_injectNativeWardrobeSaveButton(self.activeScreen)
        end
        if self.activeScreen ~= nil and self.nativeButtonActive ~= true and self.embeddedButtonActive ~= true then
            ASW_installEmbeddedWardrobeSaveButton(self.activeScreen)
        end
        if self.nativeButtonActive == true or self.embeddedButtonActive == true then
            self.buttonRect = nil
        else
            self:drawButton()
        end
    else
        self.nativeButtonActive = false
        self.buttonRect = nil
    end
end

function AvatarSwitcher.Wardrobe:update(dt)
    ASW_installWardrobeScreenHooks()
    ASW_installWardrobeClassModalBlockers()
    ASW_installNativeWardrobeButtonHook()
    if self.modalVisible == true and self.installModalInputBlockers ~= nil then
        self:installModalInputBlockers()
    end
    if self.messageTime ~= nil and self.messageTime > 0 then
        self.messageTime = math.max(0, self.messageTime - ((tonumber(dt) or 0) / 1000))
    end
end

function AvatarSwitcher.Wardrobe:handleRectClick(r)
    if r == nil then return false end
    if r.id == "field" and r.data ~= nil then
        self.focus = r.data.field
        return true
    elseif r.id == "save" then
        self:save()
        return true
    elseif r.id == "cancel" then
        self:closeModal(false)
        return true
    end
    return false
end

function AvatarSwitcher.Wardrobe:mouseEvent(posX, posY, isDown, isUp, button)
    local leftButton = Input ~= nil and Input.MOUSE_BUTTON_LEFT or 1
    if button ~= nil and button ~= leftButton and button ~= 1 then
        return self.modalVisible == true
    end
    if isUp ~= true then return self.modalVisible == true end

    local x = tonumber(posX) or 0
    local y = tonumber(posY) or 0

    if self.modalVisible == true then
        local rects = self.rects or {}
        for i = #rects, 1, -1 do
            local r = rects[i]
            if ASW_pointInRect(x, y, r) then
                self:handleRectClick(r)
                return true
            end
        end
        return true
    end

    if self.buttonRect ~= nil and ASW_pointInRect(x, y, self.buttonRect) then
        self:openModal()
        return true
    end

    return false
end

function AvatarSwitcher.Wardrobe:keyEvent(unicode, sym, modifier, isDown)
    if self.modalVisible ~= true or isDown ~= true then return false end

    -- FS calls key events through the WardrobeScreen hook and again through the
    -- mod event listener. Without this guard, text input is appended twice, e.g.
    -- "testing" becomes "tteessttiinngg". Consume only the first copy of an
    -- identical key event within a very small time window.
    local now = tonumber(g_time) or (getTimeSec ~= nil and math.floor(getTimeSec() * 1000)) or 0
    local sig = tostring(unicode or "") .. ":" .. tostring(sym or "") .. ":" .. tostring(modifier or "") .. ":" .. tostring(isDown)
    if self._lastKeyEventSignature == sig and self._lastKeyEventTime ~= nil and math.abs(now - self._lastKeyEventTime) < 75 then
        return true
    end
    self._lastKeyEventSignature = sig
    self._lastKeyEventTime = now

    self.fields = self.fields or { id = "", description = "", category = "custom" }
    local field = self.focus or "id"
    self.fields[field] = self.fields[field] or ""

    local backspace = (Input ~= nil and Input.KEY_backspace) or 14
    local deleteKey = (Input ~= nil and Input.KEY_delete) or 211
    local enter = (Input ~= nil and Input.KEY_return) or 28
    local escape = (Input ~= nil and Input.KEY_esc) or 1
    local tab = (Input ~= nil and Input.KEY_tab) or 15

    if sym == backspace then
        self.fields[field] = string.sub(self.fields[field], 1, math.max(0, string.len(self.fields[field]) - 1))
        return true
    elseif sym == deleteKey then
        self.fields[field] = ""
        return true
    elseif sym == enter then
        self:save()
        return true
    elseif sym == escape then
        self:closeModal(false)
        return true
    elseif sym == tab then
        if field == "id" then self.focus = "description"
        elseif field == "description" then self.focus = "category"
        else self.focus = "id" end
        return true
    end

    local code = tonumber(unicode)
    if code ~= nil and code >= 32 and code <= 126 then
        local ch = string.char(code)
        if field == "id" then
            if string.match(ch, "[%w_%- ]") then self.fields[field] = self.fields[field] .. ch end
        elseif field == "category" then
            if string.match(ch, "[%w_%- ]") then self.fields[field] = self.fields[field] .. ch end
        else
            self.fields[field] = self.fields[field] .. ch
        end
        return true
    end

    return true
end

function AvatarSwitcher:debugWardrobeStatus()
    self:initialize()
    ASW_installWardrobeScreenHooks()
    self:log("[WardrobeDebug] detected: " .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.detected))
    self:log("[WardrobeDebug] active hook state: " .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.active))
    self:log("[WardrobeDebug] hooks installed: " .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.hooksInstalled) .. " | draw=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.drawHookInstalled) .. " | mouse=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.mouseHookInstalled) .. " | key=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.keyHookInstalled) .. " | status=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.hookStatus))
    self:log("[WardrobeDebug] modal visible: " .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.modalVisible) .. " | native dialog=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.nativeDialogActive) .. " | modal blockers=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe._modalInputBlockerCount or 0) .. " | disabled action events=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe._modalDisabledActionEventCount or 0) .. " | class blockers=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.classBlockersInstalled))
    self:log("[WardrobeDebug] native SAVE button: hook=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.nativeButtonHookInstalled) .. " | injected=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.nativeButtonInjected) .. " | active=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.nativeButtonActive) .. " | fallback=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.nativeButtonFallback) .. " | status=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.nativeButtonStatus))
    self:log("[WardrobeDebug] embedded SAVE button: active=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.embeddedButtonActive) .. " | status=" .. tostring(AvatarSwitcher.Wardrobe ~= nil and AvatarSwitcher.Wardrobe.embeddedButtonStatus))
    self:log("[WardrobeDebug] WardrobeScreen global: " .. tostring(WardrobeScreen ~= nil))
    self:log("[WardrobeDebug] g_gui available: " .. tostring(g_gui ~= nil))
    local names = ASW_getGuiNameCandidates()
    if #names == 0 then
        self:log("[WardrobeDebug] current GUI candidate(s): <none>")
    else
        self:log("[WardrobeDebug] current GUI candidate(s): " .. table.concat(names, " | "))
    end
    if g_gui ~= nil and type(g_gui.screenControllers) == "table" then
        for screenName, controller in pairs(g_gui.screenControllers) do
            if ASW_isWardrobeName(screenName) then
                self:log("[WardrobeDebug] wardrobe-like controller: " .. tostring(screenName) .. " | visible=" .. tostring(controller ~= nil and controller.visible) .. " | isOpen=" .. tostring(controller ~= nil and controller.isOpen) .. " | isActive=" .. tostring(controller ~= nil and controller.isActive))
            end
        end
    end
end

addModEventListener(AvatarSwitcher.Wardrobe)
