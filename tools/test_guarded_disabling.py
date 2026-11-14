"""Guarded removal of a previously reviewed field must fail closed."""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

import build_release as b

sys.path.insert(0,str(b.BASE/'BuildSource'))
import linguistic_lint  # real annotation validation, also used by compose


class GuardedDisablingTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.root=Path(self.temp.name)
        self.base=self.root/'baseline'
        self.old='ယခင်ဘာသာပြန်'
        self.drafts={'42':{'title':'ခေါင်းစဉ်','detail':self.old,'objective':None,'progress':None,'complete':'ပြီးပြီ'}}
        self.write(self.base/'BuildSource/drafts.json',self.drafts)
        self.write(self.base/'BuildSource/worklist.json',[{'id':42,'en':'Quest','runtimeEnabled':True}])
        english={'title':'Quest','detail':'Go to the trainer.','objective':None,'progress':None,'complete':'Ready.'}
        self.source={'42':{'english':english}}
        self.review=[{'id':42,'fields':{'detail':{'englishSHA256':b.text_sha(english['detail']),'myanmarSHA256':None}}}]
        self.pack={'drafts':{},'rows':[],'overrides':{'42':{'detail':None}},'overridePriorSHA256':{'42':{'detail':b.text_sha(self.old)}},'heldFields':[{'id':42,'field':'detail','reason':'Current primary removed the legacy referral.'}],'pronunciations':{},'annotationExceptions':{}}
        self.manifest={'packs':['repair']}
        self.patches=[patch.object(b,'ROOT',self.root),patch.object(b,'BASE',self.base)]
        for p in self.patches:p.start()

    def tearDown(self):
        for p in reversed(self.patches):p.stop()
        self.temp.cleanup()

    def write(self,path,value):
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_text(json.dumps(value,ensure_ascii=False),encoding='utf-8')

    def compose(self):
        self.write(self.root/'repair/pack.json',self.pack)
        self.write(self.root/'repair/english-sources.json',self.source)
        self.write(self.root/'repair/review-audit.json',self.review)
        return b.compose(self.manifest)

    def test_documented_exact_hash_disabling_preserves_other_fields_and_snapshot(self):
        before=copy.deepcopy(self.drafts)
        drafts,rows,baseline,overrides,reports,holds=self.compose()
        self.assertIsNone(drafts['42']['detail'])
        for field in ['title','objective','progress','complete']:
            self.assertEqual(drafts['42'][field],before['42'][field])
        self.assertEqual(baseline,before)
        self.assertEqual(b.read(self.base/'BuildSource/drafts.json'),before)
        self.assertIn(('42','detail'),overrides)
        self.assertIsNone(overrides[('42','detail')])
        self.assertEqual(reports[0]['questAdditions'],0)
        self.assertEqual(holds,self.pack['heldFields'])

    def test_older_manifest_keeps_the_original_enabled_field(self):
        drafts,*_=b.compose({'packs':[]})
        self.assertEqual(drafts,self.drafts)

    def test_wrong_or_missing_prior_hash_is_rejected(self):
        for value in ['0'*64,None]:
            with self.subTest(priorHash=value):
                self.pack['overridePriorSHA256']={'42':{'detail':value}}
                with self.assertRaises(AssertionError):self.compose()

    def test_disabling_without_documented_hold_is_rejected(self):
        self.pack['heldFields']=[]
        with self.assertRaises(AssertionError):self.compose()

    def test_already_absent_field_cannot_be_disabled_again(self):
        self.drafts['42']['detail']=None
        self.write(self.base/'BuildSource/drafts.json',self.drafts)
        self.pack['overridePriorSHA256']={}
        with self.assertRaises(AssertionError):self.compose()

    def test_empty_string_cannot_bypass_the_disabling_contract(self):
        self.pack['overrides']['42']['detail']=''
        self.review[0]['fields']['detail']['myanmarSHA256']=b.text_sha('')
        with self.assertRaises(AssertionError):self.compose()


    def test_disabling_requires_a_nonblank_reason(self):
        for reason in [None,'',' \t\n']:
            with self.subTest(reason=reason):
                if reason is None:
                    self.pack['heldFields'][0].pop('reason',None)
                else:
                    self.pack['heldFields'][0]['reason']=reason
                with self.assertRaises(AssertionError):self.compose()


if __name__=='__main__':
    unittest.main()
