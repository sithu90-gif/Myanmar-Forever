"""Render the source-linked Undead translation pack as a readable HTML review."""
import html
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
PACK=ROOT/'translations/undead-v0.6.3'
read=lambda p:json.loads(p.read_text(encoding='utf8'))


def render():
    pack=read(PACK/'pack.json')
    sources=read(PACK/'english-sources.json')
    esc=html.escape
    labels={'title':'Quest title','detail':'Offer dialogue','objective':'Objective','progress':'Progress reply','complete':'Completion reply'}
    held={(str(h['id']),h['field']):h['reason'] for h in pack['heldFields']}
    parts=['''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>MyanmarForever — Undead starter translation review</title>
<style>body{margin:0;background:#101817;color:#edf1e9;font:16px/1.7 system-ui,"Myanmar Text",sans-serif}main{max-width:960px;margin:auto;padding:32px 22px}h1,h2,h3{line-height:1.35}h1{font-size:30px}h2{margin:0;font-size:23px}h3{font-size:14px;text-transform:uppercase;letter-spacing:.08em;color:#b5d2be;margin:0 0 12px}a{color:#a9dbbd}header{border-bottom:1px solid #45604e;padding-bottom:24px}nav{display:flex;flex-wrap:wrap;gap:8px;margin:24px 0}nav a{padding:3px 10px;background:#20342a;border-radius:8px}article{background:#19251f;border:1px solid #3b4c40;border-radius:14px;padding:26px;margin:24px 0}section{border-top:1px solid #34483b;padding-top:18px;margin-top:22px}.mm{font:19px/2 "Myanmar Text",system-ui,sans-serif;white-space:pre-wrap}.meta,.status{color:#b8c5b8;font-size:14px}.source{white-space:pre-wrap;color:#d0d9ce;margin-top:12px}details{margin-top:12px}summary{cursor:pointer;color:#a9dbbd}.hold{border-left:3px solid #d1ac68;padding-left:14px;color:#e8ce9e}footer{font-size:14px;color:#b8c5b8}@media print{body{background:white;color:black}article{background:white;break-inside:avoid;border-color:#999}.meta,.status,h3{color:#333}nav{display:none}details{display:block}.source{color:#333}a{color:#224b33}}</style>
<main><header><p class="status">v0.6.3 candidate · 5 November 2026</p><h1>Undead starter route</h1>
<p>Deathknell → Brill · 24 quests · 106 translated fields</p>
<p>The first two samples were approved in chat. Remaining fields follow that style and await full native proofreading and current live-client testing. English names stay recognizable; pronunciation appears on first important use in each field.</p>
<p class="meta">Open each English source to compare. Missing states remain missing; one gender-dependent reply is held. Reference text is not proof of current live availability. The addon's 45 first-introduction meanings are applied at runtime; this document shows editable source wording.</p></header><nav>''']
    parts.extend(f'<a href="#q{r["id"]}">{r["id"]}</a>' for r in pack['rows'])
    parts.append('</nav>')
    for row in pack['rows']:
        qid=str(row['id']);q=pack['drafts'][qid];source=sources[qid]
        branch=row['characterClass'] or 'Shared story'
        parts.append(f'<article id="q{qid}"><p class="meta">Quest {qid} · {esc(branch)}</p><h2>{esc(row["en"])}</h2><p class="meta"><a href="{esc(source["sourceURL"])}">English reference</a> · fetched {source["fetched"]}</p>')
        for field,label in labels.items():
            text=q[field];english=source['english'][field]
            parts.append(f'<section><h3>{label}</h3>')
            if text:
                approved=(qid=='363' and field=='detail') or (qid=='364' and field in ('title','detail','objective'))
                parts.append('<p class="status">'+('Approved chat sample' if approved else 'Assisted editorial draft')+'</p>')
                parts.append(f'<div class="mm" lang="my">{esc(text)}</div>')
            else:
                reason=held.get((qid,field),'No English source state available; native fallback retained.')
                parts.append(f'<p class="hold">{esc(reason)}</p>')
            if english:
                parts.append(f'<details><summary>Compare English</summary><div class="source">{esc(english)}</div></details>')
            parts.append('</section>')
        parts.append('</article>')
    parts.append('<footer>Meaning and NPC voice were checked against English with assisted editing. Independent assisted review, full native proofreading, live Forever verification and controller hardware testing remain pending. DeepL MY supplied comparison drafts; edited wording controls this pack.</footer></main></html>')
    out=ROOT/'docs/UNDEAD-STARTER-TRANSLATIONS.html'
    out.write_text('\n'.join(line.rstrip() for line in '\n'.join(parts).splitlines())+'\n',encoding='utf8')
    print(out)


if __name__=='__main__':
    render()
