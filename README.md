# FS25 AvatarSwitcher

AvatarSwitcher is a Farming Simulator 25 utility mod for saving, organising, and applying player avatar appearances.

The v0.6.0 beta release introduces the first complete native in-game workflow: a FS25-style AvatarSwitcher picker, category filtering, preset deletion, an embedded Wardrobe **SAVE** button, and a native XML **Save Avatar** dialog.

> **Status:** Beta / pre-release. Core single-player workflows have been tested, but wider mod compatibility and multiplayer behaviour still need community testing.

## Features

- Save the current Wardrobe appearance directly to AvatarSwitcher.
- Open AvatarSwitcher from the configured input binding.
- Browse saved appearances by category.
- Apply saved appearances to the active local player.
- Delete saved appearances from the AvatarSwitcher picker.
- Stores presets in XML under the user `modSettings` area.
- Includes console commands for diagnostics and fallback control.
- Includes optional integration support for HelperProfiles-style workflows.

## Installation

1. Download `FS25_AvatarSwitcher.zip`.
2. Copy it to your Farming Simulator 25 mods folder.
3. Enable **Avatar Switcher** when loading your savegame.
4. Configure the **Open Avatar Switcher** input binding from the FS25 controls menu if needed.

Typical Windows mods folder:

```text
Documents\My Games\FarmingSimulator2025\mods
```

## Basic Usage

### Save an appearance from the Wardrobe

1. Open the FS25 Wardrobe screen.
2. Use the bottom-row **SAVE** button added by AvatarSwitcher.

<img width="2428" height="322" alt="image" src="https://github.com/user-attachments/assets/29e1458b-2dcc-40dc-b7c6-abfc60f3c2f2" />

3. Enter:
   - **Preset ID** — internal identifier, for example `jen_winter1`.
   - **Description** — display name, for example `Jen - Winter Gear`.
   - **Category** — grouping label, for example `witcombe`, `judithplains`, or `custom`.
4. Click **SAVE** or press the Enter/Accept action.

<img width="1504" height="1578" alt="wardrobe_save_screen" src="https://github.com/user-attachments/assets/d4cb985d-c765-4f43-b225-cad60bdc8ad3" />

### Apply an appearance

1. Use the configured **Open Avatar Switcher** input binding.
2. Select a category on the left.
3. Select an appearance on the right.
4. Click **APPLY**.

<img width="2317" height="1262" alt="avatar_switcher_screen" src="https://github.com/user-attachments/assets/b02fa1b9-9bbc-4e85-82d1-b72dac9538b4" />

<img width="1613" height="1175" alt="avatar_switcher_appearance_changes_without_wardrobe" src="https://github.com/user-attachments/assets/c47e9171-8955-41ac-a75d-a6f5cb45ab58" />

### Delete an appearance

1. Open AvatarSwitcher.
2. Select the saved appearance.
3. Click **DELETE**.
4. Confirm the delete prompt.

## Suggested Screenshot Locations

Screenshots are not bundled with the mod ZIP, but the README is prepared for a `docs/images` folder in the GitHub repository.

## Console Commands

AvatarSwitcher includes console commands for testing, diagnostics, and fallback control.

| Command | Description |
|---|---|
| `avatarList [category]` | Lists available presets. Optionally filter by category. |
| `asList [category]` | Alias for `avatarList`. |
| `avatarUse <presetId>` | Applies the specified preset by ID. |
| `asUse <presetId>` | Alias for `avatarUse`. |
| `avatarCurrent` | Prints the current `gameSettings.xml` `lastPlayerStyle` data detected by AvatarSwitcher. |
| `asCurrent` | Alias for `avatarCurrent`. |
| `avatarSaveCurrent <presetId> <display name>` | Saves the current `lastPlayerStyle` as a preset from the console. The Wardrobe SAVE dialog is preferred for normal use. |
| `asSaveCurrent <presetId> <display name>` | Alias for `avatarSaveCurrent`. |
| `avatarDelete <presetId>` | Deletes a saved preset by ID. |
| `asDelete <presetId>` | Alias for `avatarDelete`. |
| `avatarReload` | Reloads AvatarSwitcher presets from XML. |
| `asReload` | Alias for `avatarReload`. |
| `avatarProbe` | Probes runtime player/avatar objects and prints diagnostics. Useful when appearance refresh does not behave as expected. |
| `asProbe` | Alias for `avatarProbe`. |
| `avatarRefresh` | Attempts to refresh the active player from the current `gameSettings.xml` style. |
| `asRefresh` | Alias for `avatarRefresh`. |
| `avatarHud` | Opens/toggles the AvatarSwitcher interface. Retained for compatibility with the earlier HUD naming. |
| `asHud` | Alias for `avatarHud`. |
| `avatarHudNext` | Moves the AvatarSwitcher selection to the next preset. |
| `asHudNext` | Alias for `avatarHudNext`. |
| `avatarHudPrev` | Moves the AvatarSwitcher selection to the previous preset. |
| `asHudPrev` | Alias for `avatarHudPrev`. |
| `avatarHudApply` | Applies the currently selected AvatarSwitcher preset. |
| `asHudApply` | Alias for `avatarHudApply`. |
| `avatarHudDebug` | Prints AvatarSwitcher interface diagnostics. |
| `asHudDebug` | Alias for `avatarHudDebug`. |
| `avatarInputDebug` | Prints input/action-event diagnostics. Use this if the AvatarSwitcher input binding does not work. |
| `asInputDebug` | Alias for `avatarInputDebug`. |
| `avatarMenuDebug` | Prints legacy in-game menu diagnostics. Mostly retained for compatibility after moving to the native dialog workflow. |
| `asMenuDebug` | Alias for `avatarMenuDebug`. |
| `avatarWardrobeDebug` | Prints Wardrobe integration diagnostics, including embedded SAVE button state and XML save-dialog availability. |
| `asWardrobeDebug` | Alias for `avatarWardrobeDebug`. |

### Recommended debug output for bug reports

- Input binding does not open AvatarSwitcher: run `asInputDebug`.
- Wardrobe SAVE button does not appear: run `asWardrobeDebug`.
- Appearance does not apply or refresh correctly: run `asProbe`.
- Presets are missing or not loading: run `avatarList` and `asReload`.

## Known Limitations

- Multiplayer has not been formally validated.
- Some third-party GUI/input mods may conflict with embedded buttons or input actions.
- Runtime character refresh depends on FS25 player/wardrobe internals and may vary by game patch.
- The older raw HUD code remains as fallback/compatibility code, but the default interface is now native XML GUI.

## Version

```text
v0.6.0-beta
```

Recommended GitHub tag:

```text
v0.6.0-beta
```
