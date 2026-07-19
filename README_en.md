# Kill Icon

A DMF mod for *Warhammer 40,000: Darktide* that displays kill icons in the upper area of the screen upon enemy kills, distinguishing between normal kills and headshot kills.

## Credits

This mod references the design of [m4a1deathDawn/Hit_Kill_Sounds](https://github.com/m4a1deathDawn/Hit_Kill_Sounds), streamlined on top of it:

- Only the **kill icon display** feature is retained; other modules such as kill sounds have been removed.
- **No longer loads external PNG image files via a local HTTP server.** Instead, it directly references the game's built-in UI material paths (`content/ui/materials/hud/interactions/icons/enemy` and `enemy_priority`; the headshot ring effect uses `scanner_drill_wireframe_small`).

Benefits of this approach: no need to run a local server, no image assets to package, avoidance of the performance overhead and security risks of external HTTP requests, and visual consistency with the game's native UI style.

## Features

- Different icons for normal and headshot kills, with an expanding ring effect on headshots.
- Full enter / display / leave animations, with a multi-slot queue supporting consecutive kills.
- Highly configurable (see the settings below).
- Supports multiple languages.

## Installation

Requires the [Darktide Mod Framework](https://www.nexusmods.com/warhammer40kdarktide/mods/8).

## Settings

### General Settings

| Setting | Description | Default |
| --- | --- | --- |
| Master Switch | Master toggle for the mod | On |
| Enable Companion Kill Icon | Show icons for kills by the Adamant dog | On |

### Icon Settings

| Setting | Description | Default |
| --- | --- | --- |
| Enable Kill Icon | Toggle for kill icons | On |
| Kill Icon Target | All Enemies / Elite Only / Special Only / Elite, Special and Boss | All Enemies |
| Show Kill Icon on DoT Kills | Whether DoT kills (burning, bleeding, poison, etc.) show icons | On |
| Kill Icon Transparency | 0–100 | 80 |
| Normal Icon Color - R/G/B | Color for normal kill icons | 216 / 229 / 207 |
| Headshot Icon Color - R/G/B | Color for headshot kill icons | 255 / 156 / 6 |
| Icon Vertical Position | 0–100 | 55 |
| Icon Horizontal Position | 0–100 | 50 |
| Icon Size | 5–20 | 8 |
| Icon Display Duration | 1.0s / 1.5s / 2.0s / 2.5s / 3.0s | 2.0s |

## Implementation Notes

- **Event hook**: Captures kill events by hooking `AttackReportManager.add_attack_result`. A kill is identified by `attack_result == died`, and a headshot by `hit_weakspot`.
- **DoT detection**: Primarily based on `damage_profile.damage_type`, with a fallback keyword match on `damage_profile.name` (bleed / burn / fire / toxin / corruption / grimoire / electrocution / warpfire / chain_lightning).
- **Companion detection**: Only recognizes `attack_types.companion_dog` (the Adamant dog).
- **HUD registration**: Injects the custom HUD element into the game HUD by hooking `UIManager.load_hud_packages` and `UIHud.init`. The `package = "packages/ui/views/scanner_display_view/scanner_display_view"` is declared during `load_hud_packages` to ensure the headshot ring material is loaded during missions (the game only loads this package on demand when the scanner is opened).
- **Hub suppression**: Icons are not drawn while in the hub.

## File Structure

```
Kill_Icon/
├── Kill_Icon.mod                              # Mod entry definition
└── scripts/mods/Kill_Icon/
    ├── Kill_Icon.lua                          # Main script: HUD element registration and injection
    ├── Kill_Icon_data.lua                     # DMF settings definitions
    ├── Kill_Icon_events.lua                   # Kill event hooks and target filtering
    ├── Kill_Icon_hud.lua                      # HUD element class, slot queue, and rendering logic
    └── Kill_Icon_localization.lua             # English and Chinese localization
```

## License

This mod is intended for learning and communication only. The rights related to the original Hit_Kill_Sounds belong to its original author.
