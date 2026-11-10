# Myanmar Forever

Myanmar quest and story translations for **World of Warcraft: Forever**.

## Version 1.2.1

This batch adds 12 quests across the Silverpine Deathstalker route, Teldrassil's Lost Runner chain and the opening steps of Durotar's Threat from Below. The catalog contains **986 quest IDs and 4,613 translated fields**. [Download MyanmarForever 1.2.1](dist/MyanmarForever_v1.2.1.zip) · [Release notes](releases/1.2.1-NOTES.md) · [Build validation](docs/validation/v1.2.1-2026-11-10.json)

## Version 1.2.0

This batch adds 22 quests across Westfall, the Deadmines, Dun Morogh, Loch Modan, Teldrassil, Durotar, Mulgore and Silverpine. It also adds a verified Westfall progress reply. The catalog now contains **974 quest IDs and 4,557 translated fields**. [Download MyanmarForever 1.2.0](dist/MyanmarForever_v1.2.0.zip) · [Release notes](releases/1.2.0-NOTES.md) · [Build validation](docs/validation/v1.2.0-2026-11-10.json)

## Version 1.1.1

Version 1.1.1 completes the Westfall Toxic Soil storyline through the Deadmines and corrects A Dynamite Plan to require 10 Rough Dynamite. It contains **952 quest IDs and 4,449 translated fields**. [Download MyanmarForever 1.1.1](dist/MyanmarForever_v1.1.1.zip) · [Release notes](releases/1.1.1-NOTES.md) · [Build validation](docs/validation/v1.1.1-2026-11-10.json)

## Version 1.1.0

[Download MyanmarForever 1.1.0](dist/MyanmarForever_v1.1.0.zip)

This release extends the Undead route through Brill and Tirisfal Glades, including Forever-specific quests, supported early class chains and local Camping/profession introductions. It preserves the nine-race starter coverage from version 1.0.0, including both Skyborne branches. Coverage follows available English evidence; it does not mean every quest or every state is translated.

Version 1.1.0 contains **946 quest IDs and 4,423 translated fields**. The Undead packs contain **118 quest records** across Deathknell, Brill and Tirisfal, reaching approximately levels 1–13.

- [Version 1.1 changelog](releases/1.1.0-NOTES.md)
- [Undead coverage, sources and known gaps](docs/V1.1-COVERAGE.md)
- [New Undead Myanmar/English review](docs/UNDEAD-TIRISFAL-TRANSLATIONS.html)
- [Build and validation results](docs/validation/v1.1.0-2026-11-08.json)
- [Previous 1.0.0 coverage](docs/V1-COVERAGE.md) and [translation review](docs/V1-TRANSLATION-REVIEW.html)

Version **1.1.0** has no beta or candidate suffix. Full native Myanmar proofreading and current live-client/controller verification remain pending; automated checks establish source integrity and runtime behavior, not native fluency.

## Starter routes

| Area | Races |
| --- | --- |
| Northshire | Human |
| Coldridge Valley | Dwarf, Gnome |
| Shadowglen | Night Elf |
| Valley of Trials | Orc, Troll |
| Red Cloud Mesa | Tauren |
| Deathknell → Brill / Tirisfal Glades | Undead |
| Zephras Isle, both faction branches | Skyborne |

Existing translations also cover parts of the follow-on zones. The Undead route now reaches local level-13 finales, with immediate capital and Silverpine delivery handoffs; Silverpine questing is a later update. Skyborne coverage includes supported class introductions, beginner profession/camping quests, island departure handoffs and immediate capital introductions.

## Install

1. Fully exit WoW and back up your current addon and SavedVariables.
2. Extract the ZIP and replace the complete `Myanmar_Forever_NorthshireTest` folder in the game's `Interface/AddOns` folder. Keep that folder name.
3. Start WoW and enable **MyanmarForever**.

Keep the rebuilt font and catalog together. Commands: `/mmforever` and `/mmnorth`. Existing settings, captures and per-character term history use the same SavedVariables names.

## Untranslated quest capture

The addon automatically records NPC quest offer, progress and completion text locally, including unknown quests and missing states. Use `/reload` or log out to save it to disk. With a dialogue open, `/mmforever capture` can also capture it manually.

Capture does not translate or upload quests automatically. SavedVariables can contain substituted player names; source evidence is sanitized before sharing or adding it to this repository.

## Features

- Dedicated Myanmar reader with the original English quest interface available
- Adjustable text size, scrolling, movable/resizable window and optional key bindings
- English identities retained with Myanmar pronunciation
- 46 short beginner term meanings, including Skyborne, introduced once per character
- Matching bundled font and catalog generated from editable Unicode drafts
- Strict quest ID/title checks with English fallback and capture for unsupported states

## Build from source

Install the pinned dependencies in `requirements-dev.txt`, then run:

```powershell
python tools/build_release.py --manifest releases/1.2.1.json --output ../outputs/MyanmarForever-1.2.1
```

Choose a new output directory. The command composes the versioned translation packs, checks source/review hashes, rebuilds the font and catalog, and runs Lua state-routing, capture and identity tests. It creates the install ZIP and a validation report.

`releases/1.2.1.json` lists the exact packs. Build that manifest or install its ZIP. The directory `Myanmar_Forever_NorthshireTest/` is the byte-preserved **0.6.2 release snapshot** used as the build base. New source, English evidence and per-field reviews are under `translations/`.

The [earlier CurseForge 0.6.2 package](https://www.curseforge.com/wow/addons/myanmar-forever/files/9451929) and [0.6.3 candidate notes](docs/UNDEAD-STARTER-REVIEW.md) remain available as history. The 0.1 ZIP is also historical; its internal test version does not describe version 1.

## Translation and feedback

English quest text controls meaning. UA_Forever is a secondary quest identity/state reference; its Ukrainian wording is not the source of Myanmar prose. Missing English states and unresolved branches remain explicit.

Please report quest ID/title, the dialogue state and the original English when requesting a correction. Review captures for personal information before sharing. Screenshots help with font and layout issues.

The project uses GPLv3; see `LICENSE` and the packaged credits and font licences.
