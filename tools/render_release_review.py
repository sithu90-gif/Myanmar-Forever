"""Build a source-linked review of all version 1 additions and field fixes."""
import html
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
read=lambda p:json.loads(p.read_text(encoding='utf8'))


def render():
    manifest=read(ROOT/'releases/1.0.0.json')
    baseline_rows={str(r['id']):r for r in read(ROOT/'Myanmar_Forever_NorthshireTest/BuildSource/worklist.json')}
    entries=[]
    for relative in manifest['packs']:
        directory=ROOT/relative
        pack=read(directory/'pack.json');sources=read(directory/'english-sources.json')
        rows={str(r['id']):r for r in pack['rows']}
        for qid,q in pack.get('drafts',{}).items():entries.append((qid,rows[qid],q,sources[qid],relative,False))
        for qid,q in pack.get('overrides',{}).items():entries.append((qid,baseline_rows[qid],q,sources[qid],relative,True))
    fields=sum(bool(t) for _,_,q,_,_,_ in entries for t in q.values())
    esc=html.escape
    parts=['''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MyanmarForever 1.0.0 translation review</title>
<style>body{margin:0;background:#101817;color:#edf1e9;font:16px/1.7 system-ui,"Myanmar Text",sans-serif}main{max-width:960px;margin:auto;padding:32px 22px}h1,h2,h3{line-height:1.35}h1{font-size:30px}h2{font-size:23px}h3{font-size:14px;letter-spacing:.06em;color:#b5d2be}a{color:#a9dbbd}header{border-bottom:1px solid #45604e;padding-bottom:24px}nav{display:flex;flex-wrap:wrap;gap:7px;margin:24px 0}nav a{padding:2px 9px;background:#20342a;border-radius:7px}article{background:#19251f;border:1px solid #3b4c40;border-radius:14px;padding:24px;margin:24px 0}section{border-top:1px solid #34483b;margin-top:20px}.mm{font:19px/2 "Myanmar Text",system-ui,sans-serif;white-space:pre-wrap}.meta{color:#b8c5b8;font-size:14px}.source{white-space:pre-wrap;color:#d0d9ce;margin:12px 0}summary{cursor:pointer;color:#a9dbbd}.missing{border-left:3px solid #d1ac68;padding-left:14px;color:#e8ce9e}@media print{body,article{background:white;color:black}.meta,h3,.source{color:#333}nav{display:none}article{break-inside:avoid}a{color:#224b33}}</style><main><header><p>MyanmarForever 1.0.0 · 6 November 2026</p><h1>Starter routes and captured quest fixes</h1>''']
    parts.append(f'<p>{len(entries)-1} added quest records and one existing quest reply · {fields} translated fields</p>')
    parts.append('<p>Includes both Skyborne branches, the Undead starter expansion, and the missing quests captured during play. English names retain Myanmar pronunciation. The first two Undead examples were approved; remaining wording is assisted source-aware editing, pending full native proofreading.</p><p class="meta">Open the English comparison under each field. Missing or held states retain the original-language fallback. Private player identities have been removed from shared live-capture evidence. Version 1 is the release number; live Skyborne/controller checks remain pending.</p></header><nav>')
    parts.extend(f'<a href="#q{qid}">{qid}</a>' for qid,_,_,_,_,_ in entries)
    parts.append('</nav>')
    labels={'title':'Quest title','detail':'Offer dialogue','objective':'Objective','progress':'Progress reply','complete':'Completion reply'}
    for qid,row,q,source,relative,override in entries:
        parts.append(f'<article id="q{qid}"><p class="meta">Quest {qid} · {esc(row.get("region",""))}'+(' · Added reply' if override else '')+f'</p><h2>{esc(row["en"])}</h2><p class="meta">{esc(relative)}</p>')
        for field,label in labels.items():
            if field not in q:continue
            text=q[field];english=source['english'].get(field)
            parts.append(f'<section><h3>{label}</h3>')
            if text:parts.append(f'<div class="mm" lang="my">{esc(text)}</div>')
            else:parts.append('<p class="missing">Unavailable source state or documented source hold; original-language fallback retained.</p>')
            if english:parts.append(f'<details><summary>Compare English</summary><div class="source">{esc(english)}</div></details>')
            record=source.get('fieldSources',{}).get(field,{})
            url=record.get('sourceURL') or record.get('url') or source.get('sourceURL','')
            if url.startswith(('https://','http://')):parts.append(f'<p class="meta"><a href="{esc(url)}">English reference</a></p>')
            elif url:parts.append('<p class="meta">Sanitized local quest capture</p>')
            parts.append('</section>')
        parts.append('</article>')
    parts.append('</main></html>')
    out=ROOT/'docs/V1-TRANSLATION-REVIEW.html'
    out.write_text('\n'.join(line.rstrip() for line in '\n'.join(parts).splitlines())+'\n',encoding='utf8')
    print(f'{out}: {len(entries)} quest sections, {fields} Myanmar fields')


if __name__=='__main__':render()
