# FS25_AvatarSwitcher v0.1.1-alpha

Console-command driven live avatar preset switcher for Farming Simulator 25.

## Scope

This mod changes the active/manual player avatar style stored in `gameSettings.xml` under `lastPlayerStyle`, and applies that style to the currently controlled local player in-game.

It does **not** alter AI workers, HelperProfiles, helper names, or hired worker assignment.

## Config file

On first load, the mod seeds this file:

```text
Documents/My Games/FarmingSimulator2025/modSettings/FS25_AvatarSwitcher/avatarPresets.xml
```

The preset file is global across all savegames.

## Console commands

Long commands:

```text
avatarList
avatarList <category>
avatarUse <presetId>
avatarCurrent
avatarSaveCurrent <presetId> <display name>
avatarReload
avatarProbe
avatarRefresh
```

Short aliases:

```text
asList
asList <category>
asUse <presetId>
asCurrent
asSaveCurrent <presetId> <display name>
asReload
asProbe
asRefresh
```

## Suggested workflow

1. Create an outfit using the normal FS25 wardrobe/player customisation screen.
2. Exit the customisation screen so FS25 writes it to `gameSettings.xml`.
3. Run:

```text
asSaveCurrent jen_winter Jen - Winter Outfit
```

4. Later, switch to it with:

```text
asUse jen_winter
```

## What v0.1.1-alpha does

- Loads avatar presets from `modSettings/FS25_AvatarSwitcher/avatarPresets.xml`.
- Writes the selected preset to `gameSettings.xml`.
- Updates `g_gameSettings.lastPlayerStyle` in memory.
- Builds a real `PlayerStyle` object from the selected preset.
- Resolves the active local player through `g_currentMission.playerSystem`.
- Applies the style live using `player:setStyleAsync(playerStyle, false, nil, true)` when available.
- Keeps `asProbe` / `avatarProbe` for diagnostics.

## Backup

Before the first write, the mod creates:

```text
Documents/My Games/FarmingSimulator2025/gameSettings.avatarSwitcherBackup.xml
```

## Notes

This is currently tested as a single-player/local-player focused mod. Multiplayer behaviour is not claimed yet.
