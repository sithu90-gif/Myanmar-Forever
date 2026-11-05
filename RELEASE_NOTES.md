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
