# MyanmarForever 1.0.0

- Adds the Skyborne starting experience on Zephras Isle, including the shared story, both faction branches, early class quests, beginner professions and the departure handoffs.
- Includes the Deathknell/Brill starter translations from the previous candidate. All nine playable races now have starter-route translation coverage.
- Fixes the missing Hunter pet-training, Camping, fishing-bait and delivery quests captured during play, plus the missing progress reply for Delicate Instruments.
- Keeps English names recognizable with Myanmar pronunciation, and adds a short Skyborne race introduction alongside the existing beginner term meanings.
- Preserves automatic local quest capture when opening NPC offer, progress and completion dialogue. Use `/reload` or log out to save new captures to disk.
- Uses version **1.0.0**, with no beta or candidate suffix. Rebuilds the bundled font and quest catalog together.

Fully exit WoW and replace the complete `Myanmar_Forever_NorthshireTest` folder in `Interface/AddOns`. Keep that folder name and your existing SavedVariables. Commands: `/mmforever` and `/mmnorth`.

Coverage follows available English evidence; unavailable or unresolved quest states keep the original-language fallback. Version 1 does not mean every quest in WoW Forever is translated. Full native Myanmar proofreading and current live Skyborne/controller testing remain pending.

Source, field-level evidence and validation: https://github.com/sithu90-gif/Myanmar-Forever

Full coverage: **852 quest IDs, 3,983 fields and 2,294 available dialogue states**. All 16 Lua regression groups and font/source checks pass. [Detailed coverage](docs/V1-COVERAGE.md).

---

# v0.6.3-beta-candidate — Undead starter update

Prepared November 5, 2026; candidate only, not published on CurseForge.

- Adds 24 quest records covering the shared Deathknell story, the Brill handoff, early class introductions and supported starter class quests.
- Adds 106 translated fields in the style approved for the two review samples. Keeps English names with Myanmar pronunciation and the existing first-introduction meanings.
- Combined candidate: 688 quest IDs, 3,240 translated fields and 1,879 available dialogue states. Preserves all 664 existing quest translations.
- Leaves 13 unavailable source states absent and holds one additional gender-dependent reply for live confirmation.
- Rebuilds the font and catalog together. Source quantities, placeholders, annotation rules, Unicode round trips, glyph coverage and all 13 Lua regression groups pass.

Read the [route and review notes](docs/UNDEAD-STARTER-REVIEW.md) and [full translations](docs/UNDEAD-STARTER-TRANSLATIONS.html). Full native Myanmar proofreading and current live-client/controller testing remain pending.

---

# v0.6.2-beta-candidate — current public build

Published on [CurseForge](https://www.curseforge.com/wow/addons/myanmar-forever/files/9451929) on November 5, 2026. The GitHub source tree now matches that package.

- 664 quest IDs, 3,134 translated fields, and 1,821 offer/progress/completion states.
- Includes the v0.6.1 source-based translation corrections and the earlier Tauren route expansion.
- Adds 45 concise first-introduction meanings while preserving English identifiers and pronunciation rules.
- Remembers introduced meanings per character. Previews, failed renders, hidden displays, and superseded events do not consume introduction history.
- Preserves quest Unicode drafts and source audits from v0.6.1; v0.6.2 itself is a presentation correction rather than a quest expansion.
- Eleven fields retain the native fallback while source/version questions remain unresolved.

Native Myanmar proofreading and current live-client/controller checks remain pending. See the [packaged release notes](Myanmar_Forever_NorthshireTest/RELEASE_NOTES.md) for the historical v0.6.1 correction details.

## November 5 GitHub sync and coverage audit

This repository update imports the already published v0.6.2 source and audits it against UA_Forever 0.23.0. It does not change the addon runtime, add unreviewed translations, or publish another addon version. See [coverage and priorities](docs/COVERAGE.md).

---

# v0.1.0-beta source note (historical)

This repository snapshot corresponds to the first public CurseForge package named `MyanmarForever_v0.1.0-beta.zip`.

The addon itself still reports its historical internal test identity:

- Folder: `Myanmar_Forever_NorthshireTest`
- In-game title: `Myanmar Forever - Northshire Test`
- Internal TOC version: `0.7.0`
- Historical slash command: `/mmnorth`

Those values are intentionally left unchanged in this snapshot so the published source corresponds to the released package. They should be normalized in a future public release rather than silently rewriting the history of v0.1.0-beta.
