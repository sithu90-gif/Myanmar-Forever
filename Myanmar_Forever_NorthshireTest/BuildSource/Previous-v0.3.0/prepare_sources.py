import json,re,html
from pathlib import Path
BASE=Path(__file__).resolve().parent
FIELDS=['title','detail','objective','progress','complete']
def clean(s):
    s=re.sub(r'<br\s*/?>','\n',s,flags=re.I)
    return html.unescape(re.sub('<[^>]*>','',s)).replace('\r','').strip()
ua={}
for p in (BASE.parents[1]/'inspection/ua012/UA_Forever/entries/forever/catalogs/quests').glob('*.lua'):
    s=p.read_text(encoding='utf-8-sig')
    for m in re.finditer(r'^\[(\d+)\] = \{ en="([^"]+)",([\s\S]*?)^\},',s,re.M):
        vals=[None if v[0]=='nil' else v[2] for v in re.finditer(r'\[(=*)\[([\s\S]*?)\]\1\]|\bnil\b',m[3])]
        assert len(vals)==5, (str(p),m[1],len(vals))
        ua[int(m[1])]={'file':str(p.relative_to(BASE.parents[1])),'line':s[:m.start()].count('\n')+1,'fields':dict(zip(FIELDS,vals))}
rows=[]
for r in json.loads((BASE/'inventory.json').read_text(encoding='utf-8-sig')):
    path=BASE/'reference'/f"{r['id']}.html"
    if not path.exists(): continue
    s=path.read_text(encoding='utf-8'); s=s[s.index('<h1'):s.index('</main>')]
    fields=dict.fromkeys(FIELDS);fields['title']=clean(re.search(r'<h1>(.*?)</h1>',s,re.S)[1])
    lead=re.search(r'<article><p class="preserve-lines">(.*?)</p>',s,re.S)
    if lead: fields['objective']=clean(lead[1]) or None
    for label,f in [('Description','detail'),('Progress','progress'),('Completion','complete')]:
        m=re.search(r'<h2>'+label+r'</h2><p class="preserve-lines">(.*?)</p>',s,re.S)
        if m: fields[f]=clean(m[1]) or None
    chain=re.search(r'<h2>Quest chain</h2>(.*?)</section>',s,re.S)
    source=re.search(r'<dt>Source</dt><dd>(.*?)</dd>',s,re.S)
    rows.append({**r,'english':fields,'sourceKind':clean(source[1]) if source else 'Unknown','chainText':clean(chain[1]) if chain else '', 'ua':ua.get(r['id'])})
(BASE/'english.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
print('Parsed',len(rows),'quests;',sum(bool(v) for r in rows for v in r['english'].values()),'fields')
for region in dict.fromkeys(r['region'] for r in rows):
    group=[r for r in rows if r['region']==region]
    (BASE/(region.replace(' ','-')+'-english.txt')).write_text('\n\n'.join(str(r['id'])+' '+r['en']+'\n'+'\n'.join(f+': '+str(t) for f,t in r['english'].items() if f!='title') for r in group),encoding='utf-8')
