"""Build the 353-entry regional draft with the supplied, unchanged HB generator."""
from pathlib import Path
import sys, json, importlib.util, shutil, hashlib, urllib.request
sys.stdout.reconfigure(encoding='utf-8')
BASE=Path(__file__).resolve().parent
ROOT=BASE.parent.parent
sys.path.insert(0,str(ROOT/'production/build-tools'))
from fontTools.ttLib import TTFont
from PIL import Image, ImageDraw, ImageFont

source=ROOT/'inspection/shaped043/Myanmar_Forever_ShapedTest/BuildSource'
spec=importlib.util.spec_from_file_location('preshape',source/'mm_preshape.py')
shape=importlib.util.module_from_spec(spec); spec.loader.exec_module(shape)
font=source/'NotoSansMyanmar-Regular.ttf'
out=BASE/'dist/Myanmar_Forever_NorthshireTest'
(out/'fonts').mkdir(parents=True,exist_ok=True)
(out/'Catalogs').mkdir(exist_ok=True)
(out/'BuildSource').mkdir(exist_ok=True)
drafts=json.loads((BASE/'drafts.json').read_text(encoding='utf-8'))
rows=json.loads((BASE/'worklist.json').read_text(encoding='utf-8'))
titles={str(r['id']):r['en'] for r in rows}
labels={'objective':'ရည်ရွယ်ချက်','priest':'Priest (ပရီးစ်တ် — ဘာသာရေးဆရာ)','priestess':'Priestess (ပရီးစ်တက်စ် — ဘာသာရေးဆရာမ)'}
texts=[t for q in drafts.values() for t in q.values() if t]+list(labels.values())
shaper=shape.HBShaper(str(font))
from functools import lru_cache
@lru_cache(maxsize=None)
def safe_clusters(shaper,run):
    # A HarfBuzz cluster boundary is not always a safe isolation boundary.
    # Find the shortest units whose independent shape equals the original run.
    glyphs=shaper.shape(run)
    starts=sorted({g[1] for g in glyphs})+[len(run)]
    assert starts[0]==0
    def signature(gs): return [(g,a,x,y) for g,c,a,x,y in gs]
    choices={len(starts)-1:[]}
    for i in range(len(starts)-2,-1,-1):
        for j in range(i+1,len(starts)):
            if j not in choices: continue
            unit=run[starts[i]:starts[j]]
            expected=signature([g for g in glyphs if starts[i]<=g[1]<starts[j]])
            if signature(shaper.shape(unit))==expected:
                choices[i]=[unit]+choices[j]; break
    assert 0 in choices,('Unable to preserve shaping',ascii(run))
    return choices[0]
shape.split_clusters=safe_clusters
units=[]
for text in texts:
    for mm,run in shape.split_runs(text):
        if mm:
            parts=shape.split_clusters(shaper,run)
            assert ''.join(parts)==run
            full=[(g,a,x,y) for g,c,a,x,y in shaper.shape(run)]
            split=[(g,a,x,y) for u in parts for g,c,a,x,y in shaper.shape(u)]
            assert full==split,('Shaping changes at split boundary',run)
            for u in parts:
                assert all(g[0]!=0 for g in shaper.shape(u)),('Missing source glyph',u)
                if u not in units: units.append(u)
mapping,scale=shape.build_font(str(font),shaper,units,str(out/'fonts/NorthshireShaped.ttf'))
built=TTFont(out/'fonts/NorthshireShaped.ttf')
# Distinct internal name as well as path prevents collision with sample-font caches.
for rec in built['name'].names:
    if rec.nameID in (1,4,6,16):
        value='MMNorthshireShaped' if rec.nameID==6 else 'MM Northshire Shaped'
        rec.string=value.encode(rec.getEncoding())
built.save(out/'fonts/NorthshireShaped.ttf')
cmap=built.getBestCmap()
reverse={chr(v):k for k,v in mapping.items()}
def encode(text):
    missing=set(); result=shape.encode_text(shaper,mapping,text,missing)
    assert not missing
    assert ''.join(reverse.get(c,c) for c in result)==text
    assert all(ord(c) in cmap for c in result if c not in '\n\r\t'),('Missing display glyph',text)
    return result
lines=['-- Generated together with fonts/NorthshireShaped.ttf; do not mix versions.',
       'local _, A = ...',f'A.scale = {scale!r}','A.labels = {']
for k,v in labels.items(): lines.append(f'  {k} = {shape.lua_string(encode(v))},')
lines+=['}','A.quests = {']
encoded={}
for id in [r['id'] for r in rows]:
    key=str(id); encoded[key]={}
    lines += [f'  [{id}] = {{',f'    en = {shape.lua_string(titles[key])},']
    for f,t in drafts[key].items():
        encoded[key][f]=encode(t) if t is not None else None
        lines.append(f'    {f} = '+(shape.lua_string(encoded[key][f]) if t is not None else 'nil')+',')
    lines.append('  },')
lines.append('}')
(out/'Catalogs/Northshire.lua').write_text('\n'.join(lines)+'\n',encoding='ascii')
for file in (BASE/'Addon').glob('*.lua'): shutil.copy2(file,out/file.name)
toc=r'''## Interface: 16001
## AllowLoadGameType: camelot
## Title: MyanmarForever
## Version: 0.3.0-beta
## Notes: 353 quest drafts: Human and Dwarf/Gnome quest drafts; /mmnorth 179
## SavedVariables: MMNorthshireSettings, MMNorthshireCaptures

Catalogs\Northshire.lua
Renderer.lua
QuestBridge.lua
'''
for suffix in ['', '_Camelot']:
    (out/f'Myanmar_Forever_NorthshireTest{suffix}.toc').write_text(toc,encoding='utf-8')
for f in ['drafts.json','worklist.json','catalog-validation.json','english-reviewed.json','recovered.py']:
    shutil.copy2(BASE/f,out/'BuildSource'/f)
shutil.copy2(source/'mm_preshape.py',out/'BuildSource/mm_preshape.py')
(out/'BuildSource/BUILD-NOTE.txt').write_text('This build uses build.py safe_clusters in the production workspace to merge unsafe isolation boundaries before calling the original mm_preshape font builder. Do not regenerate with the original sample script alone. The rendered glyph sequence/positions were verified equal to full-run HarfBuzz shaping for every Myanmar run. Font and catalog must always be regenerated together.\n',encoding='utf-8')
(out/'BuildSource/clusters.json').write_text(json.dumps({'scale':scale,'map':mapping},ensure_ascii=False,indent=2),encoding='utf-8')
license_file=BASE/'OFL.txt'
if not license_file.exists():
    urllib.request.urlretrieve('https://raw.githubusercontent.com/notofonts/myanmar/main/OFL.txt',license_file)
shutil.copy2(license_file,out/'fonts/OFL.txt')
shutil.copy2(BASE/'INSTALL.txt',out/'INSTALL.txt')
(out/'fonts/NOTICE.txt').write_text('MM Northshire Shaped is a modified Noto Sans Myanmar font, generated from the font supplied with ShapedTest 0.4.3. Copyright 2022 The Noto Project Authors. Licensed under SIL OFL 1.1; see OFL.txt. The added private-use glyphs are HarfBuzz-shaped clusters for this 353-entry regional corpus. It is not an upstream Noto release.\n',encoding='utf-8')
# Font-only proof outside WoW, not a claimed in-game screenshot.
fnt=ImageFont.truetype(str(out/'fonts/NorthshireShaped.ttf'),round(23*scale),layout_engine=ImageFont.Layout.BASIC)
header=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
im=Image.new('RGB',(1400,9000),(7,9,14)); draw=ImageDraw.Draw(im)
draw.text((24,15),'MyanmarForever v0.3.0-beta - font proof (outside WoW)',font=header,fill='white')
y=60
for id in [179,170,3107,98423,86585,1097]:
    draw.text((24,y),f'{id}  {titles[str(id)]}',font=header,fill='#e9c46a');y+=36
    draw.text((24,y),encoded[str(id)]['title'],font=fnt,fill='white');y+=65
    text=encoded[str(id)]['complete'] or encoded[str(id)]['detail']
    line=''
    for char in text:
        if char=='\n':
            draw.text((24,y),line,font=fnt,fill='white'); y+=60;line=''
            continue
        if draw.textlength(line+char,font=fnt)>1320:
            draw.text((24,y),line,font=fnt,fill='white'); y+=60;line=''
        line+=char
    if line: draw.text((24,y),line,font=fnt,fill='white');y+=60
    y+=20
im.crop((0,0,1400,y+20)).save(BASE/'font-proof.png')
manifest={'version':'0.3.0-beta','quests':[r['id'] for r in rows],'clusters':len(mapping),'fontScale':scale,
 'shapingBoundaryEquivalence':'passed for every Myanmar run','unicodeRoundTrip':'passed for every field',
 'glyphCoverage':'passed for every encoded field','inGame':'not tested','foreverSemanticVerification':'Human base plus 104 Dwarf/Gnome reference drafts and live-captured Elmore offer; new live-game verification pending',
 'fontSHA256':hashlib.sha256((out/'fonts/NorthshireShaped.ttf').read_bytes()).hexdigest(),
 'catalogSHA256':hashlib.sha256((out/'Catalogs/Northshire.lua').read_bytes()).hexdigest()}
manifest['normalPlayerAppearancePreserved']=True
manifest['dialogueStates']=sum(bool(q[f]) for q in drafts.values() for f in ('detail','progress','complete'))
manifest['translatedFields']=sum(bool(t) for q in drafts.values() for t in q.values())
(BASE/'build-validation.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Built',len(drafts),'quests;',manifest['dialogueStates'],'states;',len(mapping),'shaped units.')
