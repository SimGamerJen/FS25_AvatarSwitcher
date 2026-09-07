# Changelog

## 1.0.0.0 — 7 September 2026

Initial ModHub release, approved by GIANTS Software.

### Features

- Save the current wardrobe appearance as a reusable avatar preset.
- Assign each preset a unique ID, display name and category.
- Select an existing category or create a new category while saving.
- Contextual help for Preset ID, Display Name and Category fields.
- Browse, filter, apply and delete saved appearances from the in-game Avatar Switcher menu.
- Open Avatar Switcher while on foot or inside a vehicle.
- Save directly from the Farming Simulator wardrobe.
- Persistent preset storage in `modSettings/FS25_AvatarSwitcher`.
- Public integration API for compatible mods.
- English, German and French localisation.

### Final GIANTS testing fixes

- Changed the default Avatar Switcher control to **Alt+Shift+A** to avoid keyboard-layout-dependent punctuation bindings and conflicts with FS25/debug function keys.
- Added one-time GUI profile loading so `guiProfiles.xml` is not registered repeatedly during a game process.
- Fixed duplicate GUI profile DevErrors affecting profiles including `asButtonSaveEnter`, `asMetaText`, `asInputFieldButton` and `asButtonDelete`.
- Corrected the Wardrobe **Save Avatar** dialog layout so field headings and validation text remain inside the native dialog.
- Updated the English, German and French ModHub descriptions to the final approved usage text.

### Compatibility

- Farming Simulator 25
- PC/Mac
- Single-player only
- Multiplayer is intentionally disabled and unsupported in 1.0.0.0.

### Existing installations

FS25 preserves user-defined control assignments in `inputBinding.xml`. Users who previously mapped Avatar Switcher to another key may therefore retain that personal binding after updating to the ModHub release.
