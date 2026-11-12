import unittest
from build_release import BASE, classify_source_holds, reviewed_hold_test_source, reviewed_term_test_source

class SourceHoldReportTests(unittest.TestCase):
    def test_reviewed_fill_resolves_historical_hold_without_hiding_pending_states(self):
        old={'id':98021,'field':'complete','reason':'Race condition not yet established'}
        pending={'id':98435,'field':'detail','reason':'Unresolved branch'}
        outside={'id':999999,'field':'detail','reason':'Excluded source candidate'}
        drafts={'98021':{'complete':'Reviewed source-supported reply'},'98435':{'detail':None}}
        active,resolved=classify_source_holds(drafts,[old,pending,outside])
        self.assertEqual(active,[pending,outside])
        self.assertEqual(resolved,[old])
        self.assertEqual(old['reason'],'Race condition not yet established')


    def test_snapshot_hold_assertion_tracks_the_reviewed_manifest_field(self):
        original=(BASE/'BuildSource/tests.lua').read_text(encoding='utf8')
        pending={'98021':{'complete':None}}
        resolved={'98021':{'complete':'Reviewed literal Skyborne reply'},'97924':{'complete':'Reviewed camping reply'},'97279':{'progress':'Reviewed weapon reply'}}
        self.assertEqual(reviewed_hold_test_source(original,pending),original)
        current=reviewed_hold_test_source(original,resolved)
        self.assertNotIn('Unverified elf-specific completion released',current)
        self.assertIn("assert(A.window:IsShown(),'Source-reviewed Skyborne completion missing')",current)
        self.assertIn('Source-reviewed camping completion missing',current)
        self.assertIn('Source-reviewed custom progress or capture missing',current)
        with self.assertRaises(AssertionError):
            reviewed_hold_test_source('Changed historical test',resolved)



    def test_term_learning_uses_a_still_held_probe_after_source_resolution(self):
        original=(BASE/'BuildSource/term_tests.lua').read_text(encoding='utf8')
        self.assertEqual(reviewed_term_test_source(original,{'98021':{'complete':None}}),original)
        resolved={'98021':{'complete':'Reviewed reply'},'842':{'complete':None}}
        current=reviewed_term_test_source(original,resolved)
        self.assertIn("liveShow(842,'QUEST_COMPLETE');assert(not A.window:IsShown());emptySeen()",current)
        self.assertNotIn("liveShow(98021,'QUEST_COMPLETE');assert(not A.window:IsShown());emptySeen()",current)
        with self.assertRaises(AssertionError):
            reviewed_term_test_source(original,{'98021':{'complete':'Reviewed reply'},'842':{'complete':'Newly reviewed'}})
        with self.assertRaises(AssertionError):
            reviewed_term_test_source('Changed historical probe',resolved)


if __name__=='__main__':
    unittest.main()
