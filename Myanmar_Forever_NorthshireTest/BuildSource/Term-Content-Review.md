# Brief first-introduction meanings: content review

## Result

The proposal contains 45 canonical terms: 9 faction/group labels, 9 classes, 8 races, 10 ranks/roles, and 9 recurring game/lore concepts. It supplies 112 exact annotated aliases and 23 field-level exclusions. None of the 664 source quest drafts was edited.

The agreed examples are retained exactly:
- Horde (ဟော်ဒ် — မျိုးနွယ်စုပေါင်းအင်အားစု)
- Warrior (ဝေါရီယာ — အနီးကပ်တိုက်ခိုက်တဲ့ စစ်သည်)

Deliverables:
- term-glossary-v0.6.2.json: integration data with key, en, pronunciation, meaning, category, aliases, sourceQuestIDs, sourceURLs, and excludedContexts.
- Term-Glossary-Review-List.txt: compact Myanmar wording checklist.

## Use and important limits

1. Introduce an eligible key on its first actual displayed encounter, then retain only pronunciation. Quest ordering is not player encounter ordering. Do not consume a seen key while building, previewing hidden states, or skipping an exception.
2. Matching is by a complete annotated alias. Named ranks retain the whole NPC name and whole pronunciation, but share the rank's once-only key. The names of places, items, and enemies do not inherit meanings merely because they contain the same English word.
3. Original 0.6.1 spelling is preserved. Old embedded explanations are matched so the renderer can replace them rather than append a second gloss. Carrying a historical spelling forward is not a declaration of native approval.
4. Dynamic Priest and Priestess labels share class.priest. The gendered English/pronunciation labels remain distinct.
5. Rune, Totem, Arcane, and Emerald Dream receive deliberately broad meanings. No cooldowns, damage types, current class-race eligibility, new story chronology, or promises of an item's powers are added.
6. No intrinsic good/evil alignment is assigned to Alliance or Horde. Warchief is a war-leadership role, not a universally exclusive title for the Horde. Captain covers both military and nautical contexts without inventing a precise modern rank.
7. Undead has a broad risen-dead meaning. Forsaken is a distinct group. The API token Scourge must never turn the player's race introduction into a description of the enemy Scourge faction.

## Exceptions that affect correctness

- Quest 152 detail/objective/progress: standalone Warrior means the shortened Murloc Warrior kill target.
- Quest 56 progress: Warrior and Mage mean the shortened Skeletal enemy names.
- Quest 743 detail: Ruul's generic warrior-and-teacher statement already has စစ်သည်တော် after the label.
- Quest 65 detail: the source's “rogue” description of Wiley does not establish the player class; exclude it.
- Human labels immediately followed by လူသား are already explained. The JSON identifies each exact field rather than changing dialogue.
- Quest 56 title already supplies ညကင်းတပ် after Night Watch; quests 265 progress and 1395 complete already give Mage a generic မှော်ဆရာ meaning.
- Sentinel Hill, Morbent Fel, Burning Blade Coven, creature compounds, and compound Rune/Sigil/Totem item titles are not glossary aliases. Existing meaningful item-title wording is therefore untouched by this proposal.

## Evidence

The stable class summaries, faction division, race identities, Forsaken distinction, shaman objects, and Hearthstone purpose were checked against Blizzard's [World of Warcraft manual](https://bnetcmsus-a.akamaihd.net/cms/template_resource/263A8NGR8HLZ1556919642368.pdf), especially PDF pages 15, 69–80, 101, and the race appendix. These sources establish general concepts; they do not certify current Forever mechanics. [Blizzard's class overview](https://worldofwarcraft.blizzard.com/en-gb/game/classes) and [race overview](https://worldofwarcraft.blizzard.com/en-us/game/races) corroborate the stable identities. No retired class restrictions from the manual were copied into the meanings.

Named Sentinels' defensive/military role is supported by the official [Night Elf description](https://worldofwarcraft.blizzard.com/en-us/game/races/night-elf) and [Elegy](https://worldofwarcraft.blizzard.com/en-gb/media/short-story/elegy). The Defias group is described as former workers turned brigands in Blizzard's [Cataclysm Classic dungeon preview](https://worldofwarcraft.blizzard.com/en-gb/news/24095666/unveiling-cataclysm-classic-zones-dungeons-and-pvp-season-9); only that historical identity is used, without importing Cataclysm events. Fel's demonic nature is supported by Blizzard's [Shattered Halls preview](https://worldofwarcraft.blizzard.com/en-us/news/19803331/timewalking-highlight-the-shattered-halls). The [Emerald Nightmare preview](https://worldofwarcraft.blizzard.com/en-gb/news/20271917/raid-preview-7-eerie-reasons-to-enter-the-emerald-nightmare) supports Emerald Dream as a distinct realm; the proposal avoids further cosmological claims.

Rank words were checked against Merriam-Webster's [marshal](https://www.merriam-webster.com/dictionary/marshal), [captain](https://www.merriam-webster.com/dictionary/captain), [lieutenant](https://www.merriam-webster.com/dictionary/lieutenant), and [quartermaster](https://www.merriam-webster.com/dictionary/quartermaster) entries, while quest context controls the relevant sense. The Myanmar phrases intentionally avoid claiming an exact modern army equivalent.

Game-authored English quest snapshots in full_catalog_correction/review provide the directly relevant primary dialogue, with each catalog audit's public reference URL retained in the JSON. Especially useful records are 56/146 (Night Watch), 102/144 (militia), 749/751 (Venture Co.), 792/794/829 (Burning Blade), 921/4812 (Moonwells), 3116 (Sigil), and 77616/3106 (the different Rune uses). The public quest pages are third-party mirrors of that primary game text, not official current-client verification.

## Remaining review gate

Meanings are assisted editorial proposals. Native Myanmar proofreading remains pending, especially the compact class and fantasy-race descriptors. Neither source lookup nor alias validation constitutes native-language certification or a live Forever test. Race descriptions are recognizable appearance/culture cues, not exhaustive biological definitions or claims about every individual.
