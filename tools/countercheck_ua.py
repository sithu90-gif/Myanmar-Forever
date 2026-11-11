"""Compare a composed release and planned quest IDs with a pinned UA_Forever catalog."""
import argparse
import json
from pathlib import Path
import re

from audit_coverage import compare_upstream, inventory, load_ua, present, title_result
from build_release import compose, read, sha


def check(manifest_path, catalog, reference_path, previous_catalog, planned_ids):
    reference = read(reference_path)
    if sha(catalog) != reference["catalogSHA256"]:
        raise ValueError("UA catalog hash differs from the pinned release reference")
    if not re.fullmatch(r"[0-9a-f]{40}", reference["commit"]):
        raise ValueError("UA reference requires an exact commit SHA")
    for field in ("version", "checkedAt", "publishedAtUTC", "releaseURL", "assetSHA256"):
        if not reference.get(field):
            raise ValueError(f"Missing UA release evidence: {field}")
    manifest = read(manifest_path)
    drafts, rows, _, _, _, added_holds = compose(manifest)
    upstream, faction_counts = load_ua(catalog)
    coverage = inventory(drafts, rows, upstream)
    root = Path(__file__).resolve().parents[1]
    baseline_holds = read(root / "Myanmar_Forever_NorthshireTest/BuildSource/release-spec.json")["heldFields"]
    holds = {(int(record["id"]), record["field"]): record["reason"]
             for record in [*baseline_holds, *added_holds]}
    for gap in coverage["uaPresentMyanmarMissingFields"]:
        reason = holds.get((gap["id"], gap["field"]))
        gap["documentedHold"] = reason
    changes = None
    affected = []
    if previous_catalog:
        previous, _ = load_ua(previous_catalog)
        changes = compare_upstream(previous, upstream)
        affected = [entry for entry in changes["changedQuestRecords"] if str(entry["id"]) in drafts]
    planned = []
    for quest_id in sorted(set(planned_ids)):
        variants = upstream.get(quest_id, [])
        planned.append({
            "id": quest_id,
            "uaPresent": bool(variants),
            "uaEnglishTitles": sorted({entry["en"] for entry in variants if present(entry.get("en"))}),
            "uaFieldsPresent": {field: any(present(entry.get(field)) for entry in variants)
                                for field in ("title", "detail", "objective", "progress", "complete")},
            "alreadyInMyanmar": str(quest_id) in drafts,
        })
    mismatches = [{"id": row["id"], "en": row["en"]}
                  for row in rows if row["id"] in upstream and title_result(row, upstream[row["id"]]) == "mismatch"]
    return {
        "checkedAt": reference["checkedAt"],
        "myanmarVersion": manifest["version"],
        "upstreamReference": reference,
        "manifestSHA256": sha(manifest_path),
        "upstreamFactionEntries": faction_counts,
        "coverage": coverage,
        "titleMismatches": mismatches,
        "changesSincePreviousCatalog": changes,
        "changedRecordsInMyanmar": affected,
        "plannedQuestChecks": planned,
        "reviewStatus": "Changed UA text and field gaps are candidates for an English-source recheck.",
        "chainVerification": "UA membership is checked per planned step. Chain edges require quest metadata and English evidence.",
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--catalog", required=True, type=Path)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--previous-catalog", type=Path)
    parser.add_argument("--planned-ids", nargs="*", type=int, default=[])
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    report = check(args.manifest, args.catalog, args.reference, args.previous_catalog, args.planned_ids)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n",
                           encoding="utf-8", newline="\n")
    print(json.dumps({
        "myanmarVersion": report["myanmarVersion"],
        "upstreamVersion": report["upstreamReference"]["version"],
        "overlapQuestIDs": report["coverage"]["overlapQuestIDs"],
        "titleMismatches": len(report["titleMismatches"]),
        "changedRecordsInMyanmar": len(report["changedRecordsInMyanmar"]),
        "uaPresentMyanmarMissingFields": len(report["coverage"]["uaPresentMyanmarMissingFields"]),
        "plannedQuestsAbsentFromUA": [entry["id"] for entry in report["plannedQuestChecks"] if not entry["uaPresent"]],
    }, indent=2))
