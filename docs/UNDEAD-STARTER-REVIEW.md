# v0.6.3 candidate: Deathknell starter route

The Undead starter route now has Myanmar translations in the conversational style approved for the first two examples. English names remain recognizable, with Myanmar pronunciation at first important use in each field. The existing first-introduction term system supplies its 45 short beginner meanings.

[Download the validated candidate](../dist/MyanmarForever_v0.6.3-beta-candidate.zip). SHA-256: `22e83f1f12cfa151b88e577457a7a717e592fcf0c2bf0fb8ab20d15fb72a9001`. The ZIP contains runtime files, licences and candidate notes; the full source/review evidence is maintained in this repository.

## Scope and coverage

- 24 added quest records: the shared Deathknell story, the delivery to Brill and return to Calvin, five original class introductions, the first Warlock summoning quest, the supported early Paladin chain, and the Priest handoff to Brill.
- 106 added translated fields: 24 titles, 24 offers, 24 objectives, 15 progress replies and 19 completion replies.
- Combined candidate: 688 quest IDs, 3,240 translated fields, and 1,879 available offer/progress/completion states. The 664 existing quest records are preserved.
- The rest of Tirisfal Glades and Silverpine are outside this starter-area update. This is not a claim to cover every quest available to an Undead character.

## Route

| Quest ID | English quest | Branch |
| --- | --- | --- |
| 363 | Rude Awakening | Wake in the crypt; meet Sarvis |
| 364 | The Mindless Ones | Sarvis |
| 376 | The Damned | Elreth |
| 3901 | Rattling the Rattlecages | Sarvis |
| 3902 | Scavenging Deathknell | Saltain |
| 6395 | Marla's Last Wish | Elreth |
| 380 | Night Web's Hollow | Arren |
| 381 | The Scarlet Crusade | Arren |
| 382 | The Red Messenger | Arren |
| 383 | Vital Intelligence | Arren → Zygand in Brill |
| 8 | A Rogue's Deal | Calvin → Renee in Brill; shared quest despite its title |
| 590 | A Rogue's Deal | Return to Calvin; defeat rather than kill him |
| 3095 | Simple Scroll | Warrior introduction |
| 3096 | Encrypted Scroll | Rogue introduction |
| 3097 | Hallowed Scroll | Priest introduction |
| 3098 | Glyphic Scroll | Mage introduction |
| 3099 | Tainted Scroll | Warlock introduction |
| 1470 | Piercing the Veil | Warlock's first summoned servant |
| 98601 | A Difficult Path | Paladin introduction |
| 90902 | Rediscovering the Light | Paladin healing |
| 98389 | A Light in the Darkness | Paladin rescues |
| 91208 | Coming to Terms | Paladin reaches out to a frightened peer |
| 91209 | Continue Your Training | Paladin handoff to Brill |
| 5651 | In Favor of Darkness | Priest handoff to Brill |

This is a coverage inventory, not a verified prerequisite order or an optimized leveling guide.

## Source and review notes

English dialogue was captured from the public 60.tools Forever records on November 5, 2026. Wowhead Forever was also consulted for the shared route. UA_Forever 0.23.0 remains a secondary identity/state reference; Ukrainian wording does not control Myanmar meaning. Reference records are not current live-client captures.

The approved opening of 363 and title/offer/objective of 364 are preserved exactly. The user authorized continuing in that style. Other fields and new pronunciations are assisted editorial drafts; they have not each received native-language approval or independent assisted review. DeepL MY comparison drafts were corrected for meaning, idioms, speaker register and English identities. DeepL Free ignored the context parameter; it was not relied upon to preserve names or voice automatically.

Thirteen source states are absent and remain absent: progress for 363, 590 and 5651; progress and completion for all five new Paladin records. One additional state, 3099 progress, is held because the English reference contains literal `brother/sister` alternatives without a verified live gender branch. That state uses the existing English fallback/capture behavior.

The older UA ID 89301 shares the title A Difficult Path but has no available English reference page. Only the supported record 98601 is enabled. The promotional Welcome quest 5843 remains excluded. The source uses both Night Web's Hollow and Night's Web Hollow; each field retains its sourced English spelling rather than silently assuming a new alias.

## Build and checks

From the repository root, using Python with `requirements-dev.txt` installed:

```powershell
python tools/build_candidate.py --output ../outputs/candidate-0.6.3
```

Choose a new output directory for each build. The command stages the preserved base, merges the pack, regenerates its font and catalog together, checks every field against its Unicode draft and glyph coverage, preserves all original quest records, and runs the Lua state-routing and term-introduction regressions. It produces a runtime installation ZIP plus a validation report. The checked-in 0.6.2 snapshot remains unchanged.

Current live Forever testing, controller testing and full native Myanmar proofreading remain pending. CurseForge and social publication are not part of this candidate preparation.

Read the full [Myanmar and English review](UNDEAD-STARTER-TRANSLATIONS.html). Editable translations, English snapshots, pronunciations and review status are in [the versioned pack](../translations/undead-v0.6.3/pack.json).
