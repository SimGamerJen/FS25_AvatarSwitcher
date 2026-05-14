# FS25 AvatarSwitcher v0.6.0-beta

This is the first public beta release candidate for AvatarSwitcher.

## Added

- Added native FS25-style AvatarSwitcher picker.
- Added category list and appearance list with scrolling.
- Added preset detail strip.
- Added Apply and Delete actions in the native picker.
- Added embedded Wardrobe **SAVE** button in the bottom Wardrobe button row.
- Added native XML **Save Avatar** dialog.
- Added Preset ID, Description, and Category fields for saving appearances without the console.
- Added Enter/Accept action hint for saving.
- Added Wardrobe integration diagnostics.

## Changed

- Replaced the old custom raw-drawn selection HUD with a native XML GUI by default.
- Removed the old top-right Wardrobe save overlay in favour of an embedded Wardrobe button.
- Cleaned up the save-dialog layout and button spacing.
- Updated mod version to `0.6.0.0`.

## Fixed

- Fixed duplicated text input in the save dialog.
- Fixed Wardrobe input leaking through while AvatarSwitcher dialogs are active.
- Fixed delete confirmation transparency/click-through issues.
- Fixed Apply/Delete button hints using the same input icon.
- Fixed the Save dialog so typing `x` no longer triggers Save.
- Fixed the Save button styling after removing the old `X` shortcut.

## Known Issues

- Multiplayer has not been formally tested.
- Some GUI/input mods may conflict with embedded Wardrobe buttons.
- Runtime avatar refresh depends on FS25 internals and may vary across patches.

## Suggested Release Asset

Upload the clean mod ZIP as:

```text
FS25_AvatarSwitcher.zip
```
