# Fresh independent English/Myanmar review

Read root AGENTS.md and work/Myanmar-Forever-v1.2.7/AGENTS.md, established BuildSource/STYLE-GUIDE.md and ../worker.md. Review every assigned quest and enabled field against actual current English/source HTML, installed metadata and pinned UA1.0.0. Raw DeepL/provenance/holds/audits are evidence, not a substitute for reading final text. Check voice, fluency, meaning, exact IDs/same-title branches, names/ranks/places, numbers and written quantities, directions, temporal/stage clauses, placeholders and maintained phonetics per first English occurrence. Unsupported gender markers remain held. Completion-only records keep current nulls. Do not treat self-review or simulations as native/live verification.

Do not edit worker files, shared repo, Git or automation state. Write only YOUR_GROUP.json here. Format:
{quests:[{id:123,reviewNotes:['actual per-ID observations'],issues:[]}],requestedHolds:[],pronunciationMapReconciliation:[],status:'...',nativeMyanmarProofreading:'pending',liveClientVerification:'not tested'}
All assigned IDs must be included. One consolidated issue per field:
{field:'detail',englishSHA256:'...',reviewedMyanmarSHA256:'...',old:'exact unique substring',new:'replacement',proposedFullField:'complete corrected field',reason:'source-specific reason'}
Multiple changes use whole-field old/new. The replacement must yield proposedFullField exactly. Requested holds separately need id,field,englishSHA256,reviewedMyanmarSHA256,reason. Pronunciation reconciliation needs term,old,new,reason. Root applies approved changes under exacthash guards and repeats checks. Preserve source uncertainty and held evidence; no invented branch.
