# FS25 Avatar Switcher

**Avatar Switcher** is a Farming Simulator 25 script mod that lets you save the current player appearance as a reusable preset and switch between saved avatars from an in-game selector.

## Features

- Save the current wardrobe appearance as an avatar preset.
- Give each preset a unique ID, display name and category.
- Select an existing category or create a new category while saving.
- Contextual help explains the save fields with examples.
- Filter saved appearances by category.
- Apply or delete presets through an in-game selector.
- Open Avatar Switcher while on foot or inside a vehicle.
- Save directly from the player wardrobe through the **Save to AvatarSwitcher** control.
- Store presets outside the mod ZIP so they survive mod updates.
- Refresh preset data without restarting the game.
- Provide a public API for integration with other mods, including Helper Profiles.
- English, German and French localisation.

## Compatibility

- Farming Simulator 25
- Version: **1.0.0.0**
- Script mod for PC and Mac
- Single-player only
- Multiplayer is not supported
- No additional mods are required

## Installation

1. Download `FS25_AvatarSwitcher.zip`.
2. Copy the ZIP file into your Farming Simulator 25 mods folder:

   ```text
   Documents/My Games/FarmingSimulator2025/mods
   ```

3. Enable **Avatar Switcher** when loading your save.
4. Press **Ctrl+Alt+A** to open Avatar Switcher. The binding can be changed in the in-game controls menu.

Do not extract the mod ZIP into the mods folder.

## Using Avatar Switcher

### Saving an appearance

1. Open the Farming Simulator wardrobe and configure the player appearance.
2. Select **Save to AvatarSwitcher**.
3. Enter a unique **Preset ID**. This is the internal identifier used by Avatar Switcher and compatible mods; spaces are stored as underscores.
4. Enter an optional **Display Name**. This is the readable name shown in the selector. If left blank, the Preset ID is used.
5. Choose one of the existing categories shown in the list, or enter a value in **New Category** to create and use a new category.
6. Use the contextual Help panel for field explanations and examples, then select **Save**.

### Applying an appearance

1. Press the mapped **Open Avatar Switcher** control (**Ctrl+Alt+A** by default).
2. Select a category.
3. Select a saved appearance.
4. Choose **Apply**.

The selected appearance is written to the player settings and Avatar Switcher attempts to refresh the active player immediately.

### Deleting an appearance

Open the selector, choose the preset and select **Delete**. Deleting a preset does not change the appearance currently in use.

## Preset Storage

Avatar presets are stored at:

```text
Documents/My Games/FarmingSimulator2025/modSettings/FS25_AvatarSwitcher/avatarPresets.xml
```

On first use, Avatar Switcher creates a new empty preset file directly in the `modSettings` folder. Saved presets remain there when the mod ZIP is updated.

Before Avatar Switcher first writes an appearance to `gameSettings.xml`, it creates this backup when one does not already exist:

```text
Documents/My Games/FarmingSimulator2025/gameSettings.avatarSwitcherBackup.xml
```

## Console Commands

The following commands are available when the developer console is enabled:

| Command | Purpose |
|---|---|
| `avatarList [category]` | List saved presets, optionally filtered by category. |
| `avatarUse <presetId>` | Apply a preset. |
| `avatarCurrent` | Show the current player style stored in `gameSettings.xml`. |
| `avatarSaveCurrent <presetId> <display name>` | Save the current player style as a custom preset. |
| `avatarDelete <presetId>` | Delete a preset. |
| `avatarReload` | Reload presets from XML. |
| `avatarRefresh` | Attempt a live refresh of the active player. |
| `avatarHud` | Open or close Avatar Switcher. |
| `avatarProbe` | Print runtime avatar diagnostics. |

Equivalent shortened aliases are available with the `as` prefix, such as `asList`, `asUse`, `asDelete` and `asReload`.

## Integration API

Avatar Switcher exposes these global API tables for other mods:

```lua
AvatarSwitcherAPI
FS25_AvatarSwitcherAPI
```

The API supports availability checks, preset lookup, category filtering, reload requests and conversion of a saved preset into a runtime `PlayerStyle` object.

Useful entry points include:

```lua
AvatarSwitcherAPI.isAvailable()
AvatarSwitcherAPI.getPresets()
AvatarSwitcherAPI.getPresetsByCategory(category)
AvatarSwitcherAPI.getPreset(presetId)
AvatarSwitcherAPI.getPresetLabel(presetId)
AvatarSwitcherAPI.createPlayerStyleFromPresetId(presetId)
AvatarSwitcherAPI.reload()
```

## Localisation

Included languages:

- English
- German
- French

Localisation files are stored in the `l10n` folder. Contributions for additional languages are welcome.

## Known Limitations

- Multiplayer is intentionally disabled and unsupported.
- Live appearance refresh depends on the current player and wardrobe runtime state. When an immediate refresh is not possible, reopening the wardrobe or reloading the save applies the stored appearance.
- Player configuration paths are validated before live refresh so an unknown or unavailable model configuration is not passed to the game loader.
- Preset IDs must be unique.

## Licence and Credits

Created by **SimGamerJen**.

The Farming Simulator name and related assets are trademarks of GIANTS Software. This project is an independent mod and is not affiliated with or endorsed by GIANTS Software.
