"""Regenerate the matching Myanmar font/catalog offline. See BUILD-NOTE.txt."""
from pathlib import Path
from functools import lru_cache
import json, hashlib, importlib.metadata, tempfile
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.recordingPen import DecomposingRecordingPen
import mm_preshape as shape

BASE=Path(__file__).resolve().parent
ADDON=BASE.parent
VERSION='0.6.2-beta-candidate'
load=lambda p:json.loads(p.read_text(encoding='utf-8'))
drafts=load(BASE/'drafts.json')
rows=load(BASE/'worklist.json')
assert len(rows)==len(drafts)==len({r['id'] for r in rows})
assert {str(r['id']) for r in rows}==set(drafts)
source_font=BASE/'NotoSansMyanmar-Regular.ttf'
latin_font=BASE/'Previous-v0.3.0/LatinFallback.ttf'
# The upstream Myanmar-only font omits Latin letters and digits. Preserve the
# previous release's Latin outlines, without depending on OS font substitution.
temp=tempfile.TemporaryDirectory(prefix='myanmar-forever-build-')
font=Path(temp.name)/'input.ttf'
merged=TTFont(source_font);fallback=TTFont(latin_font)
assert merged['head'].unitsPerEm==1000 and fallback['head'].unitsPerEm==1600
cmap_in=merged.getBestCmap();fallback_cmap=fallback.getBestCmap()
order=merged.getGlyphOrder();glyphset=fallback.getGlyphSet()
for cp,name in sorted(fallback_cmap.items()):
    if cp in cmap_in or cp>=0xE000 or shape.is_myanmar(chr(cp)):continue
    dest='legacyLatin%04X'%cp
    pen=TTGlyphPen(None);rec=DecomposingRecordingPen(glyphset)
    glyphset[name].draw(rec);rec.replay(pen)
    glyph=pen.glyph();merged['glyf'].glyphs[dest]=glyph;order.append(dest)
    # Legacy output's 1.6 em adjustment did not scale outlines or advances.
    merged['hmtx'].metrics[dest]=fallback['hmtx'].metrics[name]
    for table in merged['cmap'].tables:
        if table.isUnicode() and table.format in (4,12):table.cmap[cp]=dest
merged.setGlyphOrder(order);merged['glyf'].glyphOrder=order
merged.save(font)
shaper=shape.HBShaper(str(font))

@lru_cache(maxsize=None)
def safe_clusters(shaper,run):
    glyphs=shaper.shape(run)
    starts=sorted({g[1] for g in glyphs})+[len(run)]
    assert starts[0]==0
    signature=lambda gs:[(g,a,x,y) for g,c,a,x,y in gs]
    choices={len(starts)-1:[]}
    for i in range(len(starts)-2,-1,-1):
        for j in range(i+1,len(starts)):
            if j not in choices:continue
            unit=run[starts[i]:starts[j]]
            expected=signature([g for g in glyphs if starts[i]<=g[1]<starts[j]])
            if signature(shaper.shape(unit))==expected:
                choices[i]=[unit]+choices[j];break
    assert 0 in choices,('Unsafe shaping boundary',run)
    return choices[0]

shape.split_clusters=safe_clusters
labels={'objective':'ရည်ရွယ်ချက်','priest':'Priest (ပရီးစ်တ် — ဘာသာရေးဆရာ)','priestess':'Priestess (ပရီးစ်တက်စ် — ဘာသာရေးဆရာမ)'}
identities=load(BASE/'identity-glossary.json')
term_source=load(BASE/'term-glossary-v0.6.2.json')
terms={record['key']:record for record in term_source['terms']}
assert len(terms)==len(term_source['terms'])
aliases=[]
alias_by_text={}
for key,record in terms.items():
    assert record['meaning'].strip() and record['meaning']!=record['pronunciation']
    record['short']=record['en']+' ('+record['pronunciation']+')'
    record['intro']=record['en']+' ('+record['pronunciation']+' — '+record['meaning']+')'
    for alias in record['aliases']:
        if isinstance(alias,str):alias={'text':alias,'en':record['en'],'pronunciation':record['pronunciation']}
        short=alias['en']+' ('+alias['pronunciation']+')'
        intro=alias['en']+' ('+alias['pronunciation']+' — '+record['meaning']+')'
        for text in (alias['text'],short,intro):
            value={'key':key,'text':text,'short':short,'intro':intro}
            if text in alias_by_text:assert alias_by_text[text]==value,('Ambiguous alias',text)
            else:alias_by_text[text]=value
    for text in (record['short'],record['intro']):
        value={'key':key,'text':text,'short':record['short'],'intro':record['intro']}
        if text in alias_by_text:assert alias_by_text[text]==value,('Ambiguous canonical alias',text)
        else:alias_by_text[text]=value
aliases=sorted(alias_by_text.values(),key=lambda a:(-len(a['text']),a['text']))

for kind,records in identities.items():
    for key,record in records.items():
        record['full']=record['en']+' ('+record['pronunciation']+')'
        record['termKey']=kind+'.'+record['en'].lower().replace(' ','_')
        assert record['termKey'] in terms,('Missing identity meaning',kind,key)
        record['intro']=terms[record['termKey']]['intro']
        assert terms[record['termKey']]['short']==record['full']
identity_texts=[r['full'] for records in identities.values() for r in records.values()]
term_texts=[record[k] for record in terms.values() for k in ('short','intro')]+[record[k] for record in aliases for k in ('text','short','intro')]
units=[];seen=set()
for text in [t for q in drafts.values() for t in q.values() if t]+list(labels.values())+identity_texts+term_texts:
    for mm,run in shape.split_runs(text):
        if not mm:continue
        parts=safe_clusters(shaper,run)
        assert ''.join(parts)==run
        assert [(g,a,x,y) for g,c,a,x,y in shaper.shape(run)]==[(g,a,x,y) for u in parts for g,c,a,x,y in shaper.shape(u)]
        for unit in parts:
            assert all(g[0]!=0 for g in shaper.shape(unit)),('Missing source glyph',unit)
            if unit not in seen:units.append(unit);seen.add(unit)
font_out=ADDON/'fonts/NorthshireShaped.ttf'
mapping,scale=shape.build_font(str(font),shaper,units,str(font_out))
built=TTFont(font_out)
for rec in built['name'].names:
    if rec.nameID in (1,4,6,16):
        value='MMNorthshireShaped' if rec.nameID==6 else 'MM Northshire Shaped'
        rec.string=value.encode(rec.getEncoding())
built.save(font_out)
cmap=built.getBestCmap()
reverse={chr(v):k for k,v in mapping.items()}
def encode(text):
    missing=set();result=shape.encode_text(shaper,mapping,text,missing)
    assert not missing
    assert ''.join(reverse.get(c,c) for c in result)==text
    assert all(ord(c) in cmap for c in result if c not in '\n\r\t')
    return result
lines=['-- Generated with fonts/NorthshireShaped.ttf; do not mix versions.','local _, A = ...',f'A.scale = {scale!r}','A.labels = {']
for key,text in labels.items():lines.append(f'  {key} = {shape.lua_string(encode(text))},')
lines+=['}','A.identityLabels = {']
for kind,records in identities.items():
    lines.append('  '+kind+' = {')
    for key,record in records.items():
        lines.append('    ['+shape.lua_string(key)+'] = {en='+shape.lua_string(record['en'])+', full='+shape.lua_string(encode(record['full']))+', intro='+shape.lua_string(encode(record['intro']))+', termKey='+shape.lua_string(record['termKey'])+'},')
    lines.append('  },')
lines+=['}','A.termGlossary = {']
for key,record in terms.items():
    lines.append('  ['+shape.lua_string(key)+'] = {key='+shape.lua_string(key)+', en='+shape.lua_string(record['en'])+', short='+shape.lua_string(encode(record['short']))+', intro='+shape.lua_string(encode(record['intro']))+'},')
lines+=['}','A.termAliases = {']
for record in aliases:
    lines.append('  {key='+shape.lua_string(record['key'])+', text='+shape.lua_string(encode(record['text']))+', short='+shape.lua_string(encode(record['short']))+', intro='+shape.lua_string(encode(record['intro']))+'},')
lines+=['}','A.termFieldExceptions = {']
exceptions={}
for item in term_source.get('excludedContexts',[]):
    assert item['key'] in terms
    assert str(item['id']) in drafts and item['field'] in drafts[str(item['id'])]
    exceptions.setdefault(item['id'],{}).setdefault(item['field'],set()).add(item['key'])
for qid,fields in sorted(exceptions.items()):
    lines.append('  ['+str(qid)+'] = {')
    for field,keys in sorted(fields.items()):
        lines.append('    '+field+' = {'+', '.join('['+shape.lua_string(key)+']=true' for key in sorted(keys))+'},')
    lines.append('  },')
lines+=['}','A.quests = {']
for row in rows:
    q=drafts[str(row['id'])]
    lines += [f"  [{row['id']}] = {{",f"    en = {shape.lua_string(row['en'])},"]
    if row.get('englishTitleAliases'):
        lines.append('    enAliases = {'+', '.join(shape.lua_string(t) for t in row['englishTitleAliases'])+'},')
    for field,text in q.items():
        lines.append(f'    {field} = '+(shape.lua_string(encode(text)) if text is not None else 'nil')+',')
    lines.append('  },')
lines.append('}')
catalog=ADDON/'Catalogs/Northshire.lua'
catalog.write_text('\n'.join(lines)+'\n',encoding='ascii')
(BASE/'clusters.json').write_text(json.dumps({'scale':scale,'map':mapping},ensure_ascii=False,indent=2),encoding='utf-8')
manifest={'version':VERSION,'runtimeQuestCount':len(drafts),'runtimeDialogueStates':sum(bool(q[f]) for q in drafts.values() for f in ('detail','progress','complete')),
 'translatedFields':sum(bool(t) for q in drafts.values() for t in q.values()),'dynamicIdentityLabels':len(identity_texts),'firstIntroductionTerms':len(terms),'termAliasVariants':len(aliases),'clusters':len(mapping),'fontScale':scale,
 'shapingBoundaryEquivalence':'passed for every Myanmar run','unicodeRoundTrip':'passed for every field','glyphCoverage':'passed for every encoded field',
 'inGame':'not tested','nativeReview':'pending','sourceFontSHA256':hashlib.sha256(source_font.read_bytes()).hexdigest(),
 'latinFallbackSHA256':hashlib.sha256(latin_font.read_bytes()).hexdigest(),
 'fontSHA256':hashlib.sha256(font_out.read_bytes()).hexdigest(),'catalogSHA256':hashlib.sha256(catalog.read_bytes()).hexdigest(),
 'buildDependencies':{p:importlib.metadata.version(p) for p in ('fonttools','uharfbuzz')}}
(BASE/'validation.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print(json.dumps(manifest,indent=2))
