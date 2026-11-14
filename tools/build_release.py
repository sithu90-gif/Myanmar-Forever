"""Compose source-reviewed translation packs into a manifest-selected release.

The checked-in 0.6.2 folder remains a released snapshot. Release composition is
explicit: additions cannot replace an existing quest. Overrides fill unavailable
fields, correct reviewed text, or disable an unsupported state under an exact prior
hash and documented hold. Private
SavedVariables are never packaged.
"""
from __future__ import annotations

import argparse
from collections import Counter
from datetime import date
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'Myanmar_Forever_NorthshireTest'
FIELDS={'title','detail','objective','progress','complete'}
TOKENS=re.compile(r'<(?:name|class|race|priest/priestess)>',re.I)

def release_version(manifest):
    version=manifest['version']
    if not isinstance(version,str) or not re.fullmatch(r'(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)',version):
        raise ValueError('Manifest version must be a stable numeric major.minor.patch release')
    release_date=manifest['date']
    if not isinstance(release_date,str) or date.fromisoformat(release_date).isoformat()!=release_date:
        raise ValueError('Manifest date must use YYYY-MM-DD')
    return version


def release_document(relative):
    path=(ROOT/relative).resolve()
    if not path.is_relative_to((ROOT/'releases').resolve()):
        raise ValueError('Release documents must be inside releases/')
    if not path.is_file():
        raise FileNotFoundError(f'Missing release document: {path}')
    return path


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(path,value):
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf8')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def text_sha(text):
    return hashlib.sha256(text.encode('utf8')).hexdigest() if text is not None else None


def validate_fields(qid,fields,source,review,holds):
    for field,text in fields.items():
        assert field in FIELDS,(qid,'Unexpected field',field)
        english=source['english'].get(field)
        evidence=review['fields'][field]
        assert evidence['englishSHA256']==text_sha(english),(qid,field,'English review stale')
        assert evidence['myanmarSHA256']==text_sha(text),(qid,field,'Myanmar review stale')
        if (qid,field) in holds:
            assert english and text is None,(qid,field,'Invalid hold')
        elif english:
            assert text,(qid,field,'Missing translation')
        else:
            assert text is None,(qid,field,'Invented source state')
        if text:
            assert Counter(TOKENS.findall(text))==Counter(TOKENS.findall(english)),(qid,field,'Changed placeholder')
            assert Counter(map(int,re.findall(r'\d+',text)))==Counter(map(int,re.findall(r'\d+',english))),(qid,field,'Changed quantity')
            assert not re.search(r'[\u0400-\u04ff\ufffd\ue000-\uf8ff]',text),(qid,field,'Encoding/script issue')


def compose(manifest):
    baseline=read(BASE/'BuildSource/drafts.json')
    drafts=json.loads(json.dumps(baseline))
    rows=read(BASE/'BuildSource/worklist.json')
    pack_reports=[];overrides={};additions={};all_holds=[]
    sys.path.insert(0,str(BASE/'BuildSource'))
    from linguistic_lint import lint
    for relative in manifest['packs']:
        directory=(ROOT/relative).resolve()
        assert directory.is_relative_to(ROOT)
        pack=read(directory/'pack.json')
        sources=read(directory/'english-sources.json')
        reviews={str(r['id']):r for r in read(directory/'review-audit.json')}
        added=pack.get('drafts',{})
        changed=pack.get('overrides',{})
        prior_hashes=pack.get('overridePriorSHA256',{})
        for qid,fields in prior_hashes.items():
            assert fields and fields.keys()<=changed.get(qid,{}).keys(),(qid,'Unused prior override hash')
        assert not set(added)&set(drafts),('Duplicate/addition collision',relative,set(added)&set(drafts))
        assert len(pack['rows'])==len(added)==len({str(r['id']) for r in pack['rows']})
        assert set(added)=={str(r['id']) for r in pack['rows']}
        assert set(added)|set(changed)==set(sources)==set(reviews),('Missing source/review record',relative)
        holds={(str(h['id']),h['field']) for h in pack.get('heldFields',[])}
        hold_reasons={(str(h['id']),h['field']):h.get('reason') for h in pack.get('heldFields',[])}
        for row in pack['rows']:
            assert row['en']==sources[str(row['id'])]['english']['title']
        for qid,q in added.items():
            assert set(q)==FIELDS,(qid,'Incomplete field schema')
            validate_fields(qid,q,sources[qid],reviews[qid],holds)
        for qid,fields in changed.items():
            assert qid in drafts and fields,(qid,'Invalid field override')
            assert sources[qid]['english']['title']==next(r['en'] for r in rows if str(r['id'])==qid)
            for field,text in fields.items():
                assert (qid,field) not in overrides,(qid,field,'Duplicate override')
                assert field in drafts[qid],(qid,field,'Invalid override field')
                previous=drafts[qid][field]
                if text is None:
                    assert previous is not None and (qid,field) in holds,(qid,field,'Disabling requires an enabled prior field and documented hold')
                    reason=hold_reasons.get((qid,field))
                    assert isinstance(reason,str) and reason.strip(),(qid,field,'Disabling requires a nonblank hold reason')
                else:
                    assert text,(qid,field,'Invalid override field')
                expected_hash=prior_hashes.get(qid,{}).get(field)
                if previous is None:
                    assert expected_hash is None,(qid,field,'Expected prior translation is missing')
                else:
                    assert expected_hash==text_sha(previous),(qid,field,'Override requires the exact prior translation hash')
                overrides[(qid,field)]=text
            validate_fields(qid,fields,sources[qid],reviews[qid],holds)
        issues=lint(added|changed,pack['pronunciations'],pack.get('annotationExceptions',{}))
        assert not issues,(relative,issues[:20])
        assert not set(added)&{str(q['id']) for q in pack.get('excludedQuestIDs',[])}
        drafts.update(added);additions.update(added);rows.extend(pack['rows'])
        for qid,fields in changed.items():drafts[qid].update(fields)
        all_holds.extend(pack.get('heldFields',[]))
        pack_reports.append({'path':relative,'questAdditions':len(added),'fieldAdditions':sum(bool(t) for q in added.values() for t in q.values()),'fieldOverrides':sum(len(q) for q in changed.values()),'packSHA256':sha(directory/'pack.json')})
    assert len(rows)==len(drafts)==len({r['id'] for r in rows})
    for qid,q in baseline.items():
        for field,text in q.items():
            assert drafts[qid][field]==overrides.get((qid,field),text),(qid,field,'Unexpected baseline edit')
    if manifest.get('expectedSkyborneQuestIDs'):
        inventory=read(ROOT/'translations/skyborne-inventory-v1.json')
        expected=set(map(str,inventory['includedQuestIDs']))
        assert len(expected)==manifest['expectedSkyborneQuestIDs']
        assert expected<=set(additions),'Skyborne starter inventory is incomplete'
        assert not set(map(str,(q['id'] for q in inventory['exclusions'])))&set(drafts),'Unused/disabled Skyborne record enabled'
    if manifest.get('expectedNewLiveCaptureQuestIDs'):
        captured=next(r for r in pack_reports if r['path']=='translations/live-fixes-v1')
        assert captured['questAdditions']==manifest['expectedNewLiveCaptureQuestIDs']
    if manifest.get('expectedUndeadTirisfalQuestIDs'):
        directory=ROOT/'translations/undead-tirisfal-v1.1.0'
        inventory=read(directory/'inventory.json')
        expected=set(map(str,inventory['includedQuestIDs']))
        pack=read(directory/'pack.json')
        assert len(expected)==inventory['includedCount']==manifest['expectedUndeadTirisfalQuestIDs']
        assert expected==set(pack['drafts']),'Tirisfal inventory differs from the translated pack'
        sources=read(directory/'english-sources.json')
        counts={field:sum(bool(sources[qid]['english'].get(field)) for qid in expected) for field in FIELDS}
        assert counts==inventory['englishFieldCounts'],'Tirisfal English inventory is stale'
        assert sum(counts.values())==inventory['englishFieldsTotal']
    return drafts,rows,baseline,overrides,pack_reports,all_holds


def classify_source_holds(drafts, recorded_holds):
    # Keep the historical reason as evidence, but a later reviewed field override
    # must no longer be reported as an active runtime hold.
    active=[];resolved=[]
    for hold in recorded_holds:
        target=resolved if drafts.get(str(hold['id']),{}).get(hold['field']) else active
        target.append(hold)
    return active,resolved


def reviewed_hold_test_source(source_text, drafts):
    cases=[
        ('98021','complete',
         "command('98021 complete');assert(not A.window:IsShown(),'Unverified elf-specific completion released')",
         "command('98021 complete');assert(A.window:IsShown(),'Source-reviewed Skyborne completion missing')"),
        ('97924','complete',
         "command('97924 complete');assert(not A.window:IsShown())",
         "command('97924 complete');assert(A.window:IsShown(),'Source-reviewed camping completion missing')"),
        ('97279','progress',
         "assert(not A.window:IsShown() and MMNorthshireCaptures[97279].states.progress,'Absent custom progress fallback failed')",
         "assert(A.window:IsShown() and MMNorthshireCaptures[97279].states.progress,'Source-reviewed custom progress or capture missing')")]
    for qid,field,old,new in cases:
        if drafts.get(qid,{}).get(field):
            assert source_text.count(old)==1, 'Historical source-state assertion changed; review the test update'
            source_text=source_text.replace(old,new)
    if drafts.get('98021',{}).get('complete'):
        source_text=source_text.replace('unverified elf branch and placeholder held.','reviewed source holds and placeholder protections.')
    return source_text



def reviewed_term_test_source(source_text, drafts):
    if drafts.get('98021',{}).get('complete'):
        assert not drafts.get('842',{}).get('complete'), 'Replacement held-view probe requires a still-held source state'
        old="liveShow(98021,'QUEST_COMPLETE');assert(not A.window:IsShown());emptySeen()"
        new="liveShow(842,'QUEST_COMPLETE');assert(not A.window:IsShown());emptySeen()"
        assert source_text.count(old)==1, 'Historical held-view probe changed; review the test update'
        source_text=source_text.replace(old,new)
    return source_text


def patch_runtime(addon):
    bridge=addon/'QuestBridge.lua'
    text=bridge.read_text(encoding='utf8')
    anchor='  local record=token and labels[token]\n'
    assert text.count(anchor)==1
    # Current Forever IDs are documented by the installed QuestieDB race-mask
    # table (95 Alliance, 96 Horde). Unknown future IDs retain literal fallback.
    text=text.replace(anchor,'''  local record=token and labels[token]
  if not record and kind=="race" then
    local raceID=read(function() local _,_,id=fn("player"); return id end)
    if raceID==95 or raceID==96 then record=labels.Skyborne end
    if not record and (raw=="High Order Skyborne" or raw=="Windshaper Skyborne") then record=labels.Skyborne end
  end
''')
    text=text.replace('Myanmar | Draft translation','Myanmar | Translation')
    bridge.write_text(text,encoding='utf8')
    renderer=addon/'Renderer.lua'
    renderer.write_text(renderer.read_text(encoding='utf8').replace('Myanmar font loaded | Draft quest catalog','Myanmar font loaded | Quest catalog'),encoding='utf8')


def add_skyborne_identity(build_source,version):
    identities=read(build_source/'identity-glossary.json')
    identities['race']['Skyborne']={'en':'Skyborne','pronunciation':'စကိုင်းဘောန်း'}
    write(build_source/'identity-glossary.json',identities)
    terms=read(build_source/'term-glossary-v0.6.2.json')
    terms['terms'].append({'key':'race.skyborne','en':'Skyborne','pronunciation':'စကိုင်းဘောန်း','meaning':'ကောင်းကင်ဒေသမှ အယ်လ်ဖ်မျိုးနွယ်','category':'race','aliases':[]})
    terms['version']=version
    terms['scope']='46 short introduction meanings, including the Skyborne race; original term records preserved.'
    write(build_source/'term-glossary-v0.6.2.json',terms)


def verify(addon,drafts,baseline,overrides,manifest,pack_reports,holds):
    version=release_version(manifest)
    from fontTools.ttLib import TTFont
    from lupa.lua51 import LuaRuntime
    assert read(addon/'BuildSource/drafts.json')==drafts
    v=read(addon/'BuildSource/validation.json')
    states=sum(bool(q[f]) for q in drafts.values() for f in ('detail','progress','complete'))
    total_fields=sum(bool(t) for q in drafts.values() for t in q.values())
    lua=LuaRuntime(unpack_returned_tuples=True,register_eval=False,register_builtins=False)
    lua.globals().ADDON_DIR=str(addon)
    lua.globals().EXPECTED_QUESTS=len(drafts);lua.globals().EXPECTED_STATES=states;lua.globals().EXPECTED_MISSING=3*len(drafts)-states
    lua.globals().EXPECTED_DISABLED_FIELDS=lua.table_from({f'{qid}.{field}':True for (qid,field),text in overrides.items() if text is None})
    bindings=ET.parse(addon/'Bindings.xml').getroot()
    lua.globals().BINDING_ACTIONS=lua.table_from([(b.text or '').strip() for b in bindings])
    logs=[];lua.globals().print=lambda *a:logs.append(' '.join(map(str,a)))
    scripts=[addon/'BuildSource/tests.lua',addon/'BuildSource/term_tests.lua',ROOT/'tools/release_tests.lua']
    lua.execute('\n'.join(p.read_text(encoding='utf8') for p in scripts))
    a=lua.table();lua.execute((addon/'Catalogs/Northshire.lua').read_text(encoding='ascii'),BASE.name,a)
    reverse={chr(v):k for k,v in read(addon/'BuildSource/clusters.json')['map'].items()}
    cmap=TTFont(addon/'fonts/NorthshireShaped.ttf').getBestCmap()
    count=0
    for qid,q in drafts.items():
        assert a.quests[int(qid)] is not None
        for field,text in q.items():
            actual=a.quests[int(qid)][field]
            if text is None:assert actual is None,(qid,field,'Missing state enabled')
            else:
                assert ''.join(reverse.get(c,c) for c in actual)==text,(qid,field,'Round trip')
                assert all(ord(c) in cmap for c in actual if c not in '\n\r\t'),(qid,field,'Missing glyph')
                count+=1
    for _,kind in a.identityLabels.items():
        for _,record in kind.items():
            for field in ('full','intro'):assert all(ord(c) in cmap for c in record[field])
    for _,record in a.termGlossary.items():
        for field in ('short','intro'):assert all(ord(c) in cmap for c in record[field])
    assert count==total_fields==v['translatedFields']
    assert v['version']==version and v['runtimeQuestCount']==len(drafts) and v['runtimeDialogueStates']==states
    assert read(addon/'BuildSource/release-spec.json')['version']==version
    assert read(addon/'BuildSource/term-glossary-v0.6.2.json')['version']==version
    assert v['dynamicIdentityLabels']==18 and v['firstIntroductionTerms']==46
    for file,key in [('fonts/NorthshireShaped.ttf','fontSHA256'),('Catalogs/Northshire.lua','catalogSHA256')]:assert sha(addon/file)==v[key]
    for name in ('Controls.lua','Bindings.xml','TermIntroductions.lua'):assert sha(addon/name)==sha(BASE/name)
    for toc in addon.glob('*.toc'):
        text=toc.read_text(encoding='utf8');assert f'## Version: {version}' in text.splitlines() and '## Title: MyanmarForever' in text.splitlines() and 'beta' not in text.lower() and 'candidate' not in text.lower()
    baseline_holds=read(BASE/'BuildSource/release-spec.json')['heldFields']
    active_holds,resolved_holds=classify_source_holds(drafts,baseline_holds+holds)
    active_pack_holds,_=classify_source_holds(drafts,holds)
    report={'version':version,'result':'PASS','date':manifest['date'],'questIDs':len(drafts),'translatedFields':count,'dialogueStates':states,'absentOrHeldDialogueStates':3*len(drafts)-states,'preservedBaselineQuestRecords':len(baseline),'baselineFieldOverrides':[{'id':int(k[0]),'field':k[1]} for k in overrides],'packs':pack_reports,'heldFields':active_holds,'resolvedHeldFields':resolved_holds,'addedHeldFields':active_pack_holds,'fontSHA256':v['fontSHA256'],'catalogSHA256':v['catalogSHA256'],'dynamicIdentityLabels':18,'firstIntroductionTerms':46,'luaRegressionGroups':[s.replace('17 preshaped','18 preshaped').replace('all 17 class/race','all 18 class/race') for s in logs if s.startswith('PASS:')],'capture':'Automatic local capture preserved; missing live-captured states checked','nativeMyanmarProofreading':'pending','currentLiveSkyborneClient':'not tested','controllerHardware':'not tested'}
    if 'translations/undead-tirisfal-v1.1.0' in manifest['packs']:
        report['currentLiveUndeadClient']='not tested'
    return report


def build(output,manifest_path):
    manifest=read(manifest_path)
    version=release_version(manifest)
    notes=release_document(f'releases/{version}-NOTES.md')
    terms=release_document(manifest.get('termsGuide',f'releases/{version}-TERMS.txt'))
    drafts,rows,baseline,overrides,pack_reports,holds=compose(manifest)
    output=output.resolve()
    assert not output.is_relative_to(BASE.resolve()),'Output cannot be inside the preserved release snapshot'
    assert not output.is_relative_to((ROOT/'translations').resolve()),'Output cannot be inside preserved translation sources'
    if output.exists():raise FileExistsError(f'Choose a new output directory: {output}')
    output.mkdir(parents=True)
    addon=output/BASE.name
    shutil.copytree(BASE,addon,ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
    source=addon/'BuildSource'
    write(source/'drafts.json',drafts);write(source/'worklist.json',rows)
    add_skyborne_identity(source,version)
    spec=read(source/'release-spec.json')
    spec['version']=version
    write(source/'release-spec.json',spec)
    builder=source/'build.py'
    text=builder.read_text(encoding='utf8');old="VERSION='0.6.2-beta-candidate'";assert text.count(old)==1
    builder.write_text(text.replace(old,f'VERSION={version!r}'),encoding='utf8')
    subprocess.run([sys.executable,'-X','utf8',str(builder)],check=True)
    patch_runtime(addon)
    snapshot_tests=source/'tests.lua'
    snapshot_tests.write_text(reviewed_hold_test_source(snapshot_tests.read_text(encoding='utf8'),drafts),encoding='utf8')
    term_tests=source/'term_tests.lua'
    term_tests.write_text(reviewed_term_test_source(term_tests.read_text(encoding='utf8'),drafts),encoding='utf8')
    for toc in addon.glob('*.toc'):
        text=toc.read_text(encoding='utf8');old='## Version: 0.6.2-beta-candidate';assert text.splitlines().count(old)==1
        text=text.replace(old,f'## Version: {version}').replace('Myanmar quest drafts','Myanmar quest translations')
        toc.write_text(text,encoding='utf8')
    report=verify(addon,drafts,baseline,overrides,manifest,pack_reports,holds)
    (addon/'RELEASE_NOTES.md').write_text(notes.read_text(encoding='utf8'),encoding='utf8')
    (addon/'TERM-EXPLANATION-GUIDE.txt').write_text(terms.read_text(encoding='utf8'),encoding='utf8')
    (addon/'INSTALL.txt').write_text(f'MyanmarForever {version}\n\nFully exit WoW. Back up your current addon and SavedVariables, then replace the complete Myanmar_Forever_NorthshireTest folder in Interface/AddOns. Keep the folder name and do not mix font/catalog versions. Enable MyanmarForever. Commands: /mmforever, /mmnorth.\n\nAutomatic local quest capture is enabled. Open NPC offer/progress/completion dialogue; /reload or logout saves captures to disk. No automatic network upload or live machine translation occurs.\n\nCoverage: '+str(report['questIDs'])+' quest IDs; '+str(report['translatedFields'])+' translated fields. Version 1 is a release number, not a claim that every quest or live branch is complete. Native proofreading and current live/controller review remain pending.\n',encoding='utf8')
    credits=addon/'CREDITS.txt'
    credits.write_text(credits.read_text(encoding='utf8')+f'\n\nMyanmarForever {version} starter update, {manifest["date"]}. English source evidence and assisted Myanmar review are maintained at https://github.com/sithu90-gif/Myanmar-Forever/tree/main/translations . UA_Forever is secondary identity/state evidence. Sanitized live captures were compared with public English; private SavedVariables are not distributed.\n',encoding='utf8')
    archive=output/f'MyanmarForever_v{version}.zip'
    names=['Bindings.xml','Controls.lua','QuestBridge.lua','Renderer.lua','TermIntroductions.lua','CREDITS.txt','LICENSE.txt','INSTALL.txt','RELEASE_NOTES.md','TERM-EXPLANATION-GUIDE.txt']
    files=[addon/n for n in names]+list(addon.glob('*.toc'))+[p for d in ('Catalogs','fonts') for p in (addon/d).rglob('*') if p.is_file()]
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(files):z.write(p,p.relative_to(output).as_posix())
    with zipfile.ZipFile(archive) as z:assert z.testzip() is None
    report['zip']={'name':archive.name,'bytes':archive.stat().st_size,'sha256':sha(archive)}
    write(output/'validation.json',report)
    print(json.dumps(report,indent=2))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--manifest',type=Path,default=ROOT/'releases/1.0.0.json')
    args=parser.parse_args();build(args.output,args.manifest)
