# FS25 AvatarSwitcher

Save and switch between player appearances in Farming Simulator 25.

## Features

- Save the current wardrobe appearance to AvatarSwitcher.
- Switch saved appearances from the AvatarSwitcher interface.
- Organise appearances by category.
- Delete saved appearances from the selection interface.
- Optional HelperProfiles integration for assigning appearances to AI/helper profiles.
- Console diagnostics for troubleshooting.

## Usage

1. Open the in-game wardrobe.
2. Click "Save to AvatarSwitcher".
3. Enter an ID, description, and category.
4. Open AvatarSwitcher using the configured input binding.
5. Select a category and appearance.
6. Apply or delete appearances as needed.

## Known limitations

- Runtime character refresh depends on Farming Simulator 25's player/wardrobe systems.
- Some mod conflicts may affect GUI/input behaviour.
- Multiplayer is not yet formally tested.

## Known Issues

- Multiplayer support has not been fully validated.
- Some third-party GUI/input mods may conflict with AvatarSwitcher overlays.
- Wardrobe integration has been tested against FS25 1.18.0.0.
- If the Save to AvatarSwitcher button does not appear, run `asWardrobeDebug` from the console and include the output in a bug report.

## Console Commands

AvatarSwitcher includes several console commands for testing, diagnostics, and fallback control.

| Command | Description |
|---|---|
| `avatarList` | Lists available AvatarSwitcher presets in the console. Useful for checking whether `avatarPresets.xml` has loaded correctly. |
| `asList` | Short alias for `avatarList`. |
| `avatarUse <presetId>` | Applies the specified preset by ID. Useful as a fallback if the GUI is unavailable. |
| `asUse <presetId>` | Short alias for `avatarUse <presetId>`. |
| `avatarDelete <presetId>` | Deletes a saved preset by ID from AvatarSwitcher. Useful if a preset cannot be deleted through the GUI. |
| `asDelete <presetId>` | Short alias for `avatarDelete <presetId>`. |
| `avatarInputDebug` | Prints input-binding and action-event registration diagnostics. Use this if the AvatarSwitcher open key/button does not work. |
| `asInputDebug` | Short alias for `avatarInputDebug`. |
| `avatarWardrobeDebug` | Prints wardrobe integration diagnostics, including whether `WardrobeScreen` hooks are active and whether the save modal/input lock is installed. |
| `asWardrobeDebug` | Short alias for `avatarWardrobeDebug`. |
| `avatarMenuDebug` | Prints legacy menu-entry diagnostics. Mainly retained for compatibility/debugging after the old top-right menu button was retired. |
| `asMenuDebug` | Short alias for `avatarMenuDebug`. |
| `avatarProbe` | Attempts to probe the current player/avatar runtime state and reports what AvatarSwitcher can detect. Useful when appearance application does not appear to refresh correctly. |
| `asProbe` | Short alias for `avatarProbe`. |

### Recommended debug commands for bug reports

If reporting an issue, please include the relevant console output:

- If the open key/button does not work: `asInputDebug`
- If the wardrobe save button does not appear: `asWardrobeDebug`
- If a saved appearance does not apply correctly: `asProbe`
- If presets are missing or not loading: `avatarList`
