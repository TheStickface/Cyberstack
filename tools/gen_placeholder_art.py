"""
Generates basic placeholder art for units (portraits) and augments (icons),
and wires the results into the corresponding .tres resource files.

Safe to re-run: existing portrait/icon images are regenerated (so palette/
style tweaks apply to everyone), but .tres files that are already wired are
left alone. Run this again after adding new units/augments to data/units or
data/augments to generate art for them automatically.

Usage:
    python tools/gen_placeholder_art.py

Requires Pillow (`pip install pillow`) and a Consolas-family font (bundled
with Windows). Swap FONT_BOLD/FONT_REG below if running elsewhere.
"""
import re
import glob
import os
import math
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UNITS_DIR = os.path.join(ROOT, "data", "units")
AUGS_DIR = os.path.join(ROOT, "data", "augments")
PORTRAIT_OUT = os.path.join(ROOT, "assets", "portraits")
ICON_OUT = os.path.join(ROOT, "assets", "icons", "augments")

FONT_BOLD = "C:/Windows/Fonts/consolab.ttf"
FONT_REG = "C:/Windows/Fonts/consola.ttf"

BG = (8, 7, 16, 255)

# Faction (Enums.Faction) -> accent color / label
FACTION_COLORS = {
    1: (0, 245, 212),    # STREET_RUNNERS - cyan
    2: (0, 180, 216),    # CORP_ENFORCERS - electric blue
    3: (150, 60, 255),   # ROGUE_AIS - neon purple (brightened for legibility)
    4: (255, 0, 110),    # FIXERS - hot pink
    5: (50, 240, 80),    # BIO_HACKERS - acid green
    6: (170, 70, 255),   # NET_PHANTOMS - violet
}
FACTION_ABBR = {1: "RUN", 2: "CORP", 3: "AI", 4: "FIX", 5: "BIO", 6: "GHOST"}

# AugmentTier (Enums.AugmentTier) -> accent color / label
TIER_COLORS = {
    0: (0, 180, 216),    # COMMON - electric blue
    1: (170, 90, 255),   # RARE - purple (brightened)
    2: (255, 40, 130),   # LEGENDARY - hot pink/red
}
TIER_NAMES = {0: "C", 1: "R", 2: "L"}

# AugmentTag (Enums.AugmentTag) -> glyph color
TAG_COLORS = {
    1: (70, 255, 40),    # VIRAL - toxic green
    2: (255, 100, 20),   # THERMAL - orange
    3: (30, 210, 255),   # NEURAL - cyan-blue
    4: (255, 214, 10),   # KINETIC - amber
}

# UnitRole (Enums.UnitRole) -> badge shape / label
ROLE_SHAPE_SIDES = {0: 6, 1: 4, 2: 3, 3: 5, 4: 8, 5: 7}  # tank hex, hacker diamond, sniper triangle, fixer pentagon, meatshield octagon, commander heptagon
ROLE_ABBR = {0: "TANK", 1: "HACK", 2: "SNIPE", 3: "FIXER", 4: "MEAT", 5: "CMDR"}


# ---------- .tres parsing ----------

def parse_field(text: str, name: str, cast: type = str):
    m = re.search(rf'^{name}\s*=\s*(.+)$', text, re.M)
    if not m:
        raise ValueError(f"field '{name}' not found")
    val = m.group(1).strip()
    return val.strip('"') if cast is str else cast(val)


def load_units():
    units = []
    for path in sorted(glob.glob(os.path.join(UNITS_DIR, "*.tres"))):
        text = open(path, encoding="utf-8").read()
        units.append({
            "path": path,
            "id": parse_field(text, "id"),
            "display_name": parse_field(text, "display_name"),
            "role": int(parse_field(text, "role", int)),
            "faction": int(parse_field(text, "faction", int)),
        })
    return units


def load_augments():
    augs = []
    for path in sorted(glob.glob(os.path.join(AUGS_DIR, "*.tres"))):
        text = open(path, encoding="utf-8").read()
        tags_m = re.search(r'tags\s*=\s*Array\[int\]\(\[([^\]]*)\]\)', text)
        tag = int(tags_m.group(1).split(",")[0].strip()) if tags_m and tags_m.group(1).strip() else 0
        augs.append({
            "path": path,
            "id": parse_field(text, "id"),
            "display_name": parse_field(text, "display_name"),
            "tier": int(parse_field(text, "tier", int)),
            "tag": tag,
        })
    return augs


def monogram_for(display_name):
    words = [w for w in re.split(r"[ .\-_/]+", display_name) if w]
    if len(words) >= 2:
        return (words[0][0] + words[1][0]).upper()
    if words:
        return words[0][:2].upper() if len(words[0]) >= 2 else words[0].upper()
    return "??"


def dedupe_monograms(units):
    """Disambiguate monograms that collide within the same faction+role
    visual group (same color + same badge shape), since that's the only
    case where two portraits would otherwise be hard to tell apart."""
    seen = {}
    for u in units:
        mono = monogram_for(u["display_name"])
        bucket = seen.setdefault((u["faction"], u["role"]), {})
        if mono in bucket:
            alt = re.sub(r"[ .\-_/]", "", u["display_name"])
            for extra_len in (3, 4, 5):
                cand = alt[:extra_len].upper()
                if cand not in bucket:
                    mono = cand
                    break
        bucket[mono] = u["id"]
        u["monogram"] = mono
    return units


# ---------- drawing helpers ----------

def regular_polygon(cx, cy, r, sides, rotation=-90):
    pts = []
    for i in range(sides):
        ang = math.radians(rotation + i * 360 / sides)
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    return pts


def draw_corner_brackets(draw, size, color, margin=8, length=14, width=3):
    s = size
    corners = [
        [(margin, margin + length), (margin, margin), (margin + length, margin)],
        [(s - margin - length, margin), (s - margin, margin), (s - margin, margin + length)],
        [(margin, s - margin - length), (margin, s - margin), (margin + length, s - margin)],
        [(s - margin - length, s - margin), (s - margin, s - margin), (s - margin, s - margin - length)],
    ]
    for pts in corners:
        draw.line(pts, fill=color, width=width, joint="curve")


def draw_centered_text(draw, cx, cy, text, font, fill):
    bbox = draw.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((cx - w / 2 - bbox[0], cy - h / 2 - bbox[1]), text, font=font, fill=fill)


def make_portrait(unit, size=128):
    img = Image.new("RGBA", (size, size), BG)
    draw = ImageDraw.Draw(img)
    color = FACTION_COLORS[unit["faction"]]
    role = unit["role"]

    # subtle vertical gradient wash in faction color
    for y in range(size):
        t = y / size
        a = max(0, int(26 * (1 - abs(t - 0.5) * 1.4)))
        draw.line([(0, y), (size, y)], fill=(*color, a))

    cx, cy = size / 2, size / 2 - 4
    r = size * 0.36
    sides = ROLE_SHAPE_SIDES.get(role, 6)
    rotation = -45 if sides == 4 else -90
    draw.polygon(regular_polygon(cx, cy, r, sides, rotation), fill=(*color, 40), outline=(*color, 230))
    draw.polygon(regular_polygon(cx, cy, r - 5, sides, rotation), outline=(*color, 110))

    draw_corner_brackets(draw, size, (*color, 255))

    font_mono = ImageFont.truetype(FONT_BOLD, int(size * 0.34))
    draw_centered_text(draw, cx, cy, unit["monogram"], font_mono, (245, 245, 255, 255))

    font_small = ImageFont.truetype(FONT_BOLD, 11)
    label = f'{ROLE_ABBR.get(role, "?")} \u00b7 {FACTION_ABBR.get(unit["faction"], "?")}'
    draw_centered_text(draw, size / 2, size - 12, label, font_small, (*color, 255))

    font_id = ImageFont.truetype(FONT_REG, 9)
    draw_centered_text(draw, size / 2, 11, unit["id"], font_id, (150, 150, 165, 200))

    return img


def draw_bolt(draw, cx, cy, s, color):
    pts = [
        (cx + 0.05*s, cy - 0.45*s), (cx - 0.28*s, cy + 0.05*s), (cx - 0.02*s, cy + 0.05*s),
        (cx - 0.10*s, cy + 0.45*s), (cx + 0.30*s, cy - 0.10*s), (cx + 0.02*s, cy - 0.10*s),
    ]
    draw.polygon(pts, fill=color)


def draw_flame(draw, cx, cy, s, color):
    pts = [
        (cx, cy + 0.42*s),
        (cx - 0.26*s, cy + 0.18*s),
        (cx - 0.22*s, cy - 0.10*s),
        (cx - 0.06*s, cy - 0.02*s),
        (cx - 0.08*s, cy - 0.40*s),
        (cx + 0.14*s, cy - 0.18*s),
        (cx + 0.24*s, cy + 0.08*s),
        (cx + 0.10*s, cy + 0.05*s),
        (cx + 0.20*s, cy + 0.30*s),
    ]
    draw.polygon(pts, fill=color)
    draw.ellipse([cx - 0.07*s, cy + 0.08*s, cx + 0.07*s, cy + 0.30*s], fill=BG)


def draw_neural(draw, cx, cy, s, color):
    draw.ellipse([cx - 0.09*s, cy - 0.09*s, cx + 0.09*s, cy + 0.09*s], fill=color)
    for ang in range(0, 360, 60):
        a = math.radians(ang)
        nx, ny = cx + 0.38*s*math.cos(a), cy + 0.38*s*math.sin(a)
        draw.line([(cx, cy), (nx, ny)], fill=color, width=max(2, int(s*0.03)))
        r = 0.075*s
        draw.ellipse([nx - r, ny - r, nx + r, ny + r], fill=color)


def draw_viral(draw, cx, cy, s, color):
    for ang in (90, 210, 330):
        a = math.radians(ang)
        ox, oy = cx + 0.20*s*math.cos(a), cy + 0.20*s*math.sin(a)
        r = 0.17*s
        draw.ellipse([ox - r, oy - r, ox + r, oy + r], outline=color, width=max(3, int(s*0.045)))
    r2 = 0.09*s
    draw.ellipse([cx - r2, cy - r2, cx + r2, cy + r2], fill=color)


TAG_DRAW = {1: draw_viral, 2: draw_flame, 3: draw_neural, 4: draw_bolt}


def make_augment_icon(aug, size=96):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    tier_color = TIER_COLORS[aug["tier"]]
    tag_color = TAG_COLORS.get(aug["tag"], (200, 200, 200))
    pad, corner = 3, 10

    draw.rounded_rectangle([pad, pad, size - pad, size - pad], radius=corner,
                            fill=(9, 8, 18, 235), outline=tier_color, width=2 + aug["tier"])
    if aug["tier"] >= 1:
        draw.rounded_rectangle([pad + 4, pad + 4, size - pad - 4, size - pad - 4], radius=corner - 3,
                                outline=(*tier_color, 130), width=1)
    if aug["tier"] == 2:
        d = 6
        for cx, cy in [(pad+d, pad+d), (size-pad-d, pad+d), (pad+d, size-pad-d), (size-pad-d, size-pad-d)]:
            draw.polygon(regular_polygon(cx, cy, 5, 4, 0), fill=tier_color)

    glyph_fn = TAG_DRAW.get(aug["tag"])
    if glyph_fn:
        glyph_fn(draw, size / 2, size / 2 - 4, size * 0.62, tag_color)

    pip_count = aug["tier"] + 1
    pip_r = 3
    total_w = pip_count * (pip_r * 2 + 4) - 4
    start_x = size / 2 - total_w / 2 + pip_r
    py = size - 12
    for i in range(pip_count):
        px = start_x + i * (pip_r * 2 + 4)
        draw.ellipse([px - pip_r, py - pip_r, px + pip_r, py + pip_r], fill=tier_color)

    font_tier = ImageFont.truetype(FONT_BOLD, 12)
    draw.text((pad + 4, pad + 2), TIER_NAMES[aug["tier"]], font=font_tier, fill=(*tier_color, 255))

    return img


# ---------- .tres wiring ----------

def wire_resource(path, res_relpath, field_name, ext_id):
    text = open(path, encoding="utf-8").read()
    if f"{field_name} = ExtResource(" in text:
        return False
    text = re.sub(r'(load_steps=)(\d+)', lambda m: f"{m.group(1)}{int(m.group(2)) + 1}", text, count=1)
    ext_line = f'[ext_resource type="Texture2D" path="res://{res_relpath}" id="{ext_id}"]\n'
    m = re.search(r'(\[ext_resource type="Script"[^\n]*\n)', text)
    text = text[:m.end()] + ext_line + text[m.end():]
    m2 = re.search(r'(script = ExtResource\("[^"]+"\)\n)', text)
    text = text[:m2.end()] + f'{field_name} = ExtResource("{ext_id}")\n' + text[m2.end():]
    open(path, "w", encoding="utf-8").write(text)
    return True


def main():
    os.makedirs(PORTRAIT_OUT, exist_ok=True)
    os.makedirs(ICON_OUT, exist_ok=True)

    units = dedupe_monograms(load_units())
    for u in units:
        make_portrait(u).save(os.path.join(PORTRAIT_OUT, f"{u['id']}.png"))
        wired = wire_resource(u["path"], f"assets/portraits/{u['id']}.png", "portrait", "2_portrait")
        print(("wired " if wired else "image  "), "unit", u["id"], u["monogram"])

    augs = load_augments()
    for a in augs:
        make_augment_icon(a).save(os.path.join(ICON_OUT, f"{a['id']}.png"))
        wired = wire_resource(a["path"], f"assets/icons/augments/{a['id']}.png", "icon", "2_icon")
        print(("wired " if wired else "image  "), "augment", a["id"])

    print(f"\n{len(units)} unit portraits, {len(augs)} augment icons generated.")


if __name__ == "__main__":
    main()
