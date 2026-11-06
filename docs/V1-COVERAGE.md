# MyanmarForever 1.0.0 coverage

Version 1.0.0 covers starter routes for all **nine playable races** across the seven original/Forever starting areas. Skyborne coverage includes both faction branches on Zephras Isle. It is a release version with no beta/candidate suffix; quest coverage continues to expand.

| Measure | Version 1.0.0 |
| --- | ---: |
| Quest IDs | 852 |
| Titles | 852 |
| Offer/detail fields | 837 |
| Objective fields | 837 |
| Progress replies | 634 |
| Completion replies | 823 |
| Translated fields | 3,983 |
| Available offer/progress/completion states | 2,294 |
| Absent or held dialogue states | 262 |
| Short first-introduction terms | 46 |

## What changed

| Source pack | Quest additions | Added translated fields |
| --- | ---: | ---: |
| Existing published base | 664 existing records | 3,134 existing fields |
| Undead starter update | 24 | 106 |
| Captured missing quests | 13 | 61 |
| Delicate Instruments progress fix | Existing quest 91723 | 1 |
| Skyborne starter experience | 151 | 681 |

The 664 earlier records are preserved except for the explicitly sourced missing progress reply on quest 91723. All 30 missing dialogue states found in the saved capture snapshot, across 14 quest IDs, now have matching translations. Thirteen of those IDs were new quests; the fourteenth was the existing Delicate Instruments record. Raw player/account data remains local.

## Skyborne scope

The inventory reconciles installed QuestieDB 1.0.11 metadata, current public zone lists and English quest pages. It includes the shared island story, both faction paths, six class introductions, supported early class chains, beginner profession/camping tutorials, departures and immediate capital introductions. The 151 records include 681 English fields: 151 titles, 151 offers, 151 objectives, 79 progress replies and 149 completions. Every available field is translated.

Seven promotional, unused, disabled or placeholder records remain excluded. The promotional Welcome record is a Collector's Edition voucher quest rather than part of the starter story. The Ancient Hilt (93161) is included from public English evidence despite its absence from installed Questie and the pinned UA corpus. These references do not establish current live eligibility.

English sources use both Hippogryph Harrassment/Harassment and Reading the Ley Lines/Leylines. Only these documented aliases are accepted; unrelated title mismatches still fall back and capture the live text. Source spelling, approximate quantity and place-name variants are recorded in individual audits rather than silently rewritten.

See the [inventory and exclusions](../translations/skyborne-inventory-v1.json) and [full translation review](V1-TRANSLATION-REVIEW.html).

## Remaining gaps and verification

Unavailable source states remain unavailable. In particular, no reviewed completion reply was available for The Ancient Hilt (93161) or the Call of Fire breadcrumb (98517). Some other quests have no available progress reply. The existing source holds remain in place, plus the gender-dependent Tainted Scroll progress reply; version 1 does not choose unverified branches.

All fields received source-aware assisted editing. The first two Undead examples were approved by the owner, who authorized continuing that style. Limited independent integration samples are documented separately; full native Myanmar proofreading and current live Skyborne/controller testing remain pending.

Automated checks pass for source/review hashes, placeholders, quantities, English identity annotations, all 3,983 runtime Unicode round trips and glyph coverage, matching font/catalog hashes, all 16 Lua regression groups, both TOCs and installation ZIP dependencies. Skyborne race IDs 95/96 and English aliases receive a separate introduction from Undead; unknown identities retain literal fallback. Automatic local quest capture remains enabled.

[Validation](validation/v1.0.0-2026-11-06.json) · [Limited integration review](validation/v1.0.0-integration-review.json)

## UA comparison

The pinned UA_Forever 0.23.0 corpus contains 6,214 unique quest IDs. Version 1 overlaps **851 IDs (13.69%)**, has one English-supported ID outside that corpus (93161), and leaves 5,363 UA IDs outside the Myanmar catalog. This is a dated comparison-corpus percentage, not a percentage of all live WoW Forever content.

[Machine-readable coverage](coverage/v1.0.0-2026-11-06.json)
