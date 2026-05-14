-- FS25_AvatarSwitcher
-- ModVersion: 0.6.0-beta
-- File: AS_Dialog.lua
-- BuildTag: 20260514.3
-- FS25-native GUI dialog for selecting, applying and deleting AvatarSwitcher presets.

AvatarSwitcher = AvatarSwitcher or {}

AvatarSwitcherDialog = {}
local AvatarSwitcherDialog_mt = Class(AvatarSwitcherDialog, MessageDialog)

function AvatarSwitcherDialog.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or AvatarSwitcherDialog_mt)
    self.avatarSwitcher = AvatarSwitcher
    self.categoryRows = {}
    self.presetRows = {}
    self.selectedCategoryIndex = 1
    self.selectedPresetIndex = 1
    return self
end

local function ASD_toDisplayCategory(category)
    category = tostring(category or "general")
    if category == "all" then
        return "All"
    end
    return category
end

function AvatarSwitcherDialog:onGuiSetupFinished()
    AvatarSwitcherDialog:superClass().onGuiSetupFinished(self)

    if self.categoryTable ~= nil then
        self.categoryTable:setDataSource(self)
        self.categoryTable:setDelegate(self)
    end
    if self.presetTable ~= nil then
        self.presetTable:setDataSource(self)
        self.presetTable:setDelegate(self)
    end
end

function AvatarSwitcherDialog:onCreate()
    AvatarSwitcherDialog:superClass().onCreate(self)
end

function AvatarSwitcherDialog:onOpen()
    AvatarSwitcherDialog:superClass().onOpen(self)
    self:reloadData()

    if FocusManager ~= nil and self.categoryTable ~= nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.categoryTable)
        self:setSoundSuppressed(false)
    end
end

function AvatarSwitcherDialog:onClose()
    AvatarSwitcherDialog:superClass().onClose(self)
    if AvatarSwitcher ~= nil then
        AvatarSwitcher.guiDialog = nil
        if AvatarSwitcher.HUD ~= nil then
            AvatarSwitcher.HUD.visible = false
        end
    end
end

function AvatarSwitcherDialog:reloadData()
    local mod = self.avatarSwitcher or AvatarSwitcher
    if mod == nil then return end
    mod:initialize()
    if mod.rebuildHudLists ~= nil then
        mod:rebuildHudLists()
    end

    local categories = (mod.HUD ~= nil and mod.HUD.categories) or {"all"}
    self.categoryRows = {}
    for _, category in ipairs(categories) do
        local count = 0
        for _, preset in ipairs(mod.presets or {}) do
            if category == "all" or tostring(preset.category or "general") == category then
                count = count + 1
            end
        end
        table.insert(self.categoryRows, {
            category = category,
            label = ASD_toDisplayCategory(category),
            count = count
        })
    end

    self.selectedCategoryIndex = math.max(1, math.min(self.selectedCategoryIndex or 1, #self.categoryRows))
    self:rebuildPresetRows()

    if self.categoryTable ~= nil then self.categoryTable:reloadData() end
    if self.presetTable ~= nil then self.presetTable:reloadData() end
    self:updateDetailText()
end

function AvatarSwitcherDialog:rebuildPresetRows()
    local mod = self.avatarSwitcher or AvatarSwitcher
    local categoryRow = self.categoryRows[self.selectedCategoryIndex or 1]
    local category = categoryRow ~= nil and categoryRow.category or "all"

    self.presetRows = {}
    for _, preset in ipairs(mod.presets or {}) do
        if category == "all" or tostring(preset.category or "general") == category then
            table.insert(self.presetRows, preset)
        end
    end

    self.selectedPresetIndex = math.max(1, math.min(self.selectedPresetIndex or 1, math.max(1, #self.presetRows)))
end

function AvatarSwitcherDialog:getNumberOfSections(list)
    return 1
end

function AvatarSwitcherDialog:getNumberOfItemsInSection(list, section)
    if list == self.categoryTable then
        return #(self.categoryRows or {})
    elseif list == self.presetTable then
        return #(self.presetRows or {})
    end
    return 0
end

function AvatarSwitcherDialog:populateCellForItemInSection(list, section, index, cell)
    if list == self.categoryTable then
        local row = self.categoryRows[index]
        if row ~= nil then
            cell:getAttribute("CategoryName"):setText(tostring(row.label or row.category or ""))
            cell:getAttribute("CategoryCount"):setText(tostring(row.count or 0))
        end
    elseif list == self.presetTable then
        local preset = self.presetRows[index]
        if preset ~= nil then
            cell:getAttribute("PresetName"):setText(tostring(preset.name or preset.id or ""))
            cell:getAttribute("PresetId"):setText(tostring(preset.id or ""))
        end
    end
end

function AvatarSwitcherDialog:onListSelectionChanged(list, section, index)
    if list == self.categoryTable then
        self.selectedCategoryIndex = index or 1
        self.selectedPresetIndex = 1
        self:rebuildPresetRows()
        if self.presetTable ~= nil then
            self.presetTable:reloadData()
        end
    elseif list == self.presetTable then
        self.selectedPresetIndex = index or 1
    end
    self:updateDetailText()
end

function AvatarSwitcherDialog:getSelectedPreset()
    return self.presetRows ~= nil and self.presetRows[self.selectedPresetIndex or 1] or nil
end

function AvatarSwitcherDialog:updateDetailText()
    if self.detailText == nil then return end
    local preset = self:getSelectedPreset()
    if preset == nil then
        self.detailText:setText("No saved appearances in this category.")
        return
    end
    self.detailText:setText(string.format("Selected: %s   |   ID: %s   |   Category: %s", tostring(preset.name or preset.id), tostring(preset.id), tostring(preset.category or "general")))
end

function AvatarSwitcherDialog:onClickBack(sender)
    self:close()
end

function AvatarSwitcherDialog:onClickApply(sender)
    local preset = self:getSelectedPreset()
    if preset == nil then
        if AvatarSwitcher ~= nil and AvatarSwitcher.warn ~= nil then
            AvatarSwitcher:warn("[Dialog] No preset selected")
        end
        return
    end
    if AvatarSwitcher ~= nil and AvatarSwitcher.applyPreset ~= nil then
        AvatarSwitcher:applyPreset(tostring(preset.id or ""))
    end
end

function AvatarSwitcherDialog:onClickDelete(sender)
    local preset = self:getSelectedPreset()
    if preset == nil then
        return
    end

    local presetId = tostring(preset.id or "")
    local presetName = tostring(preset.name or preset.id or "")
    local function doDelete(arg1, arg2)
        local yes = arg1
        if type(arg1) == "table" and arg2 ~= nil then
            yes = arg2
        end
        if yes ~= true then return end
        if AvatarSwitcher ~= nil and AvatarSwitcher.deletePreset ~= nil then
            if AvatarSwitcher:deletePreset(presetId) == true then
                self.selectedPresetIndex = math.max(1, (self.selectedPresetIndex or 1) - 1)
                self:reloadData()
            end
        end
    end

    if g_gui ~= nil and g_gui.showYesNoDialog ~= nil then
        g_gui:showYesNoDialog({
            text = string.format("Delete AvatarSwitcher preset '%s'?", presetName),
            title = "Delete Appearance",
            callback = doDelete
        })
    else
        doDelete(true)
    end
end

function AvatarSwitcher:openDialog()
    self:initialize()
    if g_gui == nil then
        self:warn("[Dialog] g_gui is not available")
        return false
    end

    if self.guiDialog ~= nil then
        return true
    end

    if g_gui.loadProfiles ~= nil then
        g_gui:loadProfiles(self.modDirectory .. "gui/guiProfiles.xml")
    end

    local dlgFrame = AvatarSwitcherDialog.new(g_i18n)
    g_gui:loadGui(self.modDirectory .. "gui/AS_Dialog.xml", "AvatarSwitcherDialog", dlgFrame)
    self.guiDialog = g_gui:showDialog("AvatarSwitcherDialog")

    if self.HUD ~= nil then
        self.HUD.visible = self.guiDialog ~= nil
    end

    return self.guiDialog ~= nil
end

function AvatarSwitcher:closeDialog()
    if self.guiDialog ~= nil and self.guiDialog.target ~= nil and self.guiDialog.target.close ~= nil then
        self.guiDialog.target:close()
    elseif self.guiDialog ~= nil and self.guiDialog.close ~= nil then
        self.guiDialog:close()
    end
    self.guiDialog = nil
    if self.HUD ~= nil then
        self.HUD.visible = false
    end
end
