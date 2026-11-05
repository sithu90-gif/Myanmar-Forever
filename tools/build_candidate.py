"""Stage the released addon, add the reviewed Undead pack, and rebuild as a unit.

The checked-in 0.6.2 addon is a byte-preserved release snapshot. New translations
live outside it. Output must be a new directory; existing builds are never erased.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile
from collections import Counter
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'Myanmar_Forever_NorthshireTest'
PACK=ROOT/'translations/undead-v0.6.3'
FIELDS={'title','detail','objective','progress','complete'}
TOKENS=re.compile(r'<(?:name|class|race|priest/priestess)>',re.I)


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(path,value):
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf8')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def digits(text):
    # Myanmar digits and ASCII digits express the same quantities.
    return Counter(int(n) for n in re.findall(r'\d+',text))


def validate_pack(pack,sources,baseline):
    drafts=pack['drafts']
    assert set(drafts)==set(sources)=={str(r['id']) for r in pack['rows']}
    assert len(pack['rows'])==len(drafts) and not set(drafts)&set(baseline)
    for row in pack['rows']:
        assert row['en']==sources[str(row['id'])]['english']['title']
    holds={(str(h['id']),h['field']) for h in pack['heldFields']}
    audit={str(r['id']):r for r in read(PACK/'review-audit.json')}
    assert set(audit)==set(drafts),'Per-quest source review coverage differs'
    for qid,q in drafts.items():
        assert set(q)==FIELDS
        for field,text in q.items():
            english=sources[qid]['english'][field]
            reviewed=audit[qid]['fields'][field]
            assert reviewed['englishSHA256']==(hashlib.sha256(english.encode()).hexdigest() if english else None),(qid,field,'English review is stale')
            assert reviewed['myanmarSHA256']==(hashlib.sha256(text.encode()).hexdigest() if text else None),(qid,field,'Myanmar review is stale')
            if (qid,field) in holds:
                assert english and text is None
            elif english:
                assert text,(qid,field,'Missing translation')
            else:
                assert text is None,(qid,field,'Invented state')
            if text:
                assert Counter(TOKENS.findall(text))==Counter(TOKENS.findall(english)),(qid,field,'Changed placeholder')
                assert digits(text)==digits(english),(qid,field,'Changed digit quantity')
                assert not re.search(r'[\u0400-\u04ff\ufffd\ue000-\uf8ff]',text)
    sys.path.insert(0,str(BASE/'BuildSource'))
    from linguistic_lint import lint
    issues=lint(drafts,pack['pronunciations'],pack['annotationExceptions'])
    assert not issues,issues
    assert not set(drafts)&{str(q['id']) for q in pack['excludedQuestIDs']}


def verify_runtime(addon,pack,base_drafts):
    from fontTools.ttLib import TTFont
    from lupa.lua51 import LuaRuntime
    data=read(addon/'BuildSource/drafts.json')
    assert all(data[qid]==q for qid,q in base_drafts.items()),'Baseline translations changed'
    validation=read(addon/'BuildSource/validation.json')
    lua=LuaRuntime(unpack_returned_tuples=True,register_eval=False,register_builtins=False)
    logs=[]
    lua.globals().print=lambda *args:logs.append(' '.join(map(str,args)))
    lua.globals().ADDON_DIR=str(addon)
    states=sum(bool(q[f]) for q in data.values() for f in ('detail','progress','complete'))
    lua.globals().EXPECTED_QUESTS=len(data)
    lua.globals().EXPECTED_STATES=states
    lua.globals().EXPECTED_MISSING=3*len(data)-states
    xml=ET.parse(addon/'Bindings.xml').getroot()
    lua.globals().BINDING_ACTIONS=lua.table_from([(node.text or '').strip() for node in xml])
    lua.execute((addon/'BuildSource/tests.lua').read_text(encoding='utf8')+'\n'+(addon/'BuildSource/term_tests.lua').read_text(encoding='utf8'))
    catalog=lua.table()
    lua.execute((addon/'Catalogs/Northshire.lua').read_text(encoding='ascii'),'Myanmar_Forever_NorthshireTest',catalog)
    mapping=read(addon/'BuildSource/clusters.json')['map']
    reverse={chr(v):k for k,v in mapping.items()}
    cmap=TTFont(addon/'fonts/NorthshireShaped.ttf').getBestCmap()
    decoded=0
    for qid,q in data.items():
        assert catalog.quests[int(qid)] is not None
        for field,text in q.items():
            actual=catalog.quests[int(qid)][field]
            if text is None:
                assert actual is None,(qid,field,'Unavailable state enabled')
            else:
                assert ''.join(reverse.get(c,c) for c in actual)==text,(qid,field,'Round trip')
                assert all(ord(c) in cmap for c in actual if c not in '\n\r\t'),(qid,field,'Missing glyph')
                decoded+=1
    # Test the actual first-introduction module against the newly added fields,
    # including uppercase markers and a held Warlock state.
    lua.execute((addon/'TermIntroductions.lua').read_text(encoding='utf8'),'Myanmar_Forever_NorthshireTest',catalog)
    lua.globals().NEW_CATALOG=catalog
    lua.execute('''
      local A=NEW_CATALOG
      MMNorthshireTermSeen=nil
      local identities={name='Player%Name',class=A.identityLabels.class.WARRIOR,race=A.identityLabels.race.Scourge}
      local function prepare(id,field)
        local text=A.quests[id][field]
        assert(text, 'Expected a translated field')
        local view=A.TermIntroductions.Prepare(id,field,true,{{field=field,text=text}},identities)
        return view
      end
      for _,id in ipairs({3901,380,382}) do
        local view=prepare(id,'detail')
        assert(view[1]:find('Player%Name',1,true),'Uppercase name marker did not expand')
        assert(not view[1]:find('<[Nn]ame>'),'Unexpanded name marker')
      end
      local view=prepare(98389,'detail')
      assert(view[1]:find('Warrior',1,true) and not view[1]:find('<Class>',1,true),'Uppercase class marker did not expand')
      assert(A.quests[3099].progress==nil,'Unverified gender branch must stay held')
      assert(A.quests[89301]==nil,'Unverified old Paladin ID must remain excluded')
    ''')
    # Every static/dynamic short and introduction label uses the rebuilt font.
    labels=0
    for _,record in catalog.termGlossary.items():
        for key in ('short','intro'):
            assert all(ord(c) in cmap for c in record[key])
            labels+=1
    for _,kind in catalog.identityLabels.items():
        for _,record in kind.items():
            for key in ('full','intro'):
                assert all(ord(c) in cmap for c in record[key])
                labels+=1
    assert decoded==validation['translatedFields']
    assert states==validation['runtimeDialogueStates']
    assert validation['version']==pack['version']
    assert sha(addon/'fonts/NorthshireShaped.ttf')==validation['fontSHA256']
    assert sha(addon/'Catalogs/Northshire.lua')==validation['catalogSHA256']
    for name in ('Controls.lua','Bindings.xml','QuestBridge.lua','Renderer.lua','TermIntroductions.lua'):
        assert sha(addon/name)==sha(BASE/name),(name,'Unexpected runtime code change')
    return {'version':pack['version'],'result':'PASS','baselineQuestRecordsPreserved':len(base_drafts),
            'addedQuestRecords':len(pack['drafts']),'addedTranslatedFields':sum(bool(t) for q in pack['drafts'].values() for t in q.values()),
            'totalQuestRecords':len(data),'translatedFields':decoded,'availableDialogueStates':states,
            'absentOrHeldDialogueStates':3*len(data)-states,'newHeldFields':pack['heldFields'],
            'newAbsentSourceFields':sum(v is None for q in read(PACK/'english-sources.json').values() for v in q['english'].values()),
            'fontLabelsChecked':labels,'fontSHA256':validation['fontSHA256'],'catalogSHA256':validation['catalogSHA256'],
            'luaRegressionGroups':[s for s in logs if s.startswith('PASS:')],
            'newQuestMarkerAndHeldStateChecks':'PASS','nativeMyanmarProofreading':'pending','currentLiveClient':'not tested',
            'controllerHardware':'not tested','independentAssistedReview':'not performed'}


def build(output):
    pack=read(PACK/'pack.json')
    sources=read(PACK/'english-sources.json')
    baseline=read(BASE/'BuildSource/drafts.json')
    validate_pack(pack,sources,baseline)
    output=output.resolve()
    if output.exists():
        raise FileExistsError(f'Choose a new output directory: {output}')
    output.mkdir(parents=True)
    addon=output/BASE.name
    shutil.copytree(BASE,addon,ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
    build_source=addon/'BuildSource'
    write(build_source/'drafts.json',baseline|pack['drafts'])
    write(build_source/'worklist.json',read(BASE/'BuildSource/worklist.json')+pack['rows'])
    builder=build_source/'build.py'
    text=builder.read_text(encoding='utf8')
    old="VERSION='0.6.2-beta-candidate'"
    assert text.count(old)==1
    builder.write_text(text.replace(old,"VERSION='"+pack['version']+"'"),encoding='utf8')
    subprocess.run([sys.executable,'-X','utf8',str(builder)],check=True)
    for toc in addon.glob('*.toc'):
        toc.write_text(toc.read_text(encoding='utf8').replace('## Version: 0.6.2-beta-candidate','## Version: '+pack['version']),encoding='utf8')
    report=verify_runtime(addon,pack,baseline)
    write(output/'validation.json',report)
    # The install ZIP contains runtime, licences and current candidate notes.
    # Historical BuildSource audits remain in GitHub's preserved release folder;
    # they do not describe the combined candidate and are not shipped as its audit.
    notes=(PACK/'RELEASE_NOTES.md').read_text(encoding='utf8')
    (addon/'RELEASE_NOTES.md').write_text(notes,encoding='utf8')
    credits=addon/'CREDITS.txt'
    credits.write_text(credits.read_text(encoding='utf8')+'\n\nUndead starter addition, v0.6.3 candidate (2026-11-05): 24 English-source-based Myanmar quest records. Public English references: 60.tools Forever, with Wowhead Forever comparison; UA_Forever 0.23.0 is secondary identity/state evidence. Per-field sources and assisted review records: https://github.com/sithu90-gif/Myanmar-Forever/tree/main/translations/undead-v0.6.3\n',encoding='utf8')
    (addon/'INSTALL.txt').write_text('MyanmarForever '+pack['version']+'\n\nFully exit WoW. Replace the complete Myanmar_Forever_NorthshireTest folder in Interface/AddOns. Keep the folder name. Do not mix font and catalog versions. Enable MyanmarForever. Commands: /mmforever and /mmnorth.\n\n688 quest IDs; 24 new Deathknell/Brill starter records. This candidate has automated validation; current live-client/controller checks and full native proofreading remain pending.\n',encoding='utf8')
    archive=output/('MyanmarForever_v'+pack['version']+'.zip')
    names=['Bindings.xml','Controls.lua','QuestBridge.lua','Renderer.lua','TermIntroductions.lua','CREDITS.txt','LICENSE.txt','INSTALL.txt','RELEASE_NOTES.md','TERM-EXPLANATION-GUIDE.txt']
    files=[addon/n for n in names]+list(addon.glob('*.toc'))+[p for directory in ('Catalogs','fonts') for p in (addon/directory).rglob('*') if p.is_file()]
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for path in sorted(files):
            z.write(path,path.relative_to(output).as_posix())
    report['zip']={'name':archive.name,'sha256':sha(archive),'bytes':archive.stat().st_size}
    write(output/'validation.json',report)
    print(json.dumps(report,indent=2))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True,help='New directory for the staged addon, ZIP and validation')
    build(parser.parse_args().output)
