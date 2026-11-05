"""Catalog-wide source integrity and Lua 5.1 mocks. No live-client claim."""
from pathlib import Path
from collections import Counter
import hashlib,json,re,xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime
from fontTools.ttLib import TTFont

BASE=Path(__file__).resolve().parent
ADDON=BASE.parent
load=lambda n:json.loads((BASE/n).read_text(encoding='utf-8'))
canonical=lambda d:json.dumps(d,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode()
digest=lambda d:hashlib.sha256(canonical(d)).hexdigest()
drafts=load('drafts.json');rows=load('worklist.json')
sources=load('source-audit-v0.6.1.json');spec=load('release-spec.json')
baseline=load('baseline-v0.6.0.json');validation=load('validation.json')
changes=load('approved-changes-v0.6.1.json');review=load('catalog-review-v0.6.1.json')
audit=load('audit-summary-v0.6.1.json');inventory=load('tauren-inventory.json')
assert len(drafts)==len(rows)==len(sources)==spec['quests']
assert len({r['id'] for r in rows})==len(rows)
assert len({r['id'] for r in sources})==len(sources)
assert set(drafts)=={str(r['id']) for r in rows}=={str(s['id']) for s in sources}
prior=set(baseline['questSHA256']);assert len(prior)==664 and prior==set(drafts)
assert spec['addedQuestRecords']==0
rowmap={str(r['id']):r for r in rows}
changed={str(r['id']):r for r in changes['quests']}
unchanged=0
for qid,previous in baseline['questSHA256'].items():
 if digest(drafts[qid])==previous:
  assert qid not in changed,('Unchanged record listed as changed',qid)
  unchanged+=1
 else:
  assert qid in changed,('Unreviewed catalog change',qid)
  assert changed[qid]['beforeSHA256']==previous
  assert changed[qid]['afterSHA256']==digest(drafts[qid])
  fields=changed[qid]['fields']
  for field,text in drafts[qid].items():
   different=digest(text)!=baseline['fieldSHA256'][qid][field]
   assert different==(field in fields),('Unaudited field change',qid,field)
   if different:
    assert fields[field]['beforeSHA256']==baseline['fieldSHA256'][qid][field]
    assert fields[field]['afterSHA256']==digest(text)
assert unchanged==spec['unchangedQuestRecords'] and len(changed)==spec['changedQuestRecords']
for file,expected in baseline['runtimeSHA256'].items():
 actual=hashlib.sha256((ADDON/file).read_bytes()).hexdigest()
 if file=='QuestBridge.lua':
  assert changes['runtimeFiles'][file]['beforeSHA256']==expected
  assert changes['runtimeFiles'][file]['afterSHA256']==actual
 else:assert actual==expected,('Unexpected UI/control/overlay change',file)
reviews={str(r['id']):r for r in review['quests']}
assert set(reviews)==set(drafts), 'Full catalog audit coverage missing'
for qid,q in drafts.items():
 r=reviews[qid]
 assert set(r['fieldsReviewed'])==set(q),('Missing field review',qid)
 assert r['finalSHA256']==digest(q),('Review stale after later edit',qid)
 assert r['independentReview']['status'] in ('assisted_reviewed','source_blocked'),('Independent review absent',qid)
 assert r['sources'],('No English evidence reference',qid)
holds={(s['id'],s['field']) for s in spec['heldFields']}
assert {(98021,'complete'),(95213,'complete'),(3118,'progress'),(842,'complete'),(3083,'progress')}<=holds
checks=0;held_checked=set();absent_fields=0
for source in sources:
 q=drafts[str(source['id'])]
 assert set(q)=={'title','detail','objective','progress','complete'}
 for field,evidence in source['fields'].items():
  text=q[field]
  if evidence['held']:
   assert (source['id'],field) in holds and evidence['sourcePresent'] and text is None
   held_checked.add((source['id'],field))
  elif evidence['sourcePresent']:
   assert text,('Untranslated sourced field',source['id'],field)
   assert Counter(re.findall(r'<(?:name|class|race)>',text.lower()))==evidence['identityTokens'],('Identity mismatch',source['id'],field)
   assert Counter(re.findall(r'\d+',text))==evidence['quantityDigits'],('Quantity-digit mismatch',source['id'],field)
   assert not re.search(r'(?i)<(?:name|class|race)\s',text)
   checks+=1
  else:
   assert text is None;absent_fields+=1
  if text:
   assert not any(0xE000<=ord(c)<=0xF8FF for c in text),('Encoded glyph in editable draft',source['id'],field)
   assert not re.search(r'[\u0400-\u04ff\ufffd]|&(?:lt|gt|amp|quot);',text),('Unexpected script/encoding',source['id'],field)
assert held_checked==holds and absent_fields==audit['absentReferenceFields']
assert checks==spec['translatedFields']==audit['enabledFieldsChecked']
states=sum(q[f] is not None for q in drafts.values() for f in ('detail','progress','complete'))
assert states==spec['dialogueStates']
missing=3*len(drafts)-states
assert missing==spec['absentOrHeldStates']
assert validation['version']==spec['version']==audit['version']=='0.6.1-beta-candidate'
assert validation['runtimeQuestCount']==len(drafts) and validation['runtimeDialogueStates']==states
assert not any(str(qid) in drafts for qid in (5843,7664,7665))
for file,key in [('fonts/NorthshireShaped.ttf','fontSHA256'),('Catalogs/Northshire.lua','catalogSHA256')]:
 assert hashlib.sha256((ADDON/file).read_bytes()).hexdigest()==validation[key],('Font/catalog mismatch',file)
xml=ET.parse(ADDON/'Bindings.xml').getroot();assert xml.tag=='Bindings' and len(xml)==6
assert len({node.attrib['name'] for node in xml})==6
for toc in ADDON.glob('*.toc'):
 text=toc.read_text();assert '## Version: 0.6.1-beta-candidate' in text and '## Interface: 16001' in text
 assert '## SavedVariables: MMNorthshireSettings, MMNorthshireCaptures' in text
 files=[line.strip().replace('\\','/') for line in text.splitlines() if line.strip() and not line.startswith('#')]
 assert files==['Catalogs/Northshire.lua','Renderer.lua','QuestBridge.lua','Controls.lua']
 assert all((ADDON/file).is_file() for file in files)
lua=LuaRuntime(unpack_returned_tuples=True)
assert lua.eval('_VERSION')=='Lua 5.1'
logs=[];lua.globals().print=lambda *args:logs.append(' '.join(map(str,args)))
lua.globals().ADDON_DIR=str(ADDON)
lua.globals().EXPECTED_QUESTS=len(drafts);lua.globals().EXPECTED_STATES=states;lua.globals().EXPECTED_MISSING=missing
lua.globals().BINDING_ACTIONS=lua.table_from([(node.text or '').strip() for node in xml])
lua.execute((BASE/'tests.lua').read_text(encoding='utf-8'))
for node in xml:assert lua.globals()['BINDING_NAME_'+node.attrib['name']]
addon=lua.table()
lua.execute((ADDON/'Catalogs/Northshire.lua').read_text(), 'Myanmar_Forever_NorthshireTest', addon)
clusters=load('clusters.json');reverse={chr(cp):word for word,cp in clusters['map'].items()}
cmap=TTFont(ADDON/'fonts/NorthshireShaped.ttf').getBestCmap();decoded=0
for qid,q in drafts.items():
 for field,text in q.items():
  runtime=addon.quests[int(qid)][field]
  if text is None:assert runtime is None
  else:
   assert ''.join(reverse.get(c,c) for c in runtime)==text,(qid,field,'round trip')
   assert all(ord(c) in cmap for c in runtime if c not in '\n\r\t'),(qid,field,'glyph coverage')
   decoded+=1
alias_ids=[]
for row in rows:
 aliases=row.get('englishTitleAliases',[])
 runtime=addon.quests[row['id']].enAliases
 actual=[runtime[i] for i in range(1,len(runtime)+1)] if runtime is not None else []
 assert actual==aliases,('Unexpected title aliases',row['id'])
 if aliases:alias_ids.append(row['id'])
assert decoded==checks==validation['translatedFields']
# Every dynamic label is validated against its Unicode source and current font.
identities=load('identity-glossary.json');identity_count=0
for kind,records in identities.items():
 for token,record in records.items():
  actual=addon.identityLabels[kind][token]
  expected=record['en']+' ('+record['pronunciation']+')'
  assert actual.en==record['en']
  assert ''.join(reverse.get(c,c) for c in actual.full)==expected
  assert all(ord(c) in cmap for c in actual.full)
  identity_count+=1
assert identity_count==validation['dynamicIdentityLabels']==17
from linguistic_lint import lint
lint_issues=lint(drafts,load('glossary-v0.6.1.json'),load('annotation-exceptions.json'))
assert not lint_issues,('Annotation/glossary policy breach',lint_issues[:12])
review_counts=Counter(r['status'] for r in reviews.values())
report={'version':spec['version'],'result':'PASS','quests':len(drafts),'dialogueStates':states,'absentOrHeldStates':missing,'changedQuestRecords':len(changed),'unchangedQuestRecords':unchanged,'addedQuestRecords':0,'duplicateQuestIDs':0,'sourceFieldsCheckedForNumericDigitsAndIdentityTokens':checks,'runtimeFieldsDecodedAndGlyphChecked':decoded,'dynamicIdentityLabelsChecked':identity_count,'annotationStructuralIssues':0,'heldFieldsChecked':len(held_checked),'documentedTitleAliasIDs':alias_ids,'unchangedRuntimeFiles':['Renderer.lua','Controls.lua','Bindings.xml'],'changedRuntimeFiles':['QuestBridge.lua'],'bindingActions':6,'LuaVersion':'Lua 5.1','runtimeTests':[s for s in logs if s.startswith('PASS:')],'assistedReviewStatusCounts':dict(review_counts),'reviewCaveat':'Structural and runtime tests do not establish translation meaning, pronunciation quality, or native fluency. Consult per-record source and independent assisted review.','inGame':'not tested','controllerHardware':'not tested','nativeMyanmarReview':'pending','publication':'not published; user verification required'}
(BASE/'test-results.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
