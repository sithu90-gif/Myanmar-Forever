# Myanmar Forever

Myanmar (Burmese) quest and story translation addon for **World of Warcraft: Forever**.

Myanmar Forever adds a dedicated Myanmar translation window while keeping the original English quest interface available. The project focuses first on quest story, objectives, dialogue, important character names, ranks, and titles.

## Status

**Early public beta.** Translation coverage is incomplete and will expand over time.

## Current public release

**CurseForge release:** `v0.6.2-beta-candidate`, published November 5, 2026.

- [Download v0.6.2](https://www.curseforge.com/wow/addons/myanmar-forever/files/9451929)
- [Current coverage and next translation priorities](docs/COVERAGE.md)
- [Release notes](RELEASE_NOTES.md)

The current source tree matches the published v0.6.2 package. It retains the installation folder `Myanmar_Forever_NorthshireTest`, reports the in-game title `MyanmarForever`, and supports `/mmforever` and `/mmnorth`. The old v0.1.0 ZIP is retained as a historical artifact; its internal `0.7.0` test identity does not describe the current build.

Native Myanmar proofreading and current live-client/controller verification remain pending. Automated checks do not certify translation quality or live quest availability.

## Coverage

The packaged build contains **664 quest IDs**, **3,134 translated fields**, and **1,821 available offer/progress/completion states**. Coverage focuses on Human, Dwarf/Gnome, Night Elf, Orc/Troll, and Tauren routes. It is incomplete; a listed quest does not imply that every dialogue state is available.

The November 5 audit compares this build with [UA_Forever 0.23.0](https://github.com/sysrover/UA_Forever/releases/tag/0.23.0). Our 664 IDs are **10.69% of its 6,214 quest IDs**. This is a comparison-corpus percentage, not a measured percentage of all live game quests. The report includes all 5,550 upstream IDs missing from our catalog and separates deliberate source holds from missing evidence.

## Current features

- Myanmar quest and story translations for supported quests
- Dedicated Myanmar translation window
- Draggable and resizable window
- Adjustable Myanmar text size
- Bundled Myanmar-compatible shaped font
- Original English names retained where useful
- Myanmar explanation/pronunciation for selected names, ranks, and titles
- English fallback when no Myanmar translation is available
- 45 concise first-introduction term meanings, remembered per character; previews do not consume introduction history
- Six optional key bindings and `/mmforever` / `/mmnorth` commands

## Translation approach

English quest references are treated as the primary semantic source. UA_Forever is used as a secondary technical / coverage reference. The project does not claim that UA_Forever's Ukrainian wording is the source of the Myanmar translation.

## Installation

For normal players, install **Myanmar Forever** from CurseForge.

For manual installation of this release:

1. Fully exit World of Warcraft and back up the current addon folder and SavedVariables.
2. Replace the complete `Myanmar_Forever_NorthshireTest` folder inside the game's `Interface/AddOns` folder. Keep the exact folder name.
3. Start the game.
4. Enable **MyanmarForever** in the AddOns list.

See `Myanmar_Forever_NorthshireTest/INSTALL.txt` for the release-specific notes and commands.

Do not mix `Catalogs/Northshire.lua` and `fonts/NorthshireShaped.ttf` from different builds. A reload alone may retain a cached font. See the [term explanation guide](Myanmar_Forever_NorthshireTest/TERM-EXPLANATION-GUIDE.txt).

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

- `Myanmar_Forever_NorthshireTest/` — complete addon/source tree from the published v0.6.2 package, including historical build/review material
- `Myanmar_Forever_NorthshireTest/Catalogs/` — generated runtime quest catalog
- `Myanmar_Forever_NorthshireTest/BuildSource/` — editable/reference build data and validation material
- `Myanmar_Forever_NorthshireTest/fonts/` — bundled font plus its license/notice
- `LICENSE` — project GPLv3 license
- `CREDITS.md` — acknowledgements and attribution
- `docs/COVERAGE.md` — current inventory, limitations, and priorities
- `docs/coverage/` — audit JSON and complete missing-ID CSV
- `tools/audit_coverage.py` — reproducible comparison against supplied UA catalogs

## Development and validation

Use Python 3.13 and the pinned dependencies:

```powershell
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements-dev.txt
.venv\Scripts\python -m unittest discover -s tools -p "test_*.py" -v
.venv\Scripts\python Myanmar_Forever_NorthshireTest/BuildSource/test.py
```

The existing addon test runner writes `BuildSource/test-results.json`. The committed copy is the original released report; fresh execution evidence is recorded separately under `docs/validation/`.

Obtain the two upstream quest catalogs at the commits pinned in [the audit JSON](docs/coverage/2026-11-05.json), then reproduce the comparison:

```powershell
.venv\Scripts\python tools/audit_coverage.py --upstream path/to/0.23.0/quests.lua --previous path/to/0.20.5/quests.lua
```

Edit Unicode prose in `BuildSource/drafts.json` and first-introduction meanings in `BuildSource/term-glossary-v0.6.2.json`. Build the font and catalog together with `BuildSource/build.py`. Historical notes inside the source tree describe their own build dates.

## License

Myanmar Forever source is distributed under the **GNU General Public License v3.0**. See `LICENSE`.

The bundled Myanmar font is separately licensed under the **SIL Open Font License 1.1**. See `Myanmar_Forever_NorthshireTest/fonts/OFL.txt` and `NOTICE.txt`.

## Disclaimer

Myanmar Forever is an unofficial community-created addon. It is not affiliated with, endorsed by, or sponsored by Blizzard Entertainment. World of Warcraft, Warcraft, and related names and trademarks belong to their respective owners.
