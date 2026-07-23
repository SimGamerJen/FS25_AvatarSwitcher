-- FS25_AvatarSwitcher
-- ModVersion: 1.0.0.1
-- File: AS_MenuEntry.lua
-- BuildTag: 20260513.1
-- Compatibility shim. The old top-right in-game pause-menu button has been retired.
-- AvatarSwitcher is now opened through the ASZ_HUD input action/console command, matching
-- the HelperProfiles-style player/vehicle input registration approach.

AvatarSwitcher = AvatarSwitcher or {}

AvatarSwitcher.MenuEntry = AvatarSwitcher.MenuEntry or {
    enabled = false,
    visible = false,
    hooksInstalled = false,
    retired = true,
    label = AvatarSwitcher:getText("as_title", "Avatar Switcher")
}

function AvatarSwitcher:installMenuEntryHooks()
    self.MenuEntry = self.MenuEntry or {}
    self.MenuEntry.enabled = false
    self.MenuEntry.visible = false
    self.MenuEntry.hooksInstalled = false
    return false
end

function AvatarSwitcher:drawMenuOverlay()
    -- Retired. HUD drawing is handled by the normal mod draw lifecycle.
end

function AvatarSwitcher:drawMenuEntry()
    if self.MenuEntry ~= nil then
        self.MenuEntry.visible = false
    end
end

function AvatarSwitcher:handleMenuEntryMouse(posX, posY, isDown, isUp, button)
    return false
end

function AvatarSwitcher:debugMenuEntryStatus()
    self:initialize()
    self:log("[MenuEntryDebug] Version: " .. tostring(self.VERSION))
    self:log("[MenuEntryDebug] retired: true")
    self:log("[MenuEntryDebug] top-right pause-menu button enabled: false")
    self:log("[MenuEntryDebug] open AvatarSwitcher with ASZ_HUD / asHud / avatarHud")
end
