"""Inventory coverage; UA is a secondary reference, never an English source."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

FIELDS = {1: "title", 2: "detail", 3: "objective", 4: "progress", 5: "complete"}
TABLES = {"quest_alliance": "Alliance", "quest_horde": "Horde", "quest_both": "Both"}
UPSTREAM_COMMIT = "e7087161130b9fe48efbe7b7b0a548d184af329d"
PREVIOUS_COMMIT = "332e9b866f55cd56afb658cc7f9202dc08b15b88"
EXPECTED_UPSTREAM_SHA256 = "1655f676c60b2afe939acc234988a331f48d22709bf8e0605f7eaf6a782b5f76"
EXPECTED_PREVIOUS_SHA256 = "e86f00bdc86e3cd3851284db394d51207ea9c4aa8627f4a3293114aa4e233575"


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def present(value):
    return isinstance(value, str) and bool(value.strip())


def load_ua(path):
    """Evaluate the data-only catalog with no globals and an instruction limit."""
    from lupa.lua51 import LuaRuntime

    lua = LuaRuntime(register_eval=False, register_builtins=False)
    load = lua.eval("""function(code, target)
      local chunk = assert(loadstring(code))
      setfenv(chunk, {})
      local steps = 0
      debug.sethook(function()
        steps = steps + 10000
        if steps > 10000000 then error('catalog instruction limit exceeded') end
      end, '', 10000)
      local ok, message = pcall(chunk, 'coverage_audit', target)
      debug.sethook()
      if not ok then error(message) end
    end""")
    addon = lua.table()
    load(Path(path).read_text(encoding="utf-8-sig"), addon)
    variants = defaultdict(list)
    table_counts = {}
    for table_name, faction in TABLES.items():
        table = addon[table_name]
        if table is None:
            raise ValueError(f"Missing upstream table: {table_name}")
        table_counts[faction] = len(list(table.keys()))
        for qid, quest in table.items():
            if not isinstance(qid, (int, float)) or int(qid) != qid:
                raise ValueError(f"Invalid quest ID: {qid!r}")
            record = {field: quest[index] for index, field in FIELDS.items()}
            record.update(en=quest["en"], faction=faction)
            variants[int(qid)].append(record)
    return dict(variants), table_counts


def title_result(row, variants):
    names = {v["en"] for v in variants if present(v.get("en"))}
    if row["en"] in names:
        return "exact"
    if row["en"].strip().casefold() in {n.strip().casefold() for n in names}:
        return "case_only"
    aliases = set(row.get("englishTitleAliases", []))
    if aliases & names:
        return "documented_alias"
    return "mismatch"


def inventory(drafts, rows, upstream):
    rowmap = {int(row["id"]): row for row in rows}
    if len(rowmap) != len(rows):
        raise ValueError("Duplicate Myanmar worklist IDs")
    if set(rowmap) != {int(k) for k in drafts}:
        raise ValueError("Draft and worklist IDs differ")
    enabled = {qid for qid, row in rowmap.items() if row.get("runtimeEnabled", True)}
    upstream_ids = set(upstream)
    overlap = enabled & upstream_ids
    additions = []
    titles = Counter()
    region_counts = Counter()
    for qid in sorted(enabled):
        region_counts[rowmap[qid].get("region", "Unclassified")] += 1
        if qid not in upstream:
            continue
        titles[title_result(rowmap[qid], upstream[qid])] += 1
        draft = drafts[str(qid)]
        for field in FIELDS.values():
            ua_present = any(present(v.get(field)) for v in upstream[qid])
            if ua_present and not present(draft.get(field)):
                additions.append({"id": qid, "en": rowmap[qid]["en"], "field": field})
    translated = {field: sum(present(drafts[str(qid)].get(field)) for qid in enabled)
                  for field in FIELDS.values()}
    return {
        "myanmarQuestIDs": len(enabled),
        "translatedFields": translated,
        "translatedFieldTotal": sum(translated.values()),
        "availableDialogueStates": sum(translated[f] for f in ("detail", "progress", "complete")),
        "absentOrHeldDialogueStates": 3 * len(enabled) - sum(translated[f] for f in ("detail", "progress", "complete")),
        "uaUniqueQuestIDs": len(upstream_ids),
        "overlapQuestIDs": len(overlap),
        "uaQuestIDsMissingFromMyanmar": len(upstream_ids - enabled),
        "myanmarQuestIDsAbsentFromUA": sorted(enabled - upstream_ids),
        "shareOfUAQuestIDsPercent": round(100 * len(overlap) / len(upstream_ids), 2) if upstream_ids else None,
        "titleMatches": dict(sorted(titles.items())),
        "uaPresentMyanmarMissingFields": additions,
        "regionCounts": dict(sorted(region_counts.items())),
    }


def compare_upstream(previous, current):
    def canonical(records):
        return sorted(records, key=lambda r: r["faction"])
    shared = set(previous) & set(current)
    changed = []
    for qid in sorted(shared):
        before, after = canonical(previous[qid]), canonical(current[qid])
        if before != after:
            changed.append({"id": qid,
                            "fields": [f for f in ["en", *FIELDS.values()]
                                       if [r.get(f) for r in before] != [r.get(f) for r in after]]})
    return {"addedQuestIDs": sorted(set(current) - set(previous)),
            "removedQuestIDs": sorted(set(previous) - set(current)),
            "changedQuestRecords": changed}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--addon", type=Path, default=Path(__file__).resolve().parents[1] / "Myanmar_Forever_NorthshireTest")
    parser.add_argument("--upstream", required=True, type=Path)
    parser.add_argument("--previous", required=True, type=Path)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "docs" / "coverage")
    args = parser.parse_args()
    if sha(args.upstream) != EXPECTED_UPSTREAM_SHA256 or sha(args.previous) != EXPECTED_PREVIOUS_SHA256:
        parser.error("Catalog hashes differ from this dated audit's pinned 0.23.0 / 0.20.5 inputs")
    base = args.addon / "BuildSource"
    drafts, rows = read_json(base / "drafts.json"), read_json(base / "worklist.json")
    spec, sources = read_json(base / "release-spec.json"), read_json(base / "source-audit-v0.6.1.json")
    current, faction_counts = load_ua(args.upstream)
    previous, _ = load_ua(args.previous)
    result = inventory(drafts, rows, current)
    assert result["myanmarQuestIDs"] == spec["quests"]
    assert result["translatedFieldTotal"] == spec["translatedFields"]
    assert result["availableDialogueStates"] == spec["dialogueStates"]
    assert result["absentOrHeldDialogueStates"] == spec["absentOrHeldStates"]
    changes = compare_upstream(previous, current)
    held = {(h["id"], h["field"]) for h in spec["heldFields"]}
    for field in result["uaPresentMyanmarMissingFields"]:
        field["held"] = (field["id"], field["field"]) in held
    missing_ids = sorted(set(current) - {int(k) for k in drafts})
    summary = {
        "auditDate": "2026-11-05",
        "baselineVersion": spec["version"],
        "upstreamVersion": "0.23.0",
        "upstreamCommit": UPSTREAM_COMMIT,
        "previousUpstreamVersion": "0.20.5",
        "previousUpstreamCommit": PREVIOUS_COMMIT,
        "upstreamSourceBuild": "1.60.1.70790",
        "upstreamRelease": "https://github.com/sysrover/UA_Forever/releases/tag/0.23.0",
        "upstreamPublishedAtUTC": "2026-11-05T02:48:00Z",
        "upstreamOfficialZIP_SHA256": "74469bddba69af0411e7d0e7116f14d1e2c40e0a133633eb94fba2f47b94ef38",
        "provenance": {
            "uaQuestFileSHA256": sha(args.upstream),
            "previousUAQuestFileSHA256": sha(args.previous),
            "draftsSHA256": sha(base / "drafts.json"),
            "worklistSHA256": sha(base / "worklist.json"),
            "luaEvaluation": "Lua 5.1; empty globals; 10 million instruction limit; catalog only, no addon scripts",
        },
        "coverage": result,
        "upstreamFactionTableEntries": faction_counts,
        "upstreamFieldPresence": {f: sum(any(present(r.get(f)) for r in records) for records in current.values())
                                  for f in FIELDS.values()},
        "myanmarOverlapByUpstreamFactionTable": {
            faction: sum(qid in {int(k) for k in drafts} and any(r["faction"] == faction for r in records)
                         for qid, records in current.items())
            for faction in TABLES.values()
        },
        "upstreamDuplicateIDsAcrossFactionTables": sorted(qid for qid, records in current.items() if len(records) > 1),
        "upstreamChangesSince0205": changes,
        "existingHeldFields": spec["heldFields"],
        "absentEnglishReferenceFields": sum(not f["sourcePresent"] for s in sources for f in s["fields"].values()),
        "sourceCaveatQuestIDs": [s["id"] for s in sources if s.get("sourceCaveats")],
        "nativeReview": "pending; no native approval claimed",
        "liveVerification": "pending; no release-client acceptance or controller approval claimed",
        "knownUnintegratedSourceStates": read_json(base / "source-discoveries-unintegrated.json")["fields"],
        "knownOnwardGaps": read_json(base / "tauren-onward-gaps.json")["quests"],
        "limitations": [
            "UA unique IDs are a comparison corpus, not the total number of live game quests.",
            "Region figures count packaged Myanmar records; no complete per-zone denominator was established.",
            "A record with a title is not necessarily translated in every dialogue state.",
            "UA presence is secondary evidence, not an English semantic source or proof that a state exists live.",
            "Upstream changes compare English identifiers and the five quest text fields, not task-object translations.",
        ],
    }
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "2026-11-05.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with (args.output / "missing-quests-2026-11-05.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["quest_id", "english_titles", "upstream_faction_tables", "available_ua_fields", "upstream_source"])
        for qid in missing_ids:
            records = current[qid]
            writer.writerow([qid, " | ".join(sorted({r["en"] for r in records if present(r.get("en"))})),
                             " | ".join(sorted({r["faction"] for r in records})),
                             " | ".join(f for f in FIELDS.values() if any(present(r.get(f)) for r in records)),
                             f"https://github.com/sysrover/UA_Forever/blob/{UPSTREAM_COMMIT}/entries/forever/cliend_db/quests.lua"])
    print(json.dumps({"coverage": {k: v for k, v in result.items() if k != "uaPresentMyanmarMissingFields"},
                      "uaPresentMyanmarMissingFieldCount": len(result["uaPresentMyanmarMissingFields"]),
                      "upstreamChanges": changes}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
