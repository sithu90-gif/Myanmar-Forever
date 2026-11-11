# Quest translation workflow

Before every quest batch or release, check the latest official UA_Forever release at https://github.com/sysrover/UA_Forever/releases/latest. Record the release version, publication time, exact commit, package SHA-256 and quest catalog SHA-256. Refresh this check for each batch.

Compare the actual composed Myanmar release and every planned quest ID against that pinned UA catalog. Check English titles and documented aliases, available offer/objective/progress/completion fields, and changes since the previous UA version. Use `tools/countercheck_ua.py` to save the comparison alongside the release evidence.

Review new or changed UA entries against current English quest references and sanitized live captures. English controls the meaning of the Myanmar translation. Use installed quest metadata and current English sources to check chain links and live captures to resolve uncertain branches. Record a quest absent from UA as an exception when independent English evidence supports it.

Keep unavailable or conflicting fields explicit. Preserve names, quantities, directions, stage instructions and supported substitution markers. State native proofreading and current live verification separately from source and machine checks.

Use one daily batch of 50–100 quests during active working sessions. Start with 50 and expand toward 75–100 when source verification and review permit. Translate in groups of 5–10 connected quests. Perform a separate English/Myanmar review pass on every group, including names, quantities, directions, NPC voice, placeholders and each available dialogue state. Assemble the daily release after the groups pass validation and report unresolved fields with their evidence.
