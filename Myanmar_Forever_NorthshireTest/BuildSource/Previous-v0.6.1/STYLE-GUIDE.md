# Myanmar Forever translation standard

Version: 0.6.1 candidate, 11 October 2026.

## Source and scope

The original English quest text controls meaning. UA_Forever is a secondary source for quest identity, structure, coverage and comparisons, not a replacement English source. A database listing is not proof that a quest can currently be accepted in Forever. A catalog preview is not a live-client test.

Review every title, offer (`detail`), objective, progress and completion separately. Do not create a missing state or enable a held field from context. Preserve the speaker, addressee, direction of actions, uncertainty, humor, omissions, emphasis and quantities. Preserve `<name>`, `<class>`, `<race>` and other supported substitution markers exactly. Preserve stage directions and formatting meaning.

## Recognizable identities and pronunciation

1. Retain the recognizable English identity of NPCs, named places and buildings, factions, creatures/targets, items, spells, classes, races, ranks and important lore terms.
2. At the first important occurrence in each displayed field, append a Myanmar pronunciation: `English Name (မြန်မာအသံထွက်)`.
3. Treat the whole identifying phrase as a unit. A full name with a rank gets one combined annotation. Phonetically render the retained English words; a semantic description alone is not pronunciation. An optional brief meaning explanation follows the pronunciation when it genuinely helps.
4. Later occurrences of the same identity in the same field normally retain English without another long annotation. A title does not supply the first-use annotation for its offer, objective, progress or completion.
5. A shortened reference may share a full-name identity in the same field when context establishes it. A common noun is not automatically a proper name. For example, Valley in quest 4641 refers to Valley of Trials, whereas an ordinary valley in another quest does not.
6. Translate ordinary narrative and meaningful quest-title wording into natural Myanmar. Do not phonetically transliterate entire English sentences or ordinary quest-title wording.
7. Use the maintained glossary. Historical entries contain both pronunciations and meaning glosses; their age alone does not establish correctness or user approval. Record deliberate spelling reconciliations. New spellings are assisted editorial proposals pending native-language review.

## Voice, personality and culture

Preserve the specific source speaker rather than assigning one uniform voice to a race. A culture can inform the source's idiom and register but does not license adding lore, stereotypes, modern Myanmar dialects or dialogue that is not present.

- Distinguish a teasing recruit assessor from a skeptical drill instructor, even in the same Orc chain.
- Preserve a Tauren speaker's reverence, grief, pragmatism or anger when it appears in the source. Do not make every Tauren sentence ceremonially solemn.
- Preserve differences among Night Elf sentinels, priests, druids, civilians and hostile speakers. Do not turn them all into a formal narrator.
- Preserve individual dwarf/gnome jokes, drinking references and practical or technical concerns without invented regional accents.
- Politeness particles must fit the individual utterance. A blunt command, sarcasm, threat or disdain must not automatically become a courteous request.
- Objectives are concise task instructions; they do not inherit invented dialogue from a nearby NPC.

## Dynamic player identities

Player names remain literal and safely escaped for WoW text. Known class/race identities use canonical English plus a short Myanmar pronunciation on first use in each field, then English alone. Their labels are shaped with the same catalog/font build. Locale-independent class/race tokens are preferred. Unknown client identities remain literal rather than receiving an invented pronunciation. Secret or unavailable API values are never inspected or exposed.

## Review and validation gates

Maintain one audit record per quest. Record which fields were actually read against English, the evidence, corrections, source discrepancies and remaining blockers. An automated identity, digit, glyph or regex pass cannot establish semantic correctness, pronunciation quality or NPC voice.

Keep these statuses separate:
- English-source/assisted semantic review
- Independent assisted review
- Machine integrity, shaping and Lua state-routing tests
- Native Myanmar proofreading
- Current live Forever verification
- Controller hardware verification

The last three gates cannot be inferred from the first three. Unresolved source variants stay explicit until a current live capture resolves them.

## Identifying titles and compound pronunciations
When a quest title is the exact identifying name of its item, target, buff/spell,
letter/rune/sigil, named rite or artifact, retain that English identity and one
Myanmar pronunciation. Translate surrounding ordinary title framing semantically.
This applies to titles as well as dialogue; titles are independently displayed
sections. Do not assume every title is an identifying name.

The glossary's spellings are assisted editorial proposals, not individually
user-approved or native-certified pronunciations. Full-name compound labels use
consistent core names (for example Bloodhoof, Rune, Tower and Sigil). Sigil's
assisted pronunciation reflects the /sɪdʒɪl/ form documented by Merriam-Webster
(https://www.merriam-webster.com/dictionary/sigil) and Dictionary.com
(https://www.dictionary.com/browse/sigil). Native pronunciation review remains a
release gate; the tests enforce consistency, not phonetic correctness.
