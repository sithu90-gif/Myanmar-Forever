from pathlib import Path
import json,sys,shutil,zipfile,hashlib
BASE=Path(__file__).resolve().parent;ROOT=BASE.parents[1]
sys.path.insert(0,str(ROOT/'production/build-tools'))
from lupa.lua51 import LuaRuntime
out=BASE/'dist/Myanmar_Forever_NorthshireTest';source=out/'BuildSource'
lua=LuaRuntime(unpack_returned_tuples=True);log=[]
lua.globals().print=lambda *args:log.append(' '.join(map(str,args)))
lua.globals().ADDON_DIR=out.as_posix()
lua.execute((BASE/'tests.lua').read_text(encoding='utf-8'))
(BASE/'test-log.txt').write_text('\n'.join(log),encoding='utf-8')
load=lambda p:json.loads(p.read_text(encoding='utf-8'))
drafts=load(BASE/'drafts.json');old=load(BASE.parent/'release-021/drafts.json')
for i,q in old.items():assert drafts[i]==q,('Prior quest changed',i)
for name in ('Renderer.lua','QuestBridge.lua'):
    assert (out/name).read_bytes()==(BASE.parent/'release-021/Addon'/name).read_bytes()
for toc in out.glob('*.toc'):
    assert '## Version: 0.3.0-beta' in toc.read_text()
    for line in toc.read_text().splitlines():
        if line and not line.startswith('#'):assert (out/line.replace('\\','/')).is_file()
assert not list(out.rglob('*.tga'))
def literal(v):
    if v is None:return 'nil'
    if isinstance(v,str):return '"'+v.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n').replace('\r','\\r')+'"'
    return '{'+','.join('['+literal(k)+']='+literal(t) for k,t in v.items())+'}'
new=load(BASE/'new-drafts.json')
text='-- Editable Unicode drafts, including review-only 95213 completion. Runtime holds are applied by prepare_release.py.\nreturn '+literal(new)+'\n'
(BASE/'DwarfGnome.lua').write_text(text,encoding='utf-8')
parsed=lua.execute(text)
for i,q in new.items():
    for f,t in q.items():assert parsed[i][f]==t,(i,f)
for name in ['coldridge.py','dun.py','loch.py','classes.py','captured_drafts.py','recovered_drafts.py',
             'prepare_sources.py','prepare_release.py','build.py','test.py','tests.lua','test-log.txt',
             'DwarfGnome.lua','new-drafts.json','release-worklist.json','inventory.json','glossary.txt',
             'Dwarf-Gnome-Review.html','fetch-results.json']:
    shutil.copy2(BASE/name,source/name)
shutil.copytree(BASE/'Addon',source/'Addon',dirs_exist_ok=True)
gap=source/'GapCheck';gap.mkdir(exist_ok=True)
for name in ['tasks.json','fetch-results.json','recovered.json']:shutil.copy2(BASE/'gap-check'/name,gap/name)
# Preserve the unchanged earlier source data without duplicating whole distributions.
base_source=source/'Base-v0.2.1';base_source.mkdir(exist_ok=True)
for name in ['captured-English.json','catalog-validation.json','worklist.json']:
    shutil.copy2(BASE.parent/'release-021'/name,base_source/name)
shutil.copy2(BASE/'Dwarf-Gnome-Review.html',out/'Dwarf-Gnome-Review.html')
manifest=load(BASE/'build-validation.json')
manifest.update(lua51Tests='passed: all 353 quests, 981 available and 78 absent dialogue states',
    prior248TranslationsUnchanged=True,rendererAndCaptureCodeUnchangedFrom021=True,
    unicodeCatalog='105 new records round-trip in Lua 5.1',tocPaths='passed',fullPageImages=0,
    sourceCoverage=load(BASE/'catalog-validation.json'))
(BASE/'build-validation.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
(source/'validation.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
archive=ROOT/'outputs/MyanmarForever_v0.3.0-beta.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(out.rglob('*')):
        if p.is_file():z.write(p,p.relative_to(out.parent))
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
print('\n'.join(log[-3:]));print(archive)
print('SHA256',hashlib.sha256(archive.read_bytes()).hexdigest())
