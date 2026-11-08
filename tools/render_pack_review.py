"""Render a translation pack with its English evidence for owner review."""
import argparse
import html
import json
from pathlib import Path


def render(directory, output):
    read = lambda name: json.loads((directory / name).read_text(encoding='utf-8'))
    pack, sources = read('pack.json'), read('english-sources.json')
    escape = html.escape
    title = f'MyanmarForever {pack["version"]} — Undead Tirisfal review'
    holds = {(str(h['id']), h['field']): h['reason'] for h in pack.get('heldFields', [])}
    labels = {'title': 'Quest title', 'detail': 'Offer dialogue', 'objective': 'Objective',
              'progress': 'Progress reply', 'complete': 'Completion reply'}
    fields = sum(bool(text) for quest in pack['drafts'].values() for text in quest.values())
    parts = ['<!doctype html><html lang="en"><meta charset="utf-8">',
             '<meta name="viewport" content="width=device-width,initial-scale=1">',
             f'<title>{escape(title)}</title>', '''<style>
body{margin:0;background:#101817;color:#edf1e9;font:16px/1.7 system-ui,"Myanmar Text",sans-serif}
main{max-width:960px;margin:auto;padding:32px 22px}h1,h2{line-height:1.35}a,summary{color:#a9dbbd}
nav{display:flex;flex-wrap:wrap;gap:8px;margin:24px 0}nav a{padding:3px 10px;background:#20342a;border-radius:8px}
article{background:#19251f;border:1px solid #3b4c40;border-radius:14px;padding:26px;margin:24px 0}
section{border-top:1px solid #34483b;padding-top:14px;margin-top:20px}h3,.meta{color:#b8c5b8;font-size:14px}
.mm{font:19px/2 "Myanmar Text",sans-serif;white-space:pre-wrap}.source{white-space:pre-wrap}
summary{cursor:pointer}.hold{border-left:3px solid #d1ac68;padding-left:14px;color:#e8ce9e}
@media print{body,article{background:white;color:black}.meta,h3{color:#333}nav{display:none}a{color:#224b33}}
</style><main><header>''', f'<p>{escape(pack["date"])}</p><h1>{escape(title)}</h1>',
             f'<p>{len(pack["drafts"])} added quests · {fields} translated fields</p>',
             f'<p>{escape(pack["scope"])}</p>',
             '<p>English identities retain Myanmar pronunciation. These translations follow the approved Undead style and received assisted source review. Full native proofreading and current live-client verification remain pending.</p>',
             '<p class="meta">Expand each English comparison. Missing or held source states retain the original-language fallback.</p></header><nav>']
    parts.extend(f'<a href="#q{row["id"]}">{row["id"]}</a>' for row in pack['rows'])
    parts.append('</nav>')
    for row in pack['rows']:
        qid = str(row['id'])
        quest, source = pack['drafts'][qid], sources[qid]
        level = row.get('questLevel')
        meta = f'Quest {qid} · {row.get("region", "")}' + (f' · Quest level {level}' if level else '')
        parts.extend([f'<article id="q{qid}"><p class="meta">{escape(meta)}</p>',
                      f'<h2>{escape(row["en"])}</h2>'])
        for field, label in labels.items():
            text, english = quest.get(field), source['english'].get(field)
            parts.append(f'<section><h3>{label}</h3>')
            if text:
                parts.append(f'<div class="mm" lang="my">{escape(text)}</div>')
            else:
                reason = holds.get((qid, field), 'No reviewed English state available; original-language fallback retained.')
                parts.append(f'<p class="hold">{escape(reason)}</p>')
            if english:
                parts.append(f'<details><summary>Compare English</summary><div class="source">{escape(english)}</div></details>')
            url = source.get('fieldSources', {}).get(field, {}).get('sourceURL') or source['sourceURL']
            if url.startswith(('https://', 'http://')):
                parts.append(f'<p class="meta"><a href="{escape(url)}">English reference</a></p>')
            parts.append('</section>')
        parts.append('</article>')
    parts.append('</main></html>')
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text('\n'.join(line.rstrip() for line in '\n'.join(parts).splitlines()) + '\n', encoding='utf-8')
    print(f'{output}: {len(pack["drafts"])} quests, {fields} translated fields')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pack', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    render(args.pack, args.output)
