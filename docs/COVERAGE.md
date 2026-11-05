# Coverage audit — November 5, 2026

Baseline: **MyanmarForever 0.6.2-beta-candidate**, [published package](https://www.curseforge.com/wow/addons/myanmar-forever/files/9451929).

Comparison: [UA_Forever 0.23.0](https://github.com/sysrover/UA_Forever/releases/tag/0.23.0), released November 5, 2026, targeting source build **1.60.1.70790**, commit `e7087161130b9fe48efbe7b7b0a548d184af329d`.

## How much is translated?

**Development update:** the [v0.6.3 Undead starter candidate](UNDEAD-STARTER-REVIEW.md) adds 24 quest records and 106 fields. Its totals are **688 IDs, 3,240 fields and 1,879 available dialogue states**. All 688 IDs occur in the pinned UA corpus: **11.07%**, with **5,526 IDs remaining outside the candidate**. This remains a comparison-corpus percentage. The tables below describe the published v0.6.2 baseline, which is preserved. See the [candidate inventory](coverage/undead-candidate-2026-11-05.json).

| Measure | Packaged Myanmar coverage |
| --- | ---: |
| Quest IDs | 664 |
| Titles | 664 |
| Offer/detail fields | 649 |
| Objective fields | 649 |
| Progress fields | 530 |
| Completion fields | 642 |
| Total translated fields | 3,134 |
| Available offer/progress/completion states | 1,821 |
| Absent or held offer/progress/completion states | 171 |

Across all five text fields there are 175 absent English-reference fields and 11 explicitly held fields. Absence is not automatically a translation defect: some quests have no progress text or only a completion state. New live English captures are needed to distinguish genuine omissions from states that do not exist.

All quest prose remains an assisted draft pending native Myanmar approval. Existing automated checks cover structure, state routing, substitutions, term introductions, glyph coverage, and font/catalog consistency. They do not establish live quest eligibility or translation fluency.

## Where is our current coverage?

These are counts of packaged records assigned to each worklist region, not claims that a whole zone, race, level range, or class chain is complete.

| Route grouping | Included regions and record counts | Total |
| --- | --- | ---: |
| Human routes | Northshire 37; Elwynn Forest 45; camping records 4; Westfall 44; Redridge Mountains 40; Duskwood 77; captured follow-up 1 | 248 |
| Dwarf/Gnome routes | Coldridge Valley 12; Coldridge class introductions 9; Dun Morogh 44; Loch Modan 39 | 104 |
| Night Elf routes | Shadowglen 14; class introductions 5; Teldrassil 33; Darkshore 69 | 121 |
| Durotar/Barrens routes | Valley of Trials 13; Durotar 33; Orc/Troll class introductions 11; The Barrens 80 | 137 |
| Tauren core routes | Red Cloud Mesa 16; Mulgore 37; Thunder Bluff 1 | 54 |
| **Total** | Barrens quests may be relevant to multiple races; records are counted once | **664** |

## How does UA_Forever compare?

UA 0.23.0 contains **6,214 unique quest IDs** in its three quest tables. Our 664 IDs all occur in that catalog: **10.69% overlap**, with **5,550 IDs not in our Myanmar build**.

This denominator is UA's packaged comparison corpus. It is not an independently verified inventory of every live Forever quest. It includes quests with incomplete dialogue fields, so neither 6,214 nor 664 means that every associated state is translated or available live.

| UA faction table | UA entries | Myanmar IDs in that table |
| --- | ---: | ---: |
| Alliance | 1,373 | 362 |
| Horde | 1,349 | 164 |
| Both | 3,492 | 138 |

All 664 English identifiers match: 655 exactly, 6 after case normalization, and 3 through documented aliases. No new title mismatch was found.

### What changed since our old UA 0.20.5 audit?

The [pinned comparison](https://github.com/sysrover/UA_Forever/compare/332e9b866f55cd56afb658cc7f9202dc08b15b88...e7087161130b9fe48efbe7b7b0a548d184af329d) shows:

- **No quest IDs added or removed.**
- Quest **181, Look to the Stars**: English title capitalization changed from `Look To The Stars`; our case-normalized match handles it.
- Quest **94374, Call of Earth**: Ukrainian completion wording changed. That quest is not in our Myanmar build; English evidence is still needed before translating it.
- Other release changes concern launch-client data, item/spell/aura text, interface and zone names, combat-time quest-tracker restoration, and tooltip handling. They do not imply equivalent Myanmar feature coverage.

The measured delta above compares the five quest text fields and the English identifier. Task-object translations and other addon systems are outside that specific delta.

## What should receive the next translation work?

### 1. Fill the missing Undead starting route

The published baseline has no dedicated **Deathknell / Tirisfal Glades / Silverpine Forest** route. The v0.6.3 candidate now covers the shared Deathknell story, the Brill handoff and supported starter class introductions. The next coherent continuation is Brill and the rest of Tirisfal, followed by Silverpine, after reviewing this candidate in the current client.

The original audit identified these untranslated candidates; all except A Putrid Task are now included in the starter candidate:

| Quest ID | English title |
| --- | --- |
| 363 | Rude Awakening |
| 364 | The Mindless Ones |
| 3901 | Rattling the Rattlecages |
| 376 | The Damned |
| 380 | Night Web's Hollow |
| 381 | The Scarlet Crusade |
| 404 | A Putrid Task |

These are an initial candidate set, not an exhaustive or live-verified starting order. Fetch current English offer/objective/progress/completion text, check prerequisites and race/class variants, translate one coherent chain, and rebuild the font/catalog together. UA remains secondary evidence.

### 2. Close small gaps in routes already shipped

- Investigate **98322, Secure the Mountain: progress**. UA has a progress field, while our saved English reference does not. This is a source-capture task before it is a translation task.
- Revisit the **six previously discovered, unintegrated states**: progress and completion for **97977, 99051, and 99052**. They require separate source/version and live confirmation.
- Finish the **eight recorded onward gaps**: **95495** The Hermit Tanner; **95621** Trouble in the Valley; **95508** Unwelcome Guests; **98340 / 98405 / 98342** The Great Cat Spirit; **98739** Blessings of the Great Cat Spirit; **98362** To Thunder Bluff. Their inventory categories are Barrens and Druid; exact live branches remain unverified.

### 3. Resolve deliberately held translations and review existing wording

The 11 held fields belong to quests **98021, 95213, 3118, 842, 3083, 745, 98435, 99108, and 98387**. They involve player/race/name branches, gender variants, conflicting objectives, or unresolved source versions. In particular, **98387 Blackrock Blockade** has conflicting item/count requirements. Do not enable a guessed translation.

Compare actual live English text and placeholders, then obtain native Myanmar review for changed prose, pronunciation, and the 45 term meanings. Release-client verification matters now that Forever has launched; older beta evidence alone does not establish current behavior.

### 4. Expand coherent later-zone routes

After starter parity and nearby gaps, prioritize routes beyond the current zone set: **Wetlands, Ashenvale, Stonetalon Mountains, Hillsbrad Foothills, and Thousand Needles**, followed by later leveling/dungeon/class/profession chains. The missing-ID CSV is the backlog, not a statement that every listed quest should be enabled without English and live evidence.

UA's item, spell, aura, full-interface, and tooltip localization are separate larger projects. Our current scope is the quest reader; those systems should not be counted as translated because UA supports them.

## Evidence and reproduction

- [Audit JSON with hashes, fields, holds, and source-gap records](coverage/2026-11-05.json)
- [All 5,550 missing quest IDs and English identifiers](coverage/missing-quests-2026-11-05.csv)
- [Fresh v0.6.2 automated validation](validation/v0.6.2-2026-11-05.json)
- [Audit script](../tools/audit_coverage.py) and [its fixture tests](../tools/test_audit_coverage.py)

The upstream official ZIP SHA256 is `74469bddba69af0411e7d0e7116f14d1e2c40e0a133633eb94fba2f47b94ef38`. Catalog hashes and pinned commits are stored in the JSON. The Lua catalog is evaluated as data in an empty environment with an instruction limit; no upstream addon scripts are loaded.

The November 5 GitHub update preserves the published addon/source bytes. This report and repository sync do not themselves add new translations or constitute a new addon release.
