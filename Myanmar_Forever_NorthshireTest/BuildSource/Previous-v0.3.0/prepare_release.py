from pathlib import Path
import json,re,html,copy
import coldridge,dun,loch,classes,captured_drafts,recovered_drafts
BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[1]
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
def dump(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf-8')
FIELDS=('title','detail','objective','progress','complete')
sources=load(BASE/'english.json')
regional={**coldridge.Q,**dun.Q,**loch.Q,**classes.Q}
recovery=load(BASE/'gap-check/recovered.json')
source_by_id={r['id']:r for r in sources}
assert len(recovery)==40 and len(recovered_drafts.Q)==40
for entry in recovery:
    i,f=entry['id'],entry['field']
    if i==1097:continue
    r=source_by_id[i]
    assert not r['english'][f] and not regional[str(i)][f]
    r['english'][f]=entry['english'];r.setdefault('fieldSources',{})[f]=entry
    regional[str(i)][f]=recovered_drafts.Q[(i,f)]
assert len(regional)==104
excluded={5841:'Collector edition gift; outside normal starting route',
    **{i:'Legacy mount exchange with literal [PH] placeholder' for i in (7673,7674,7675,7676)},
    **{i:'Quest level exceeds the planned 1–20 scope' for i in (467,466,86776,256,2500,2501,3182)}}
assert {int(i) for i in regional}|set(excluded)=={r['id'] for r in sources}
glossary={}
for path in [BASE.parent/'four-regions/glossary.txt',BASE/'glossary-extra.txt',BASE/'glossary-aliases.txt']:
    for line in path.read_text(encoding='utf-8').splitlines():
        if line.strip():
            key,value=line.split('|',1);glossary[key]=value
# Full rank + name receives one pronunciation/role annotation.
rank_names={'Mountaineer':'မောင်တီနီယာ','Captain':'ကက်ပ်တင်','Chief Engineer':'ချိဖ် အင်ဂျင်နီယာ',
    'Father':'ဖာသာ','Earthseer':'အာ့သ်ဆီးယား','Foreman':'ဖောမန်','King':'ကင်း',
    'Magistrate':'မက်ဂျစ်စထရိတ်','Pilot':'ပိုင်လော့တ်','Prospector':'ပရော့စ်ပက်တာ',
    'Quarrymaster':'ကွော်ရီမာစတာ','Senator':'ဆဲနေတာ','Explorer':'အိတ်စ်ပလိုရာ'}
for key in list(glossary):
    for rank,pron in rank_names.items():
        if key.startswith(rank+' ') and ' — ' in glossary[key] and "'" not in key:
            glossary[key]=pron+' '+glossary[key];break
pattern=re.compile(r"(?<![A-Za-z])("+'|'.join(re.escape(k) for k in sorted(glossary,key=len,reverse=True))+r")(?![A-Za-z])")
def explain(t):
    if not t:return t
    seen=set()
    def sub(m):
        if m[0] in seen:return m[0]
        seen.add(m[0]);return m[0]+' ('+glossary[m[0]]+')'
    return pattern.sub(sub,t)
marker=lambda t:re.findall(r'<(?:name|class|race)>',t or '',re.I)
drafts=load(BASE.parent/'release-021/drafts.json')
rows=load(BASE.parent/'release-021/worklist.json')
newrows=[];review=[]
for r in sources:
    i=str(r['id']);s=(BASE/'reference'/f'{i}.html').read_text(encoding='utf-8')
    level=re.search(r'<dt>Level</dt><dd>(\d+)</dd>',s)
    row=dict(id=r['id'],en=r['en'],region=r['region'],level=int(level[1]) if level else None,
        englishSource=r['url'],sourceKind=r['sourceKind'],chainEvidence=r['chainText'],
        uaFile=r['ua']['file'] if r['ua'] else None,uaLine=r['ua']['line'] if r['ua'] else None,
        status='needs_review',runtimeEnabled=r['id'] not in excluded,
        absentReferenceFields=[f for f in FIELDS if not r['english'][f]],notes=[],
        fieldSources=r.get('fieldSources',{}),runtimeHeldFields=[])
    if r['id'] in excluded:
        row['status']='excluded_from_1_20';row['notes']=[excluded[r['id']]];newrows.append(row);continue
    q=copy.deepcopy(regional[i])
    for f,t in q.items():
        en=r['english'][f]
        assert bool(t)==bool(en),(i,f,'availability')
        assert marker(t)==marker(en),(i,f,'placeholders')
        assert re.findall(r'\d+',t or '')==re.findall(r'\d+',en or ''),(i,f,'numbers')
        assert '\ufffd' not in (t or '')
        q[f]=explain(t)
    if r['id'] in (170,233):row['notes'].append('Rendered lad/lass alternatives translated with a neutral youthful address.')
    if r['id'] in (257,258):row['notes'].append('Intentional source name suffix ama/ath preserved for this NPC dialogue; not trimmed.')
    if r['id']==3110:row['notes'].append('Public progress source says lass; gender-neutral address used editorially to avoid applying a female capture to all players.')
    row['notes'].append('Regional/class inventory coverage is not proof of current availability for every race or character.')
    assert i not in drafts,('Duplicate prior quest',i)
    drafts[i]=copy.deepcopy(q)
    for (qid,f),reason in recovered_drafts.HOLDS.items():
        if qid==r['id']:
            drafts[i][f]=None;row['runtimeHeldFields'].append(f);row['notes'].append(reason)
    rows.append(row);newrows.append(row);review.append((r,q))
captures=load(BASE.parent/'startup-fix/captures/latest.json')
for i,q in captured_drafts.Q.items():
    q=copy.deepcopy(q)
    en=dict.fromkeys(FIELDS)
    for phase,state in captures[i]['states'].items():
        for f in ('title',phase,'objective') if phase=='detail' else ('title',phase):
            if state.get(f):en[f]=state[f]
    extra=[entry for entry in recovery if entry['id']==int(i)]
    for entry in extra:
        f=entry['field'];assert not en[f];en[f]=entry['english'];q[f]=recovered_drafts.Q[(int(i),f)]
    for f,t in q.items():
        assert bool(t)==bool(en[f]);assert marker(t)==marker(en[f])
        assert re.findall(r'\d+',t or '')==re.findall(r'\d+',en[f] or '')
    drafts[i]=q
    row=dict(id=int(i),en=en['title'],region='Captured Human follow-up',status='needs_review',runtimeEnabled=True,
        englishSource='Local enUS SavedVariables',absentReferenceFields=[f for f in FIELDS if not en[f]],
        fieldSources={e['field']:e for e in extra},
        notes=['Live-captured offer/title/objective; completion recovered from Wowhead Forever. Progress remains unsourced.'])
    rows.append(row);newrows.append(row)
    review.append((dict(id=int(i),en=en['title'],region=row['region'],url='',english=en,sourceKind=row['englishSource'],fieldSources=row['fieldSources']),q))
assert len(drafts)==353 and len(rows)==353
states=sum(bool(q[f]) for q in drafts.values() for f in ('detail','progress','complete'))
manifest=dict(version='0.3.0-beta',runtimeQuestCount=len(drafts),runtimeDialogueStates=states,
    newDwarfGnomeRecords=104,newCapturedHumanRecords=1,excludedInventoryRecords=12,
    newTranslatedFields=sum(bool(v) for _,q in review for v in q.values()),
    absentNewReferenceFields=sum(len(r['absentReferenceFields']) for r in newrows if r['runtimeEnabled']),
    recoveredFields=40,recoveredRuntimeFields=39,runtimeHeldFields=[dict(id=i,field=f,reason=reason) for (i,f),reason in recovered_drafts.HOLDS.items()],
    scope='Quest levels 1–20 in Coldridge Valley, Dun Morogh and Loch Modan; nine separately indexed class introductions. Not a census of all class/profession chains.',
    reviewStatus='Draft; native review and in-game verification pending',sourceDate='2026-10-03')
dump(BASE/'drafts.json',drafts);dump(BASE/'worklist.json',rows);dump(BASE/'release-worklist.json',newrows)
dump(BASE/'catalog-validation.json',manifest);dump(BASE/'new-drafts.json',{str(r['id']):q for r,q in review})
dump(BASE/'english-reviewed.json',[r for r,q in review])
(BASE/'glossary.txt').write_text('\n'.join(k+'|'+v for k,v in sorted(glossary.items())),encoding='utf-8')
e=html.escape
page=['<!doctype html><meta charset="utf-8"><title>MyanmarForever v0.3.0 review</title><style>body{font:17px/1.8 system-ui;max-width:1200px;margin:25px auto;padding:20px}article{border:1px solid #ccc;padding:16px;margin:20px 0}table{border-collapse:collapse;width:100%;table-layout:fixed}th,td{border:1px solid #ddd;padding:12px;vertical-align:top;white-space:pre-wrap;overflow-wrap:anywhere}input{padding:10px;width:90%}</style><h1>v0.3.0 — Dwarf/Gnome draft review</h1>',
    '<p>'+e(manifest['scope'])+'</p><p>104 Dwarf/Gnome records + Elmore’s Task. 12 out-of-scope or special records are excluded. Existing 248 quests retained unchanged.</p>',
    '<p>English/Forever reference text is primary; UA is a secondary cross-check. Blank fields are unsourced, not deliberately omitted translations. Sort order is regional then numeric; source chain links are recorded rather than guessed.</p>',
    '<input placeholder="Search ID or title" oninput="document.querySelectorAll(\'article\').forEach(a=>a.hidden=!a.dataset.find.includes(this.value.toLowerCase()))">']
for r,q in review:
    page.append('<article data-find="'+e((str(r['id'])+' '+r['en']+' '+r['region']).lower(),quote=True)+'"><h2>'+str(r['id'])+' — '+e(r['en'])+'</h2><p>'+e(r['region'])+' · '+e(r['sourceKind'])+'</p>')
    if r.get('url'):page.append('<a href="'+e(r['url'],quote=True)+'">English source</a>')
    page.append('<table><tr><th>English</th><th>Myanmar draft</th></tr>')
    for f in FIELDS:
        evidence=r.get('fieldSources',{}).get(f)
        link='<br><a href="'+e(evidence['url'],quote=True)+'">Recovered English source</a>' if evidence else ''
        held=' [REVIEW ONLY: ambiguous NPC race token]' if (r['id'],f) in recovered_drafts.HOLDS else ''
        page.append('<tr><td>'+e(f+'\n'+(r['english'][f] or '[No approved English text]'))+link+'</td><td lang="my">'+e((q[f] or '[Not translated: no source]')+held)+'</td></tr>')
    page.append('</table></article>')
page.append('<h2>Excluded from this 1–20 release</h2><ul>')
for r in newrows:
    if not r['runtimeEnabled']:page.append('<li>'+e(str(r['id'])+' '+r['en']+' — '+r['notes'][0])+'</li>')
page.append('</ul>')
(BASE/'Dwarf-Gnome-Review.html').write_text('\n'.join(page),encoding='utf-8')
print(json.dumps(manifest,indent=2))
