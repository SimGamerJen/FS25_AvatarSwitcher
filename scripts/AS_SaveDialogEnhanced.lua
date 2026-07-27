-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.0
-- File: AS_SaveDialogEnhanced.lua
-- BuildTag: 20260727.1
-- Structured Wardrobe save form with category selection, contextual help and live validation.

AvatarSwitcher = AvatarSwitcher or {}
AvatarSwitcherSaveDialog = AvatarSwitcherSaveDialog or {}

local ASSE_NEW_CATEGORY = "__new_category__"
local ASSE_baseNew = AvatarSwitcherSaveDialog.new

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function sanitizeId(value)
    local text = trim(value):gsub("%s+", "_")
    return text:gsub("[^A-Za-z0-9_%-]", "")
end

local function ellipsize(text, maximum)
    text = tostring(text or "")
    maximum = maximum or 58
    return #text <= maximum and text or text:sub(1, maximum - 1) .. "…"
end

local function removeLastCharacter(text)
    text = tostring(text or "")
    if text == "" then return text end
    if utf8 ~= nil and type(utf8.offset) == "function" then
        local start = utf8.offset(text, -1)
        if start ~= nil then return text:sub(1, start - 1) end
    end
    return text:sub(1, math.max(0, #text - 1))
end

local function characterFromUnicode(unicode)
    local code = tonumber(unicode)
    if code == nil or code < 32 then return nil end
    if utf8 ~= nil and type(utf8.char) == "function" then
        local ok, value = pcall(utf8.char, code)
        if ok then return value end
    end
    return code <= 255 and string.char(code) or nil
end

function AvatarSwitcherSaveDialog.new(target, custom_mt)
    local self = ASSE_baseNew(target, custom_mt)
    self.fields = {id = "", displayName = "", newCategory = ""}
    self.focus = "id"
    self.categoryValues = {}
    self.categoryTexts = {}
    self.categoryIndex = 1
    self.suppressCategoryCallback = false
    self.resultMessage = nil
    return self
end

function AvatarSwitcherSaveDialog:onGuiSetupFinished()
    AvatarSwitcherSaveDialog:superClass().onGuiSetupFinished(self)
    self:updateLocalizedTexts()
    self:populateCategoryOptions()
    self:updateControls()
end

function AvatarSwitcherSaveDialog:updateLocalizedTexts()
    local mod = self.avatarSwitcher or AvatarSwitcher
    if mod == nil then return end
    local function set(element, key, fallback)
        if element ~= nil and element.setText ~= nil then element:setText(mod:getText(key, fallback)) end
    end
    set(self.dialogTitleElement, "as_save_avatar", "Save Avatar")
    set(self.presetIdHeaderText, "as_preset_id", "Preset ID")
    set(self.displayNameHeaderText, "as_display_name", "Display Name")
    set(self.categoryHeaderText, "as_category", "Category")
    set(self.newCategoryHeaderText, "as_new_category", "New Category")
    set(self.helpHeaderText, "as_help", "Help")
    set(self.cancelButton, "as_cancel", "Cancel")
    set(self.saveButton, "as_save", "Save")
end

function AvatarSwitcherSaveDialog:onOpen()
    AvatarSwitcherSaveDialog:superClass().onOpen(self)
    self.fields = {id = "", displayName = "", newCategory = ""}
    self.focus = "id"
    self.resultMessage = nil
    self:updateLocalizedTexts()
    self:populateCategoryOptions()
    self:updateControls()

    if FocusManager ~= nil and self.idField ~= nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.idField)
        self:setSoundSuppressed(false)
    end

    if AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe ~= nil then
        AvatarSwitcher.Wardrobe.modalVisible = true
        AvatarSwitcher.Wardrobe.nativeDialogActive = true
        AvatarSwitcher.Wardrobe.saveDialogOpen = true
        if AvatarSwitcher.Wardrobe.installModalInputBlockers ~= nil then
            AvatarSwitcher.Wardrobe:installModalInputBlockers()
        end
    end
end

function AvatarSwitcherSaveDialog:getExistingCategories()
    local categories, seen = {}, {}
    local function add(value)
        value = trim(value)
        local key = value:lower()
        if value ~= "" and key ~= "all" and seen[key] == nil then
            seen[key] = true
            table.insert(categories, value)
        end
    end

    add("custom")
    for _, preset in ipairs((self.avatarSwitcher or AvatarSwitcher).presets or {}) do
        add(preset.category or "custom")
    end
    table.sort(categories, function(a, b)
        if a:lower() == "custom" then return true end
        if b:lower() == "custom" then return false end
        return a:lower() < b:lower()
    end)
    return categories
end

function AvatarSwitcherSaveDialog:populateCategoryOptions()
    local mod = self.avatarSwitcher or AvatarSwitcher
    local previous = self:getSelectedCategoryValue()
    self.categoryValues = self:getExistingCategories()
    self.categoryTexts = {}

    for _, category in ipairs(self.categoryValues) do
        local display = mod.getCategoryDisplayName ~= nil and mod:getCategoryDisplayName(category) or category
        table.insert(self.categoryTexts, tostring(display))
    end
    table.insert(self.categoryValues, ASSE_NEW_CATEGORY)
    table.insert(self.categoryTexts, mod:getText("as_create_new_category", "+ Create new category…"))

    self.categoryIndex = 1
    for index, category in ipairs(self.categoryValues) do
        if category == previous then self.categoryIndex = index break end
    end

    self.suppressCategoryCallback = true
    if self.categoryOption ~= nil then
        if self.categoryOption.setTexts ~= nil then self.categoryOption:setTexts(self.categoryTexts) end
        if self.categoryOption.setState ~= nil then self.categoryOption:setState(self.categoryIndex, true) end
    end
    self.suppressCategoryCallback = false
end

function AvatarSwitcherSaveDialog:getSelectedCategoryValue()
    return (self.categoryValues or {})[self.categoryIndex or 1] or "custom"
end

function AvatarSwitcherSaveDialog:isCreatingNewCategory()
    return self:getSelectedCategoryValue() == ASSE_NEW_CATEGORY
end

function AvatarSwitcherSaveDialog:resolveCategory()
    local selected = self:getSelectedCategoryValue()
    if selected ~= ASSE_NEW_CATEGORY then return trim(selected) ~= "" and trim(selected) or "custom" end

    local entered = trim(self.fields.newCategory)
    for _, category in ipairs(self.categoryValues or {}) do
        if category ~= ASSE_NEW_CATEGORY and category:lower() == entered:lower() then return category end
    end
    return entered
end

function AvatarSwitcherSaveDialog:setFocusField(field)
    self.focus = field or "id"
    self.resultMessage = nil
    self:updateControls()
end

function AvatarSwitcherSaveDialog:getFieldDisplay(field, placeholder)
    local value = tostring((self.fields or {})[field] or "")
    if field == "id" then
        local clean = sanitizeId(value)
        if clean ~= "" and clean ~= value then value = value .. "  →  " .. clean end
    end
    if value == "" then value = placeholder or "" end
    if self.focus == field then value = value .. "  |" end
    return ellipsize(value)
end

function AvatarSwitcherSaveDialog:validateForm()
    local mod = self.avatarSwitcher or AvatarSwitcher
    local id = sanitizeId(self.fields.id)
    if id == "" then return false, mod:getText("as_validation_id_required", "Enter a Preset ID.") end
    if mod.presetsById ~= nil and mod.presetsById[id] ~= nil then
        return false, mod:formatText("as_validation_id_exists", "Preset ID already exists: %s", id)
    end
    if self:isCreatingNewCategory() and trim(self.fields.newCategory) == "" then
        return false, mod:getText("as_validation_new_category_required", "Enter a name for the new category.")
    end
    if trim(self.fields.displayName) == "" then
        return true, mod:getText("as_validation_ready_id_name", "Ready to save. The Preset ID will also be used as the display name.")
    end
    return true, mod:getText("as_validation_ready", "Ready to save this appearance.")
end

function AvatarSwitcherSaveDialog:updateHelpText()
    local mod = self.avatarSwitcher or AvatarSwitcher
    local key, title, body = "preset_id", "Preset ID", "A unique internal key used by Avatar Switcher and compatible mods.\n\nExample: jen_winter_workwear\n\nSpaces are saved as underscores. Use letters, numbers, underscores or hyphens."
    if self.focus == "displayName" then
        key, title, body = "display_name", "Display Name", "The readable name shown in the Avatar Switcher menu.\n\nExample: Jen – Winter Workwear\n\nLeave it blank to use the Preset ID."
    elseif self.focus == "category" then
        key, title, body = "category", "Category", "Groups related avatars together and provides category filtering.\n\nChoose an existing category or select Create new category."
    elseif self.focus == "newCategory" then
        key, title, body = "new_category", "New Category", "Enter a readable category name.\n\nExample: Seasonal\n\nIf the name already exists, Avatar Switcher reuses the existing category."
    end
    if self.helpTitleText ~= nil then self.helpTitleText:setText(mod:getText("as_help_" .. key .. "_title", title)) end
    if self.helpBodyText ~= nil then self.helpBodyText:setText(mod:getText("as_help_" .. key .. "_text", body)) end
end

function AvatarSwitcherSaveDialog:updateControls()
    local mod = self.avatarSwitcher or AvatarSwitcher
    if self.idField ~= nil then self.idField:setText(self:getFieldDisplay("id", mod:getText("as_preset_id_example", "e.g. jen_winter_workwear"))) end
    if self.displayNameField ~= nil then self.displayNameField:setText(self:getFieldDisplay("displayName", mod:getText("as_display_name_example", "e.g. Jen – Winter Workwear"))) end

    local creatingNew = self:isCreatingNewCategory()
    if self.newCategoryHeaderBox ~= nil then self.newCategoryHeaderBox:setVisible(creatingNew) end
    if self.newCategoryHeaderText ~= nil then self.newCategoryHeaderText:setVisible(creatingNew) end
    if self.newCategoryField ~= nil then
        self.newCategoryField:setVisible(creatingNew)
        self.newCategoryField:setText(self:getFieldDisplay("newCategory", mod:getText("as_new_category_example", "e.g. Seasonal")))
    end

    if self.categoryOption ~= nil and self.categoryOption.setState ~= nil then
        self.suppressCategoryCallback = true
        self.categoryOption:setState(self.categoryIndex or 1, true)
        self.suppressCategoryCallback = false
    end

    local valid, message = self:validateForm()
    if self.validationText ~= nil then self.validationText:setText(tostring(self.resultMessage or message or "")) end
    if self.saveButton ~= nil and self.saveButton.setDisabled ~= nil then self.saveButton:setDisabled(not valid) end
    self:updateHelpText()
end

function AvatarSwitcherSaveDialog:onClickIdField() self:setFocusField("id") end
function AvatarSwitcherSaveDialog:onClickDisplayNameField() self:setFocusField("displayName") end
function AvatarSwitcherSaveDialog:onClickNewCategoryField() self:setFocusField("newCategory") end

function AvatarSwitcherSaveDialog:onClickCategoryOption(state, optionElement)
    if self.suppressCategoryCallback then return end
    local index = tonumber(state)
    if index == nil and optionElement ~= nil and optionElement.getState ~= nil then index = tonumber(optionElement:getState()) end
    if index ~= nil then self.categoryIndex = math.max(1, math.min(index, #self.categoryValues)) end
    self.focus = "category"
    self.resultMessage = nil
    self:updateControls()
end

function AvatarSwitcherSaveDialog:onClickSave()
    local mod = self.avatarSwitcher or AvatarSwitcher
    if mod == nil or mod.saveWardrobePreset == nil then
        self.resultMessage = mod ~= nil and mod:getText("as_not_ready", "AvatarSwitcher is not ready.") or "AvatarSwitcher is not ready."
        self:updateControls()
        return
    end
    local valid, message = self:validateForm()
    if not valid then
        self.resultMessage = message
        self:updateControls()
        return
    end

    local ok, result = mod:saveWardrobePreset(self.fields.id, self.fields.displayName, self:resolveCategory())
    self.resultMessage = tostring(result or (ok and mod:getText("as_saved", "Saved.") or mod:getText("as_save_failed", "Save failed.")))
    self:updateControls()
    if ok then
        if mod.notify ~= nil then mod:notify(result) end
        self:close()
    end
end

function AvatarSwitcherSaveDialog:cycleCategory(delta)
    local count = #(self.categoryValues or {})
    if count == 0 then return end
    self.categoryIndex = (self.categoryIndex or 1) + delta
    if self.categoryIndex < 1 then self.categoryIndex = count end
    if self.categoryIndex > count then self.categoryIndex = 1 end
    self.resultMessage = nil
    self:updateControls()
end

function AvatarSwitcherSaveDialog:cycleFocus()
    if self.focus == "id" then self.focus = "displayName"
    elseif self.focus == "displayName" then self.focus = "category"
    elseif self.focus == "category" and self:isCreatingNewCategory() then self.focus = "newCategory"
    else self.focus = "id" end
    self.resultMessage = nil
    self:updateControls()
end

function AvatarSwitcherSaveDialog:keyEvent(unicode, sym, modifier, isDown)
    if isDown ~= true then return true end
    local backspace = (Input ~= nil and Input.KEY_backspace) or 14
    local deleteKey = (Input ~= nil and Input.KEY_delete) or 211
    local enter = (Input ~= nil and Input.KEY_return) or 28
    local escape = (Input ~= nil and Input.KEY_esc) or 1
    local tab = (Input ~= nil and Input.KEY_tab) or 15
    local left = (Input ~= nil and Input.KEY_left) or 203
    local right = (Input ~= nil and Input.KEY_right) or 205

    if sym == escape then self:close() return true end
    if sym == tab then self:cycleFocus() return true end
    if self.focus == "category" and sym == left then self:cycleCategory(-1) return true end
    if self.focus == "category" and sym == right then self:cycleCategory(1) return true end
    if sym == enter then
        if self.focus == "category" and self:isCreatingNewCategory() then self:setFocusField("newCategory") else self:onClickSave() end
        return true
    end
    if self.focus == "category" then return true end

    local field = self.focus or "id"
    self.fields[field] = self.fields[field] or ""
    if sym == backspace then self.fields[field] = removeLastCharacter(self.fields[field])
    elseif sym == deleteKey then self.fields[field] = ""
    else
        local character = characterFromUnicode(unicode)
        if character == nil then return true end
        if field ~= "id" or character:match("[%w_%- ]") then self.fields[field] = self.fields[field] .. character end
    end
    self.resultMessage = nil
    self:updateControls()
    return true
end
