#!/usr/bin/env python3
"""
mm_preshape.py - make Myanmar text renderable in World of Warcraft.

WoW draws text glyph-by-glyph with no OpenType shaping, so Myanmar Unicode comes
out broken (missing medials, unstacked consonants, wrong vowel order).

Fix: shape each syllable ahead of time with HarfBuzz and store the finished
result as ONE glyph in a copy of the font, assigned a Private Use Area (PUA)
code point. Translations are then converted from normal Unicode to those PUA
characters before they go into the add-on.

Commands
  build   read text files, shape every syllable, write the shaped font,
          the syllable table (clusters.json) and an encoded Lua file
  encode  convert more text using an existing font/table (fails on syllables
          that are not in the font yet -> re-run build with all your text)

Requires:  pip install uharfbuzz fonttools
(--naive is a debugging shaper that does NOT shape; only for testing the tool.)
"""
import argparse, json, os, sys, unicodedata

from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.recordingPen import DecomposingRecordingPen

PUA_START, PUA_END = 0xE000, 0xF8FF
MYANMAR_RANGES = [(0x1000, 0x109F), (0xA9E0, 0xA9FF), (0xAA60, 0xAA7F), (0x200C, 0x200D)]


def is_myanmar(ch):
    o = ord(ch)
    return any(a <= o <= b for a, b in MYANMAR_RANGES)


def split_runs(text):
    """Split text into (is_myanmar, substring) runs. Spaces/Latin/WoW codes are not Myanmar."""
    runs, cur, cur_m = [], "", None
    for ch in text:
        m = is_myanmar(ch)
        if cur_m is None or m == cur_m:
            cur += ch
            cur_m = m
        else:
            runs.append((cur_m, cur))
            cur, cur_m = ch, m
    if cur:
        runs.append((cur_m, cur))
    return runs


# ---------------------------------------------------------------- shapers
class HBShaper:
    """Real shaping through HarfBuzz."""
    def __init__(self, font_path):
        import uharfbuzz as hb
        self.hb = hb
        face = hb.Face(hb.Blob.from_file_path(font_path))
        self.font = hb.Font(face)
        self.font.scale = (face.upem, face.upem)

    def shape(self, text):
        hb = self.hb
        buf = hb.Buffer()
        buf.add_str(text)
        buf.guess_segment_properties()
        buf.script, buf.language, buf.direction = "Mymr", "my", "ltr"
        hb.shape(self.font, buf, {})
        return [(i.codepoint, i.cluster, p.x_advance, p.x_offset, p.y_offset)
                for i, p in zip(buf.glyph_infos, buf.glyph_positions)]


class NaiveShaper:
    """NO real shaping: base letter + following marks, marks get zero advance.
    Only for checking that the font-building code works."""
    def __init__(self, font_path):
        f = TTFont(font_path)
        self.cmap, self.order = f.getBestCmap(), f.getGlyphOrder()
        self.gid = {n: i for i, n in enumerate(self.order)}
        self.hmtx = f["hmtx"]

    def shape(self, text):
        out, cluster = [], 0
        for i, ch in enumerate(text):
            name = self.cmap.get(ord(ch), ".notdef")
            mark = unicodedata.category(ch).startswith("M") and i > 0
            if not mark:
                cluster = i
            adv = 0 if mark else self.hmtx[name][0]
            out.append((self.gid[name], cluster, adv, 0, 0))
        return out


def split_clusters(shaper, run):
    glyphs = shaper.shape(run)
    starts = sorted({g[1] for g in glyphs})
    if not starts or starts[0] != 0 or starts[-1] >= len(run):
        raise SystemExit("Unexpected HarfBuzz cluster values for %r: %r" % (run, starts))
    return [run[s:(starts[i + 1] if i + 1 < len(starts) else len(run))]
            for i, s in enumerate(starts)]


def encode_text(shaper, mapping, text, missing=None):
    out = []
    for m, seg in split_runs(text):
        if not m:
            out.append(seg)
            continue
        for unit in split_clusters(shaper, seg):
            cp = mapping.get(unit)
            if cp is None:
                if missing is not None:
                    missing.add(unit)
                continue
            out.append(chr(cp))
    return "".join(out)


# ---------------------------------------------------------------- font
def build_font(font_path, shaper, units, out_font, margin=40):
    font = TTFont(font_path)
    order = font.getGlyphOrder()
    glyphset = font.getGlyphSet()
    cmap_existing = set(font.getBestCmap())
    free = [c for c in range(PUA_START, PUA_END + 1) if c not in cmap_existing]
    if len(units) > len(free):
        raise SystemExit("Too many distinct syllables (%d) for the BMP private use area (%d)."
                         % (len(units), len(free)))
    glyf, hmtx = font["glyf"], font["hmtx"]
    new_order, mapping, made = list(order), {}, []
    names_for_report = {}
    for unit, cp in zip(units, free):
        pieces = shaper.shape(unit)
        pen = TTGlyphPen(None)
        x = 0
        for gid, _cl, adv, xo, yo in pieces:
            rec = DecomposingRecordingPen(glyphset)
            glyphset[order[gid]].draw(rec)
            rec.replay(TransformPen(pen, (1, 0, 0, 1, x + xo, yo)))
            x += adv
        g = pen.glyph()
        name = "mm%04X" % cp
        glyf.glyphs[name] = g
        new_order.append(name)
        made.append((name, g, x))
        mapping[unit] = cp
        names_for_report[name] = unit
    font.setGlyphOrder(new_order)
    glyf.glyphOrder = new_order
    for name, g, adv in made:
        if g.numberOfContours != 0:
            g.recalcBounds(glyf)
            lsb = g.xMin
        else:
            lsb = 0
        hmtx.metrics[name] = (int(adv), int(lsb))
    # WoW crops every glyph to at most 1 em (the requested font size) in height.
    # Syllables with marks above AND below a letter are taller than 1000 units, so
    # we enlarge the font's em (unitsPerEm) until the tallest one fits. The outlines
    # are untouched; the text just renders smaller by 1000/unitsPerEm, so the add-on
    # must request font sizes multiplied by the returned scale.
    old_upem = font["head"].unitsPerEm
    inked = [(g.yMax - g.yMin, g.yMin, g.yMax, n) for n, g, _ in made if g.numberOfContours != 0]
    new_upem = old_upem
    if inked:
        tallest = max(t[0] for t in inked)
        need = tallest + margin
        new_upem = max(old_upem, -(-need // 100) * 100)
        print("Tallest syllable is %d units high (font size = %d units)." % (tallest, old_upem))
        print("Tallest syllables:")
        for h, y0, y1, n in sorted(inked, reverse=True)[:5]:
            print("   %5d  %s" % (h, names_for_report[n]))
    font["head"].unitsPerEm = new_upem
    scale = new_upem / float(old_upem)
    print("unitsPerEm set to %d -> request font sizes x%.2f" % (new_upem, scale))
    hit = False
    for st in font["cmap"].tables:
        if st.isUnicode() and st.format in (4, 12):
            hit = True
            for unit, cp in mapping.items():
                st.cmap[cp] = "mm%04X" % cp
    if not hit:
        raise SystemExit("No usable Unicode cmap subtable in the font.")
    for t in ("GSUB", "GPOS", "GDEF", "STAT"):
        if t in font:
            del font[t]
    font["post"].formatType = 3.0
    make_parent(out_font)
    font.save(out_font)
    return mapping, scale


# ---------------------------------------------------------------- io
def make_parent(path):
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)


def write_preview(path, font_path, encoded, scale=1.0):
    """Draw the encoded strings with the built font, outside the game (needs Pillow)."""
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("(Pillow not installed - skipping preview. Optional: pip install pillow)")
        return
    fnt = ImageFont.truetype(font_path, int(44 * scale), layout_engine=ImageFont.Layout.BASIC)
    row = 72
    im = Image.new("RGB", (1800, row * len(encoded) + 20), "black")
    d = ImageDraw.Draw(im)
    for i, s in enumerate(encoded):
        d.text((10, 10 + i * row), s, font=fnt, fill="white")
    make_parent(path)
    im.save(path)
    print("wrote preview image", path)


def read_lines(paths):
    lines = []
    for p in paths:
        with open(p, encoding="utf-8-sig") as f:
            for ln in f.read().splitlines():
                if ln.strip() and not ln.startswith("#"):
                    lines.append(ln)
    return lines


def lua_string(s):
    out = []
    for b in s.encode("utf-8"):
        c = chr(b)
        if c == '"' or c == "\\":
            out.append("\\" + c)
        elif 32 <= b < 127:
            out.append(c)
        else:
            out.append("\\%03d" % b)
    return '"' + "".join(out) + '"'


def write_lua(path, encoded, var, scale=1.0):
    make_parent(path)
    with open(path, "w", encoding="ascii", newline="\n") as f:
        f.write("-- Generated by mm_preshape.py. Do not edit; Myanmar text is stored as\n"
                "-- private-use characters that only the matching shaped font can draw.\n")
        f.write("%s_SCALE = %s  -- multiply requested font sizes by this\n" % (var, repr(round(scale, 4))))
        f.write("%s = {\n" % var)
        for i, s in enumerate(encoded, 1):
            f.write("  [%d] = %s,\n" % (i, lua_string(s)))
        f.write("}\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("--font", required=True)
    b.add_argument("--input", nargs="+", required=True, help="UTF-8 text files, one string per line")
    b.add_argument("--out-font", required=True)
    b.add_argument("--out-lua", required=True)
    b.add_argument("--out-clusters", default="clusters.json")
    b.add_argument("--lua-var", default="MM_ENCODED")
    b.add_argument("--preview", help="optional PNG showing the result outside the game (needs Pillow)")
    b.add_argument("--margin", type=int, default=40,
                   help="safety margin (font units) added to the tallest syllable when choosing the em size")
    b.add_argument("--naive", action="store_true", help="debug only: no real shaping")
    e = sub.add_parser("encode")
    e.add_argument("--font", required=True, help="the ORIGINAL font (used to find syllable boundaries)")
    e.add_argument("--clusters", default="clusters.json")
    e.add_argument("--input", nargs="+", required=True)
    e.add_argument("--out-lua", required=True)
    e.add_argument("--lua-var", default="MM_ENCODED")
    e.add_argument("--naive", action="store_true")
    a = ap.parse_args()

    shaper = (NaiveShaper if a.naive else HBShaper)(a.font)
    lines = read_lines(a.input)

    if a.cmd == "build":
        units, seen = [], set()
        for ln in lines:
            for m, seg in split_runs(ln):
                if m:
                    for u in split_clusters(shaper, seg):
                        if u not in seen:
                            seen.add(u)
                            units.append(u)
        mapping, scale = build_font(a.font, shaper, units, a.out_font, a.margin)
        make_parent(a.out_clusters)
        with open(a.out_clusters, "w", encoding="utf-8") as f:
            json.dump({"scale": scale, "map": mapping}, f, ensure_ascii=False, indent=1)
        print("%d distinct syllables -> %d of %d private-use slots"
              % (len(units), len(units), PUA_END - PUA_START + 1))
    else:
        with open(a.clusters, encoding="utf-8") as f:
            data = json.load(f)
        mapping = data["map"] if "map" in data else data
        scale = data.get("scale", 1.0) if "map" in data else 1.0

    missing = set()
    encoded = [encode_text(shaper, mapping, ln, missing) for ln in lines]
    if missing:
        print("These syllables are not in the font yet; re-run 'build' with all text:")
        for u in sorted(missing):
            print("  ", u, [hex(ord(c)) for c in u])
        raise SystemExit(1)
    write_lua(a.out_lua, encoded, a.lua_var, scale)
    print("wrote", a.out_lua, "(%d strings)" % len(encoded))
    if a.cmd == "build" and a.preview:
        write_preview(a.preview, a.out_font, encoded, scale)


if __name__ == "__main__":
    main()
