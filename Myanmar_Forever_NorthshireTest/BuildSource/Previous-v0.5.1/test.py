"""Catalog-wide source integrity and Lua 5.1 WoW API mock checks; no live-client claim."""
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
sources=load('source-audit-v0.5.1.json');spec=load('release-spec.json')
baseline=load('baseline-v0.5.0.json');validation=load('validation.json')
changes=load('translation-changes-v0.5.1.json');audit=load('audit-summary-v0.5.1.json')
assert len(drafts)==len(rows)==len(sources)==spec['quests']==610
assert set(drafts)=={str(r['id']) for r in rows}=={str(s['id']) for s in sources}==set(baseline['questSHA256'])
changed={str(c['id']):c for c in changes}
assert len(changed)==len(changes)==spec['changedQuestRecords']==spec['changedTranslationFields']==8
unchanged=0
for qid,previous in baseline['questSHA256'].items():
 if qid in changed:
  change=changed[qid]
  assert previous==change['beforeQuestSHA256']
  assert digest(drafts[qid])==change['afterQuestSHA256'],('Unexpected edited record',qid)
  assert drafts[qid][change['field']]==change['after']
  restored=drafts[qid].copy();restored[change['field']]=change['before']
  assert digest(restored)==previous,('Unreported field changed',qid)
 else:
  assert digest(drafts[qid])==previous,('Unreported quest changed',qid)
  unchanged+=1
assert unchanged==spec['unchangedQuestRecords']==602
for file,expected in baseline['unchangedRuntimeFiles'].items():
 assert hashlib.sha256((ADDON/file).read_bytes()).hexdigest()==expected,('Unexpected runtime change',file)

holds={(s['id'],s['field']) for s in spec['heldFields']}
assert holds=={(98021,'complete'),(95213,'complete'),(3118,'progress'),(842,'complete'),(3083,'progress')}
checks=0;held_checked=set();absent_fields=0
for source in sources:
 q=drafts[str(source['id'])]
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
assert held_checked==holds and absent_fields==audit['absentReferenceFields']==161
assert checks==spec['translatedFields']==audit['enabledFieldsChecked']==2884
states=sum(q[f] is not None for q in drafts.values() for f in ('detail','progress','complete'))
assert states==spec['dialogueStates']==1676
assert 3*len(drafts)-states==spec['absentOrHeldStates']==154
assert validation['version']==spec['version']==audit['version']=='0.5.1-beta'
assert validation['runtimeQuestCount']==len(drafts) and validation['runtimeDialogueStates']==states
assert not any(str(qid) in drafts for qid in (5843,7664,7665))
for file,key in [('fonts/NorthshireShaped.ttf','fontSHA256'),('Catalogs/Northshire.lua','catalogSHA256')]:
 assert hashlib.sha256((ADDON/file).read_bytes()).hexdigest()==validation[key],('Font/catalog mismatch',file)

xml=ET.parse(ADDON/'Bindings.xml').getroot();assert xml.tag=='Bindings' and len(xml)==6
assert len({node.attrib['name'] for node in xml})==6
for toc in ADDON.glob('*.toc'):
 text=toc.read_text();assert '## Version: 0.5.1-beta' in text and '## Interface: 16001' in text
 assert '## SavedVariables: MMNorthshireSettings, MMNorthshireCaptures' in text
 files=[line.strip().replace('\\','/') for line in text.splitlines() if line.strip() and not line.startswith('#')]
 assert files==['Catalogs/Northshire.lua','Renderer.lua','QuestBridge.lua','Controls.lua']
 assert all((ADDON/file).is_file() for file in files)
lua=LuaRuntime(unpack_returned_tuples=True)
assert lua.eval('_VERSION')=='Lua 5.1'
logs=[];lua.globals().print=lambda *args:logs.append(' '.join(map(str,args)))
lua.globals().ADDON_DIR=str(ADDON)
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
 if aliases:
  assert aliases==["Captain Sanders' Hidden Treasure"];alias_ids.append(row['id'])
assert sorted(alias_ids)==[138,139,140]
assert decoded==checks==validation['translatedFields']==2884
report={'version':spec['version'],'result':'PASS','quests':len(drafts),'dialogueStates':states,'absentOrHeldStates':154,'priorQuestRecordsUnchanged':unchanged,'questRecordsWithReviewedEdits':len(changed),'translationFieldsChanged':len(changes),'newQuestRecords':0,'sourceFieldsCheckedForNumericDigitsAndIdentityTokens':checks,'runtimeFieldsDecodedAndGlyphChecked':decoded,'heldFieldsChecked':len(held_checked),'documentedTitleAliasIDs':alias_ids,'priorRuntimeFilesUnchanged':list(baseline['unchangedRuntimeFiles']),'bindingActions':6,'LuaVersion':'Lua 5.1','runtimeTests':[s for s in logs if s.startswith('PASS:')],'inGame':'not tested','controllerHardware':'not tested','nativeMyanmarReview':'pending'}
(BASE/'test-results.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
