# Quest translation workflow

Before every quest batch or release, check the latest official UA_Forever release at https://github.com/sysrover/UA_Forever/releases/latest. Record the release version, publication time, exact commit, package SHA-256 and quest catalog SHA-256. Refresh this check for each batch.

Compare the actual composed Myanmar release and every planned quest ID against that pinned UA catalog. Check English titles and documented aliases, available offer/objective/progress/completion fields, and changes since the previous UA version. Use `tools/countercheck_ua.py` to save the comparison alongside the release evidence.

Review new or changed UA entries against current English quest references and sanitized live captures. English controls the meaning of the Myanmar translation. Use installed quest metadata and current English sources to check chain links and live captures to resolve uncertain branches. Record a quest absent from UA as an exception when independent English evidence supports it.

Keep unavailable or conflicting fields explicit. Preserve names, quantities, directions, stage instructions and supported substitution markers. State native proofreading and current live verification separately from source and machine checks.

The user authorized a daily 03:00 Asia/Rangoon batch of 50 quests and a conditional 13:00 follow-up of up to 50 after the morning source/translation reviews and package checks pass. Resume unfinished work before starting another batch, avoid overlap, and initially cap new records at 100 per day. Translate in groups of 5–10 connected quests. Perform a separate English/Myanmar review pass on every group, including names, quantities, directions, NPC voice, placeholders and each available dialogue state. Assemble each release after the reviewed groups pass validation and report unresolved fields with their evidence.

Read the workspace `.summer/quest-automation-state.json` and confirm its worktree/artifact evidence. Completed IDs from manual workflow tests count as completed work; future scheduled batches must continue after those IDs. Respect `nextNewBatchNotBeforeLocalDate` while allowing unfinished reviews to resume. Save completed ZIP downloads, changelogs, review reports and SHA-256 under `C:/GameDev/Myanmar Forever Translation`, in versioned subfolders, as authorized by the user.

Refresh installed QuestieDB metadata before selection. Fetch current English with `tools/fetch_quest_sources.py --output <batch-source-directory> --metadata <decoded-installed-metadata.json> --ids <quest-IDs>`. Inspect missing states and HTML boundaries, including repeatable quests whose Progress text follows its heading directly. `tools/test_fetch_quest_sources.py` protects that layout. Document obsolete upstream labels separately; never enable an invalid generic runtime title alias just to remove an audit mismatch.

When new English and installed metadata resolve a previously held state, document the old reason and the new source evidence. A reviewed fill must leave the active-hold report while preserving its historical reason under resolvedHeldFields. Native and live test status remain separate.

Preserve the exact bytes of copied Windows validation reports in Git with per-release -text attributes, so delivered validation and package evidence retain stable hashes.
