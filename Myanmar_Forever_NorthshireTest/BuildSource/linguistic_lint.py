"""Structural annotation lint; never a semantic or pronunciation reviewer.

Printed issues must be resolved by source-aware editing or a field-specific,
reviewed exception. Do not bulk-transliterate unknown English runs.
"""
import argparse,json,re
from pathlib import Path
MARKER=re.compile(r'<(?:name|class|race|priest/priestess)>',re.I)
RUN=re.compile(r"[A-Za-z][A-Za-z0-9'’:-]*(?: +[A-Za-z0-9][A-Za-z0-9'’:-]*)*")
PAREN=re.compile(r'\s*\(([^()]*)\)')
MM=re.compile(r'[\u1000-\u109f\uaa60-\uaa7f\ua9e0-\ua9ff]')
def occurrences(text):
 # Mask placeholders without moving the remaining character offsets.
 masked=MARKER.sub(lambda m:' '*len(m[0]),text)
 result=[]
 for m in RUN.finditer(masked):
  term=m[0].rstrip(':');end=m.start()+len(term)
  p=PAREN.match(masked,end)
  annotation=p[1] if p and MM.search(p[1]) else None
  result.append({'term':term,'at':m.start(),'annotation':annotation})
 return result

def lint(drafts,glossary=None,exceptions=None):
 issues=[];exceptions=exceptions or {};glossary=glossary or {}
 for qid,q in drafts.items():
  for field,text in q.items():
   if not text:continue
   seen=set();approved=exceptions.get(qid,{}).get(field,{})
   for o in occurrences(text):
    term=o['term'];annotation=o['annotation']
    if term in approved:continue
    if term not in seen and not annotation:
     issues.append({'id':qid,'field':field,'term':term,'problem':'first_occurrence_without_annotation'})
    elif term in seen and annotation:
     issues.append({'id':qid,'field':field,'term':term,'problem':'repeated_annotation'})
    if annotation and term in glossary:
     canonical=glossary[term]
     if isinstance(canonical,dict):canonical=canonical['pronunciation']
     if not(annotation==canonical or annotation.startswith(canonical+' — ') or annotation.startswith(canonical+'၊')):
      issues.append({'id':qid,'field':field,'term':term,'annotation':annotation,'canonical':canonical,'problem':'glossary_mismatch'})
    if glossary and term not in glossary:
     issues.append({'id':qid,'field':field,'term':term,'problem':'missing_glossary_entry'})
    seen.add(term)
 return issues
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('drafts');p.add_argument('--glossary');p.add_argument('--exceptions');p.add_argument('--output');a=p.parse_args()
 load=lambda p:json.loads(Path(p).read_text()) if p else None
 result=lint(load(a.drafts),load(a.glossary),load(a.exceptions));text=json.dumps(result,ensure_ascii=False,indent=2)+'\n'
 if a.output:Path(a.output).write_text(text)
 else:print(text)
 print(len(result),'structural issues; this check does not establish semantic quality')
