import concurrent.futures
import argparse
import hashlib
import html
import json
import re
import urllib.request
from pathlib import Path

destination = Path('work/quest-sources')
titles = {}
fields = {"detail": "Description", "progress": "Progress", "complete": "Completion"}


def clean(text):
    text = re.sub(r"<script\b[^>]*>.*?</script>", "", text, flags=re.S | re.I)
    return html.unescape(re.sub(r"<[^>]*>", "", re.sub(r"<br\s*/?>", "\n", text))).replace("\xa0", " ").strip()


def parse_wowhead(raw):
    raw = re.sub(r'<script\b[^>]*>.*?</script>', '', raw, flags=re.S | re.I)
    patterns = {"title": r'<h1[^>]*class="heading-size-1"[^>]*>(.*?)</h1>',
                "objective": r'<h1[^>]*class="heading-size-1"[^>]*>.*?</h1>\s*(.*?)(?:<table|<ul|<h2|<div class="pad")'}
    patterns.update({field: rf'<div id="lknlksndgg-{heading.lower()}"[^>]*>(.*?)</div>'
                     for field, heading in fields.items() if field != 'detail'})
    patterns['detail'] = r'<h2[^>]*>Description</h2>(.*?)(?:<h2|<div class="pad")'
    result = {field: clean(match[1]) or None if (match := re.search(pattern, raw, re.S)) else None
              for field, pattern in patterns.items()}
    for field, heading in [('progress', 'Progress'), ('complete', 'Completion')]:
        if result[field] is not None:
            continue
        for header in re.finditer(r'<h2\b[^>]*>(.*?)</h2>', raw, re.S | re.I):
            if clean(header[1]) != heading:
                continue
            body = re.split(r'<(?:table|ul|h2|div)\b', raw[header.end():], maxsplit=1, flags=re.I)[0]
            result[field] = clean(body) or None
            break
    return result


def fetch(item):
    quest_id, title = item
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower().replace("'", "")).strip("-")
    record = {"id": quest_id, "en": title, "references": {}}
    urls = {"sixty": f"https://www.60.tools/quests/{quest_id}-{slug}",
            "wowhead": f"https://www.wowhead.com/forever/quest%3D{quest_id}/{slug}"}
    for name, url in urls.items():
        path = destination / f"{quest_id}-{name}.html"
        try:
            if not path.exists():
                request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(request, timeout=15) as response:
                    path.write_bytes(response.read())
            raw = path.read_text(encoding="utf-8")
            if name == "sixty":
                patterns = {"title": r"<h1[^>]*>(.*?)</h1>",
                            "objective": r'<article[^>]*>\s*<p class="preserve-lines">(.*?)</p>'}
                patterns.update({field: rf'<h2>{heading}</h2>\s*<p class="preserve-lines">(.*?)</p>'
                                 for field, heading in fields.items()})
            else:
                patterns = None
            english = parse_wowhead(raw) if patterns is None else {
                field: clean(match[1]) or None if (match := re.search(pattern, raw, re.S)) else None
                for field, pattern in patterns.items()}
            record["references"][name] = {"url": url, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                                          "english": english}
        except (OSError, ValueError) as error:
            record["references"][name] = {"url": url, "error": str(error)}
    return str(quest_id), record


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--ids", nargs="+", type=int, required=True)
    parser.add_argument("--metadata", required=True, type=Path, help='Decoded installed QuestieDB JSON with English titles')
    args = parser.parse_args()
    destination = args.output
    destination.mkdir(parents=True, exist_ok=True)
    if args.ids:
        questie = json.loads(args.metadata.read_text(encoding="utf-8"))
        titles = {quest_id: questie[str(quest_id)]["S"]["1"] for quest_id in args.ids}
    with concurrent.futures.ThreadPoolExecutor(max_workers=7) as pool:
        results = dict(pool.map(fetch, titles.items()))
    (destination / "fetched.json").write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    for quest_id, record in results.items():
        print(quest_id, {key: ref.get("error") or [field for field, value in ref["english"].items() if value]
                         for key, ref in record["references"].items()})
