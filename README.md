# Myanmar Forever

Myanmar (Burmese) quest and story translation addon for **World of Warcraft: Forever**.

Myanmar Forever adds a dedicated Myanmar translation window while keeping the original English quest interface available. The project focuses first on quest story, objectives, dialogue, important character names, ranks, and titles.

## Status

**Early public beta.** Translation coverage is incomplete and will expand over time.

## Current public release

**CurseForge release:** `v0.1.0-beta`

The current public ZIP grew out of an internal Northshire test build, so its addon folder, `.toc` title, slash command, and internal version still use the historical `Myanmar_Forever_NorthshireTest` / `0.7.0` naming. This is intentionally preserved here so the repository matches the released source. The public-facing naming will be normalized in a later release.

## Current features

- Myanmar quest and story translations for supported quests
- Dedicated Myanmar translation window
- Draggable and resizable window
- Adjustable Myanmar text size
- Bundled Myanmar-compatible shaped font
- Original English names retained where useful
- Myanmar explanation/pronunciation for selected names, ranks, and titles
- English fallback when no Myanmar translation is available

## Translation approach

English quest references are treated as the primary semantic source. UA_Forever is used as a secondary technical / coverage reference. The project does not claim that UA_Forever's Ukrainian wording is the source of the Myanmar translation.

## Installation

For normal players, install **Myanmar Forever** from CurseForge.

For manual installation of this release:

1. Fully exit World of Warcraft.
2. Copy `Myanmar_Forever_NorthshireTest` into the World of Warcraft: Forever AddOns folder.
3. Start the game.
4. Enable **Myanmar Forever - Northshire Test** in the AddOns list.

See `Myanmar_Forever_NorthshireTest/INSTALL.txt` for the release-specific notes and commands.

## Feedback

Please use GitHub Issues to report:

- untranslated quests
- incorrect or unnatural Myanmar wording
- font/rendering problems
- text clipping
- UI problems
- incorrect names, ranks, or titles

A screenshot plus the English quest name or Quest ID is especially useful.

## Source layout

- `Myanmar_Forever_NorthshireTest/` — exact addon/source tree from the v0.1.0-beta CurseForge package
- `Myanmar_Forever_NorthshireTest/Catalogs/` — generated runtime quest catalog
- `Myanmar_Forever_NorthshireTest/BuildSource/` — editable/reference build data and validation material
- `Myanmar_Forever_NorthshireTest/fonts/` — bundled font plus its license/notice
- `LICENSE` — project GPLv3 license
- `CREDITS.md` — acknowledgements and attribution

## License

Myanmar Forever source is distributed under the **GNU General Public License v3.0**. See `LICENSE`.

The bundled Myanmar font is separately licensed under the **SIL Open Font License 1.1**. See `Myanmar_Forever_NorthshireTest/fonts/OFL.txt` and `NOTICE.txt`.

## Disclaimer

Myanmar Forever is an unofficial community-created addon. It is not affiliated with, endorsed by, or sponsored by Blizzard Entertainment. World of Warcraft, Warcraft, and related names and trademarks belong to their respective owners.
