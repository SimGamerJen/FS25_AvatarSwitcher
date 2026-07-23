-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.0
-- File: AS_SaveDialog.lua
-- BuildTag: 20260514.11
-- FS25-native GUI dialog for saving the current Wardrobe appearance as an AvatarSwitcher preset.

AvatarSwitcher = AvatarSwitcher or {}

AvatarSwitcherSaveDialog = {}
local AvatarSwitcherSaveDialog_mt = Class(AvatarSwitcherSaveDialog, MessageDialog)

function AvatarSwitcherSaveDialog.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or AvatarSwitcherSaveDialog_mt)
    self.avatarSwitcher = AvatarSwitcher
    self.fields = { id = "", description = "", category = "custom" }
    self.focus = "id"
    self.message = AvatarSwitcher:getText("as_save_instructions", "Enter an ID, description and category for the current wardrobe appearance.")
    return self
end

local function ASSD_trim(v)
    return tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function ASSD_sanitizeIdPreview(value)
    local s = ASSD_trim(value)
    s = s:gsub("%s+", "_")
    s = s:gsub("[^A-Za-z0-9_%-]", "")
    return s
end

local function ASSD_ellipsize(text, maxLen)
    text = tostring(text or "")
    maxLen = tonumber(maxLen) or 48
    if string.len(text) <= maxLen then return text end
    return string.sub(text, 1, math.max(1, maxLen - 1)) .. "…"
end

function AvatarSwitcherSaveDialog:onGuiSetupFinished()
    AvatarSwitcherSaveDialog:superClass().onGuiSetupFinished(self)
    self:updateLocalizedTexts()
    self:updateFieldTexts()
end

function AvatarSwitcherSaveDialog:onCreate()
    AvatarSwitcherSaveDialog:superClass().onCreate(self)
end

function AvatarSwitcherSaveDialog:updateLocalizedTexts()
    local mod = self.avatarSwitcher or AvatarSwitcher
    if mod == nil or mod.getText == nil then return end

    local function setText(element, key, fallback)
        if element ~= nil and type(element.setText) == "function" then
            element:setText(mod:getText(key, fallback))
        end
    end

    setText(self.dialogTitleElement, "as_save_avatar", "Save Avatar")
    setText(self.presetIdHeaderText, "as_preset_id", "Preset ID")
    setText(self.descriptionHeaderText, "as_description", "Description")
    setText(self.categoryHeaderText, "as_category", "Category")
    setText(self.cancelButton, "as_cancel", "Cancel")
    setText(self.saveButton, "as_save", "Save")
end

function AvatarSwitcherSaveDialog:onOpen()
    AvatarSwitcherSaveDialog:superClass().onOpen(self)
    self:updateLocalizedTexts()
    self.fields = { id = "", description = "", category = "custom" }
    self.focus = "id"
    self.message = AvatarSwitcher:getText("as_save_instructions", "Enter an ID, description and category for the current wardrobe appearance.")
    self:updateFieldTexts()

    if AvatarSwitcher ~= nil and AvatarSwitcher.Wardrobe ~= nil then
        AvatarSwitcher.Wardrobe.modalVisible = true
        AvatarSwitcher.Wardrobe.nativeDialogActive = true
        AvatarSwitcher.Wardrobe.saveDialogOpen = true
        if AvatarSwitcher.Wardrobe.installModalInputBlockers ~= nil then
            AvatarSwitcher.Wardrobe:installModalInputBlockers()
        end
    end
end

function AvatarSwitcherSaveDialog:onClose()
    AvatarSwitcherSaveDialog:superClass().onClose(self)
    if AvatarSwitcher ~= nil then
        AvatarSwitcher.wardrobeSaveDialog = nil
        if AvatarSwitcher.Wardrobe ~= nil then
            AvatarSwitcher.Wardrobe.nativeDialogActive = false
            AvatarSwitcher.Wardrobe.saveDialogOpen = false
            AvatarSwitcher.Wardrobe.modalVisible = false
            if AvatarSwitcher.Wardrobe.removeModalInputBlockers ~= nil then
                AvatarSwitcher.Wardrobe:removeModalInputBlockers()
            end
        end
    end
end

function AvatarSwitcherSaveDialog:setFocusField(field)
    self.focus = field or "id"
    self:updateFieldTexts()
end

function AvatarSwitcherSaveDialog:getFieldDisplay(field, label)
    local value = self.fields ~= nil and self.fields[field] or ""
    value = tostring(value or "")
    if field == "id" then
        local clean = ASSD_sanitizeIdPreview(value)
        if clean ~= value and clean ~= "" then
            value = value .. "  →  " .. clean
        end
    elseif field == "category" and AvatarSwitcher ~= nil and AvatarSwitcher.getCategoryDisplayName ~= nil then
        value = AvatarSwitcher:getCategoryDisplayName(value)
    end
    local caret = self.focus == field and "  |" or ""
    if value == "" then
        value = tostring(label or "")
    end
    return ASSD_ellipsize(value .. caret, 64)
end

function AvatarSwitcherSaveDialog:updateFieldTexts()
    if self.idField ~= nil then self.idField:setText(self:getFieldDisplay("id", AvatarSwitcher:getText("as_preset_id", "Preset ID"))) end
    if self.descriptionField ~= nil then self.descriptionField:setText(self:getFieldDisplay("description", AvatarSwitcher:getText("as_description", "Description"))) end
    if self.categoryField ~= nil then self.categoryField:setText(self:getFieldDisplay("category", AvatarSwitcher:getText("as_category", "Category"))) end
    if self.messageText ~= nil then self.messageText:setText(tostring(self.message or "")) end
end

function AvatarSwitcherSaveDialog:onClickIdField()
    self:setFocusField("id")
end

function AvatarSwitcherSaveDialog:onClickDescriptionField()
    self:setFocusField("description")
end

function AvatarSwitcherSaveDialog:onClickCategoryField()
    self:setFocusField("category")
end

function AvatarSwitcherSaveDialog:onClickBack()
    self:close()
end

function AvatarSwitcherSaveDialog:onClickSave()
    if AvatarSwitcher == nil or AvatarSwitcher.saveWardrobePreset == nil then
        self.message = AvatarSwitcher:getText("as_not_ready", "AvatarSwitcher is not ready.")
        self:updateFieldTexts()
        return
    end

    local ok, msg = AvatarSwitcher:saveWardrobePreset(self.fields.id, self.fields.description, self.fields.category)
    self.message = tostring(msg or (ok and AvatarSwitcher:getText("as_saved", "Saved.") or AvatarSwitcher:getText("as_save_failed", "Save failed.")))
    self:updateFieldTexts()

    if ok then
        if AvatarSwitcher.notify ~= nil then AvatarSwitcher:notify(msg) end
        self:close()
    end
end

function AvatarSwitcherSaveDialog:keyEvent(unicode, sym, modifier, isDown)
    if isDown ~= true then return true end

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
        self:updateFieldTexts()
        return true
    elseif sym == deleteKey then
        self.fields[field] = ""
        self:updateFieldTexts()
        return true
    elseif sym == enter then
        self:onClickSave()
        return true
    elseif sym == escape then
        self:close()
        return true
    elseif sym == tab then
        if field == "id" then self.focus = "description"
        elseif field == "description" then self.focus = "category"
        else self.focus = "id" end
        self:updateFieldTexts()
        return true
    end

    local code = tonumber(unicode)
    if code ~= nil and code >= 32 and code <= 126 then
        local ch = string.char(code)
        if field == "id" or field == "category" then
            if string.match(ch, "[%w_%- ]") then
                self.fields[field] = self.fields[field] .. ch
            end
        else
            self.fields[field] = self.fields[field] .. ch
        end
        self:updateFieldTexts()
        return true
    end

    return true
end

function AvatarSwitcher:openWardrobeSaveDialog()
    self:initialize()
    if g_gui == nil then
        self:warn("[WardrobeSaveDialog] g_gui is not available")
        return false
    end

    if self.wardrobeSaveDialog ~= nil then
        return true
    end

    if g_gui.loadProfiles ~= nil then
        g_gui:loadProfiles(self.modDirectory .. "gui/guiProfiles.xml")
    end

    local dlgFrame = AvatarSwitcherSaveDialog.new(g_i18n)
    g_gui:loadGui(self.modDirectory .. "gui/AS_SaveDialog.xml", "AvatarSwitcherSaveDialog", dlgFrame)
    self.wardrobeSaveDialog = g_gui:showDialog("AvatarSwitcherSaveDialog")

    return self.wardrobeSaveDialog ~= nil
end
