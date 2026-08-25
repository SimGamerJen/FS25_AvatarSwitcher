-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.0
-- File: AS_GuiLifecycle.lua
-- BuildTag: 20260825.1
-- Centralises custom GUI profile loading so profile names are registered only
-- once per game process, regardless of which Avatar Switcher dialog opens first.

AvatarSwitcher = AvatarSwitcher or {}

-- Do not reset this in deleteMap(). GIANTS keeps GUI profiles registered for the
-- lifetime of the process, so loading another save must not register them again.
AvatarSwitcher.guiProfilesLoaded = AvatarSwitcher.guiProfilesLoaded == true

function AvatarSwitcher:ensureGuiProfilesLoaded()
    if self.guiProfilesLoaded == true then
        return true
    end

    if g_gui == nil or g_gui.loadProfiles == nil then
        if self.warn ~= nil then
            self:warn("[GUI] Cannot load Avatar Switcher GUI profiles: g_gui.loadProfiles unavailable")
        end
        return false
    end

    local filename = self.modDirectory .. "gui/guiProfiles.xml"
    local ok, err = pcall(g_gui.loadProfiles, g_gui, filename)
    if not ok then
        if self.error ~= nil then
            self:error("[GUI] Failed to load GUI profiles: " .. tostring(err))
        else
            print("[FS25_AvatarSwitcher/GUI] Failed to load GUI profiles: " .. tostring(err))
        end
        return false
    end

    self.guiProfilesLoaded = true
    if self.debug ~= nil then
        self:debug("[GUI] Loaded custom GUI profiles once: " .. tostring(filename))
    end
    return true
end

-- AS_Dialog.lua and AS_SaveDialog.lua historically loaded guiProfiles.xml inside
-- their open routines. Replacing the two open routines here keeps their dialog
-- behaviour unchanged while routing profile registration through the shared guard.

function AvatarSwitcher:openDialog()
    self:initialize()
    if g_gui == nil then
        self:warn("[Dialog] g_gui is not available")
        return false
    end

    if self.guiDialog ~= nil then
        return true
    end

    if not self:ensureGuiProfilesLoaded() then
        return false
    end

    local dlgFrame = AvatarSwitcherDialog.new(g_i18n)
    g_gui:loadGui(self.modDirectory .. "gui/AS_Dialog.xml", "AvatarSwitcherDialog", dlgFrame)
    self.guiDialog = g_gui:showDialog("AvatarSwitcherDialog")

    if self.HUD ~= nil then
        self.HUD.visible = self.guiDialog ~= nil
    end

    return self.guiDialog ~= nil
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

    if not self:ensureGuiProfilesLoaded() then
        return false
    end

    local dlgFrame = AvatarSwitcherSaveDialog.new(g_i18n)
    g_gui:loadGui(self.modDirectory .. "gui/AS_SaveDialog.xml", "AvatarSwitcherSaveDialog", dlgFrame)
    self.wardrobeSaveDialog = g_gui:showDialog("AvatarSwitcherSaveDialog")

    return self.wardrobeSaveDialog ~= nil
end
