import tempfile
import unittest
from pathlib import Path

from audit_coverage import compare_upstream, inventory, load_ua, present, title_result


class CoverageTests(unittest.TestCase):
    def test_lua_loader_preserves_multiline_text_and_faction(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "quests.lua"
            path.write_text('local _, at = ...\nat.quest_alliance = {[7] = {[1] = "Title", [2] = [[first\nsecond]], ["en"] = "English"}}\nat.quest_horde = {}\nat.quest_both = {}\n', encoding="utf-8")
            quests, counts = load_ua(path)
        self.assertEqual(quests[7][0]["detail"], "first\nsecond")
        self.assertEqual(quests[7][0]["faction"], "Alliance")
        self.assertEqual(counts, {"Alliance": 1, "Horde": 0, "Both": 0})

    def test_title_only_record_is_not_full_dialogue(self):
        drafts = {"1": {"title": "name", "detail": None, "objective": None, "progress": None, "complete": None}}
        rows = [{"id": 1, "en": "Name", "region": "Sample"}]
        ua = {1: [{"en": "Name", "title": "Назва", "detail": "offer", "faction": "Alliance"}],
              2: [{"en": "Other", "title": "інше", "faction": "Both"}]}
        result = inventory(drafts, rows, ua)
        self.assertEqual(result["myanmarQuestIDs"], 1)
        self.assertEqual(result["availableDialogueStates"], 0)
        self.assertEqual(result["absentOrHeldDialogueStates"], 3)
        self.assertEqual(result["uaQuestIDsMissingFromMyanmar"], 1)
        self.assertEqual(result["uaPresentMyanmarMissingFields"], [{"id": 1, "en": "Name", "field": "detail"}])

    def test_same_id_in_multiple_faction_tables_counts_once(self):
        drafts = {"1": {"title": "name", "detail": "offer", "objective": None, "progress": None, "complete": None}}
        rows = [{"id": 1, "en": "Name"}]
        ua = {1: [{"en": "Name", "detail": "offer", "faction": "Alliance"},
                  {"en": "Name", "complete": "reward", "faction": "Both"}]}
        result = inventory(drafts, rows, ua)
        self.assertEqual(result["uaUniqueQuestIDs"], 1)
        self.assertEqual(result["overlapQuestIDs"], 1)
        self.assertEqual(result["uaPresentMyanmarMissingFields"][0]["field"], "complete")

    def test_disabled_record_not_counted_as_runtime_coverage(self):
        result = inventory({"1": {"title": "name"}}, [{"id": 1, "en": "Name", "runtimeEnabled": False}], {})
        self.assertEqual(result["myanmarQuestIDs"], 0)

    def test_title_alias_requires_documented_alias(self):
        variants = [{"en": "Patrolling Westfall"}]
        self.assertEqual(title_result({"en": "Patrolling Westfall!"}, variants), "mismatch")
        self.assertEqual(title_result({"en": "Patrolling Westfall!", "englishTitleAliases": ["Patrolling Westfall"]}, variants), "documented_alias")

    def test_changed_field_and_id_sets(self):
        old = {1: [{"en": "Name", "detail": "old", "faction": "Both"}], 2: []}
        new = {1: [{"en": "Name", "detail": "new", "faction": "Both"}], 3: []}
        result = compare_upstream(old, new)
        self.assertEqual(result["addedQuestIDs"], [3])
        self.assertEqual(result["removedQuestIDs"], [2])
        self.assertEqual(result["changedQuestRecords"], [{"id": 1, "fields": ["detail"]}])

    def test_empty_text_not_translation(self):
        self.assertFalse(present("  "))
        self.assertFalse(present(None))
        self.assertFalse(present(False))


if __name__ == "__main__":
    unittest.main()
