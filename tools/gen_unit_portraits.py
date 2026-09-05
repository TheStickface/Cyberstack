"""
Cyberstack Unique Unit Portrait Generator
Draws a unique thematic placeholder image for every unit in Cyberstack.
Renders supersampled (2x) antialiased graphics into assets/portraits/<id>.png.
"""
import math
import os
import glob
import re
from PIL import Image, ImageDraw, ImageFont

ROOT = "c:/Dev/Cyberstack"
UNITS_DIR = os.path.join(ROOT, "data", "units")
PORTRAIT_OUT = os.path.join(ROOT, "assets", "portraits")

FONT_BOLD = "C:/Windows/Fonts/consolab.ttf"
FONT_REG = "C:/Windows/Fonts/consola.ttf"

BG = (10, 9, 18, 255)

FACTION_COLORS = {
    1: (0, 245, 212),    # STREET_RUNNERS - cyan
    2: (0, 180, 216),    # CORP_ENFORCERS - electric blue
    3: (160, 80, 255),   # ROGUE_AIS - neon purple
    4: (255, 0, 110),    # FIXERS - hot pink
    5: (50, 240, 80),    # BIO_HACKERS - acid green
    6: (180, 80, 255),   # NET_PHANTOMS - violet
}
FACTION_ABBR = {1: "RUN", 2: "CORP", 3: "AI", 4: "FIX", 5: "BIO", 6: "GHOST"}

ROLE_SHAPE_SIDES = {0: 6, 1: 4, 2: 3, 3: 5, 4: 8, 5: 7}
ROLE_ABBR = {0: "TANK", 1: "HACK", 2: "SNIPE", 3: "FIXER", 4: "MEAT", 5: "CMDR"}

def blend(c1, c2, factor):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * factor) for i in range(3)) + (255,)

def circle(draw, cx, cy, r, fill=None, outline=None, width=1):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=outline, width=width)

def rect(draw, x1, y1, x2, y2, fill=None, outline=None, width=1):
    draw.rectangle([x1, y1, x2, y2], fill=fill, outline=outline, width=width)

def regular_polygon(cx, cy, r, sides, rotation=-90):
    pts = []
    for i in range(sides):
        ang = math.radians(rotation + i * 360 / sides)
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    return pts

def star_points(cx, cy, r_out, r_in, points, rotation=-90):
    pts = []
    for i in range(points * 2):
        r = r_out if i % 2 == 0 else r_in
        ang = math.radians(rotation + i * 180 / points)
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

def draw_centered_text(draw, cx, cy, text, font, fill, max_w=None):
    bbox = draw.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    if max_w and w > max_w:
        cur_size = font.size
        new_size = max(10, int(cur_size * (max_w / w)))
        font = ImageFont.truetype(font.path, new_size)
        bbox = draw.textbbox((0, 0), text, font=font)
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((cx - w / 2 - bbox[0], cy - h / 2 - bbox[1]), text, font=font, fill=fill)


# ============================================================================
# ROGUE AIs (11 units)
# ============================================================================

def draw_ai_bastion(draw, cx, cy, s, color, fg):
    pts = [
        (cx - 0.36*s, cy - 0.35*s), (cx - 0.20*s, cy - 0.35*s),
        (cx - 0.20*s, cy - 0.20*s), (cx - 0.08*s, cy - 0.20*s),
        (cx - 0.08*s, cy - 0.35*s), (cx + 0.08*s, cy - 0.35*s),
        (cx + 0.08*s, cy - 0.20*s), (cx + 0.20*s, cy - 0.20*s),
        (cx + 0.20*s, cy - 0.35*s), (cx + 0.36*s, cy - 0.35*s),
        (cx + 0.36*s, cy + 0.10*s), (cx, cy + 0.44*s),
        (cx - 0.36*s, cy + 0.10*s),
    ]
    draw.polygon(pts, fill=blend(BG, color, 0.25), outline=fg, width=2)
    draw.line([(cx, cy - 0.10*s), (cx, cy + 0.26*s)], fill=color, width=4)
    circle(draw, cx, cy + 0.05*s, 0.07*s, fill=fg)

def draw_ai_byte(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.30*s, cy - 0.30*s, cx + 0.30*s, cy + 0.30*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    rect(draw, cx - 0.15*s, cy - 0.15*s, cx + 0.15*s, cy + 0.15*s, fill=color, outline=fg, width=1)
    for offset in (-0.18*s, 0, 0.18*s):
        draw.line([(cx + offset, cy - 0.30*s), (cx + offset, cy - 0.44*s)], fill=color, width=2)
        draw.line([(cx + offset, cy + 0.30*s), (cx + offset, cy + 0.44*s)], fill=color, width=2)
        draw.line([(cx - 0.30*s, cy + offset), (cx - 0.44*s, cy + offset)], fill=color, width=2)
        draw.line([(cx + 0.30*s, cy + offset), (cx + 0.44*s, cy + offset)], fill=color, width=2)

def draw_ai_cipher(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy + 0.10*s, 0.32*s, fill=blend(BG, color, 0.25), outline=fg, width=2)
    draw.arc([cx - 0.20*s, cy - 0.40*s, cx + 0.20*s, cy], 180, 0, fill=fg, width=3)
    circle(draw, cx, cy + 0.06*s, 0.07*s, fill=color)
    draw.polygon([(cx - 0.05*s, cy + 0.08*s), (cx + 0.05*s, cy + 0.08*s),
                  (cx + 0.07*s, cy + 0.24*s), (cx - 0.07*s, cy + 0.24*s)], fill=color)

def draw_ai_dreadnought(draw, cx, cy, s, color, fg):
    pts = [
        (cx, cy - 0.46*s), (cx + 0.38*s, cy + 0.35*s), (cx + 0.20*s, cy + 0.26*s),
        (cx, cy + 0.36*s), (cx - 0.20*s, cy + 0.26*s), (cx - 0.38*s, cy + 0.35*s),
    ]
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    draw.line([(cx - 0.14*s, cy), (cx - 0.14*s, cy - 0.25*s)], fill=color, width=3)
    draw.line([(cx + 0.14*s, cy), (cx + 0.14*s, cy - 0.25*s)], fill=color, width=3)
    circle(draw, cx, cy, 0.08*s, fill=fg)

def draw_ai_glitch(draw, cx, cy, s, color, fg):
    pts1 = [(cx - 0.32*s, cy - 0.40*s), (cx + 0.15*s, cy - 0.38*s), (cx - 0.05*s, cy - 0.05*s), (cx - 0.35*s, cy - 0.10*s)]
    pts2 = [(cx - 0.10*s, cy - 0.02*s), (cx + 0.38*s, cy - 0.15*s), (cx + 0.25*s, cy + 0.25*s), (cx + 0.02*s, cy + 0.15*s)]
    pts3 = [(cx - 0.30*s, cy + 0.05*s), (cx - 0.02*s, cy + 0.20*s), (cx + 0.10*s, cy + 0.44*s), (cx - 0.25*s, cy + 0.40*s)]
    draw.polygon(pts1, fill=blend(BG, color, 0.35), outline=fg, width=2)
    draw.polygon(pts2, fill=color, outline=fg, width=2)
    draw.polygon(pts3, fill=blend(BG, color, 0.4), outline=fg, width=2)
    draw.line([(cx - 0.45*s, cy - 0.18*s), (cx + 0.45*s, cy - 0.18*s)], fill=color, width=2)
    draw.line([(cx - 0.35*s, cy + 0.28*s), (cx + 0.40*s, cy + 0.28*s)], fill=color, width=2)

def draw_ai_null_construct(draw, cx, cy, s, color, fg):
    r = 0.34 * s
    top = [(cx, cy - r), (cx + r * 0.86, cy - r * 0.5), (cx, cy), (cx - r * 0.86, cy - r * 0.5)]
    left = [(cx - r * 0.86, cy - r * 0.5), (cx, cy), (cx, cy + r), (cx - r * 0.86, cy + r * 0.5)]
    right = [(cx, cy), (cx + r * 0.86, cy - r * 0.5), (cx + r * 0.86, cy + r * 0.5), (cx, cy + r)]
    draw.polygon(top, fill=blend(BG, color, 0.4), outline=fg, width=2)
    draw.polygon(left, fill=blend(BG, color, 0.2), outline=fg, width=2)
    draw.polygon(right, fill=blend(BG, color, 0.25), outline=fg, width=2)
    circle(draw, cx, cy, 0.07*s, fill=color)

def draw_ai_singularity(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.16*s, fill=BG, outline=color, width=3)
    for r, start in ((0.26*s, 0), (0.36*s, 120), (0.44*s, 240)):
        draw.arc([cx - r, cy - r, cx + r, cy + r], start, start + 240, fill=fg, width=2)
    circle(draw, cx, cy, 0.08*s, fill=color)

def draw_ai_siphon(draw, cx, cy, s, color, fg):
    pts = [(cx - 0.38*s, cy - 0.38*s), (cx + 0.38*s, cy - 0.38*s), (cx, cy + 0.42*s)]
    draw.polygon(pts, fill=blend(BG, color, 0.25), outline=fg, width=2)
    draw.line([(cx - 0.25*s, cy - 0.12*s), (cx + 0.25*s, cy - 0.12*s)], fill=color, width=2)
    draw.line([(cx - 0.13*s, cy + 0.14*s), (cx + 0.13*s, cy + 0.14*s)], fill=color, width=2)
    circle(draw, cx, cy + 0.46*s, 0.04*s, fill=color)

def draw_ai_spindle(draw, cx, cy, s, color, fg):
    draw.ellipse([cx - 0.40*s, cy - 0.16*s, cx + 0.40*s, cy + 0.16*s], outline=fg, width=2)
    draw.ellipse([cx - 0.18*s, cy - 0.40*s, cx + 0.18*s, cy + 0.40*s], outline=color, width=2)
    draw.polygon([(cx, cy - 0.46*s), (cx + 0.05*s, cy), (cx, cy + 0.46*s), (cx - 0.05*s, cy)], fill=fg)
    circle(draw, cx, cy, 0.08*s, fill=color)

def draw_ai_vector(draw, cx, cy, s, color, fg):
    draw.line([(cx, cy), (cx + 0.36*s, cy - 0.36*s)], fill=fg, width=3)
    draw.line([(cx, cy), (cx - 0.36*s, cy - 0.15*s)], fill=color, width=3)
    draw.line([(cx, cy), (cx, cy + 0.42*s)], fill=fg, width=3)
    draw.polygon([(cx + 0.36*s, cy - 0.36*s), (cx + 0.22*s, cy - 0.36*s), (cx + 0.36*s, cy - 0.22*s)], fill=fg)
    draw.polygon([(cx - 0.36*s, cy - 0.15*s), (cx - 0.24*s, cy - 0.24*s), (cx - 0.24*s, cy - 0.06*s)], fill=color)
    draw.polygon([(cx, cy + 0.42*s), (cx - 0.09*s, cy + 0.30*s), (cx + 0.09*s, cy + 0.30*s)], fill=fg)
    circle(draw, cx, cy, 0.06*s, fill=color)

def draw_ai_worm(draw, cx, cy, s, color, fg):
    points = [
        (cx - 0.32*s, cy + 0.28*s), (cx - 0.18*s, cy - 0.05*s),
        (cx + 0.02*s, cy + 0.18*s), (cx + 0.22*s, cy - 0.15*s),
        (cx + 0.36*s, cy - 0.35*s),
    ]
    for i, p in enumerate(points):
        r = (0.07 + i * 0.02) * s
        circle(draw, p[0], p[1], r, fill=blend(BG, color, 0.3 + i*0.1), outline=fg, width=2)
    head = points[-1]
    circle(draw, head[0] - 0.04*s, head[1] - 0.02*s, 0.03*s, fill=color)


# ============================================================================
# BIO-HACKERS (10 units)
# ============================================================================

def draw_bio_abomination(draw, cx, cy, s, color, fg):
    maw = regular_polygon(cx, cy, 0.38*s, 6)
    draw.polygon(maw, fill=blend(BG, color, 0.3), outline=fg, width=2)
    for i in range(6):
        a1 = math.radians(i * 60 - 90)
        a2 = math.radians((i + 1) * 60 - 90)
        px1, py1 = cx + 0.38*s*math.cos(a1), cy + 0.38*s*math.sin(a1)
        px2, py2 = cx + 0.38*s*math.cos(a2), cy + 0.38*s*math.sin(a2)
        mid_x, mid_y = (px1 + px2)/2, (py1 + py2)/2
        draw.polygon([(px1, py1), (px2, py2), (mid_x*0.6 + cx*0.4, mid_y*0.6 + cy*0.4)], fill=fg)
    circle(draw, cx, cy, 0.10*s, fill=color)

def draw_bio_chimera(draw, cx, cy, s, color, fg):
    draw.arc([cx - 0.44*s, cy - 0.44*s, cx, cy + 0.10*s], 180, 330, fill=fg, width=3)
    draw.arc([cx, cy - 0.44*s, cx + 0.44*s, cy + 0.10*s], 210, 360, fill=fg, width=3)
    pts = [(cx, cy - 0.20*s), (cx + 0.24*s, cy), (cx + 0.14*s, cy + 0.34*s),
           (cx, cy + 0.42*s), (cx - 0.14*s, cy + 0.34*s), (cx - 0.24*s, cy)]
    draw.polygon(pts, fill=blend(BG, color, 0.25), outline=fg, width=2)
    circle(draw, cx - 0.10*s, cy + 0.05*s, 0.04*s, fill=color)
    circle(draw, cx + 0.10*s, cy + 0.05*s, 0.04*s, fill=color)

def draw_bio_fleshweaver(draw, cx, cy, s, color, fg):
    draw.arc([cx - 0.35*s, cy - 0.40*s, cx + 0.35*s, cy + 0.25*s], 160, 340, fill=fg, width=3)
    circle(draw, cx - 0.30*s, cy - 0.10*s, 0.05*s, outline=fg, width=2)
    for offset in (-0.15*s, 0, 0.15*s, 0.30*s):
        y = cy + offset
        draw.line([(cx - 0.18*s, y), (cx + 0.18*s, y)], fill=color, width=3)
        circle(draw, cx - 0.18*s, y, 0.04*s, fill=fg)
        circle(draw, cx + 0.18*s, y, 0.04*s, fill=fg)

def draw_bio_gorgon(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.34*s, fill=blend(BG, color, 0.25), outline=fg, width=2)
    draw.arc([cx - 0.30*s, cy - 0.30*s, cx + 0.30*s, cy + 0.30*s], 45, 270, fill=color, width=3)
    pts = [(cx - 0.22*s, cy), (cx, cy - 0.14*s), (cx + 0.22*s, cy), (cx, cy + 0.14*s)]
    draw.polygon(pts, fill=BG, outline=fg, width=2)
    draw.line([(cx, cy - 0.14*s), (cx, cy + 0.14*s)], fill=color, width=4)

def draw_bio_hydra(draw, cx, cy, s, color, fg):
    for ang in (-35, 0, 35):
        rad = math.radians(ang - 90)
        hx = cx + 0.36*s*math.cos(rad)
        hy = cy + 0.36*s*math.sin(rad)
        draw.line([(cx, cy + 0.35*s), (hx, hy)], fill=color, width=3)
        draw.polygon([(hx, hy - 0.08*s), (hx + 0.08*s, hy), (hx, hy + 0.08*s), (hx - 0.08*s, hy)],
                     fill=blend(BG, color, 0.3), outline=fg, width=2)
        circle(draw, hx, hy, 0.03*s, fill=color)

def draw_bio_leech(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.38*s, fill=blend(BG, color, 0.25), outline=fg, width=2)
    circle(draw, cx, cy, 0.24*s, fill=blend(BG, color, 0.4), outline=color, width=2)
    circle(draw, cx, cy, 0.10*s, fill=BG)
    for ang in range(0, 360, 45):
        rad = math.radians(ang)
        p1 = (cx + 0.36*s*math.cos(rad), cy + 0.36*s*math.sin(rad))
        p2 = (cx + 0.22*s*math.cos(rad), cy + 0.22*s*math.sin(rad))
        draw.line([p1, p2], fill=fg, width=2)

def draw_bio_manticore(draw, cx, cy, s, color, fg):
    draw.arc([cx - 0.30*s, cy - 0.36*s, cx + 0.35*s, cy + 0.40*s], 220, 440, fill=fg, width=3)
    barb = [(cx - 0.16*s, cy - 0.28*s), (cx - 0.38*s, cy - 0.38*s), (cx - 0.25*s, cy - 0.16*s)]
    draw.polygon(barb, fill=color, outline=fg, width=1)
    circle(draw, cx - 0.42*s, cy - 0.44*s, 0.04*s, fill=color)
    draw.line([(cx - 0.18*s, cy + 0.36*s), (cx + 0.18*s, cy + 0.36*s)], fill=color, width=3)

def draw_bio_plague_doctor(draw, cx, cy, s, color, fg):
    mask = [
        (cx - 0.22*s, cy - 0.30*s), (cx + 0.20*s, cy - 0.25*s), (cx + 0.25*s, cy + 0.05*s),
        (cx + 0.05*s, cy + 0.15*s), (cx - 0.40*s, cy + 0.42*s), (cx - 0.25*s, cy + 0.15*s),
        (cx - 0.28*s, cy - 0.05*s),
    ]
    draw.polygon(mask, fill=blend(BG, color, 0.3), outline=fg, width=2)
    circle(draw, cx + 0.08*s, cy - 0.08*s, 0.08*s, fill=color, outline=fg, width=2)

def draw_bio_symbiote(draw, cx, cy, s, color, fg):
    circle(draw, cx - 0.14*s, cy - 0.10*s, 0.24*s, fill=blend(BG, color, 0.25), outline=fg, width=2)
    circle(draw, cx + 0.14*s, cy + 0.10*s, 0.24*s, fill=blend(BG, color, 0.35), outline=color, width=2)
    circle(draw, cx, cy, 0.10*s, fill=color)

def draw_bio_viper(draw, cx, cy, s, color, fg):
    hood = [
        (cx, cy - 0.45*s), (cx + 0.40*s, cy - 0.15*s), (cx + 0.28*s, cy + 0.18*s),
        (cx + 0.15*s, cy + 0.38*s), (cx, cy + 0.26*s), (cx - 0.15*s, cy + 0.38*s),
        (cx - 0.28*s, cy + 0.18*s), (cx - 0.40*s, cy - 0.15*s),
    ]
    draw.polygon(hood, outline=fg, width=2, fill=blend(BG, color, 0.28))
    draw.line([(cx - 0.18*s, cy - 0.08*s), (cx - 0.08*s, cy - 0.02*s)], fill=color, width=3)
    draw.line([(cx + 0.18*s, cy - 0.08*s), (cx + 0.08*s, cy - 0.02*s)], fill=color, width=3)
    draw.polygon([(cx - 0.11*s, cy + 0.18*s), (cx - 0.06*s, cy + 0.46*s), (cx - 0.02*s, cy + 0.18*s)], fill=fg)
    draw.polygon([(cx + 0.11*s, cy + 0.18*s), (cx + 0.06*s, cy + 0.46*s), (cx + 0.02*s, cy + 0.18*s)], fill=fg)
    circle(draw, cx - 0.06*s, cy + 0.52*s, 0.03*s, fill=color)
    circle(draw, cx + 0.06*s, cy + 0.52*s, 0.03*s, fill=color)


# ============================================================================
# NET-PHANTOMS (10 units)
# ============================================================================

def draw_phantom_aegis(draw, cx, cy, s, color, fg):
    pts = [
        (cx, cy - 0.44*s), (cx + 0.34*s, cy - 0.30*s), (cx + 0.34*s, cy + 0.08*s),
        (cx, cy + 0.46*s), (cx - 0.34*s, cy + 0.08*s), (cx - 0.34*s, cy - 0.30*s),
    ]
    draw.polygon(pts, fill=blend(BG, color, 0.25), outline=fg, width=2)
    draw.polygon(regular_polygon(cx, cy, 0.16*s, 6), fill=color, outline=fg, width=1)

def draw_phantom_assassin(draw, cx, cy, s, color, fg):
    draw.line([(cx - 0.35*s, cy - 0.35*s), (cx + 0.35*s, cy + 0.35*s)], fill=fg, width=3)
    draw.line([(cx + 0.35*s, cy - 0.35*s), (cx - 0.35*s, cy + 0.35*s)], fill=fg, width=3)
    circle(draw, cx, cy, 0.22*s, outline=color, width=2)
    circle(draw, cx, cy, 0.06*s, fill=color)

def draw_phantom_bulwark(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.35*s, cy - 0.38*s, cx + 0.35*s, cy + 0.38*s, fill=blend(BG, color, 0.2), outline=fg, width=2)
    for y in (-0.18*s, 0, 0.18*s):
        draw.line([(cx - 0.35*s, cy + y), (cx + 0.35*s, cy + y)], fill=color, width=2)
    for x in (-0.16*s, 0, 0.16*s):
        draw.line([(cx + x, cy - 0.38*s), (cx + x, cy + 0.38*s)], fill=color, width=2)

def draw_phantom_eidolon(draw, cx, cy, s, color, fg):
    pts = [
        (cx, cy - 0.42*s), (cx + 0.32*s, cy - 0.18*s), (cx + 0.22*s, cy + 0.26*s),
        (cx, cy + 0.44*s), (cx - 0.22*s, cy + 0.26*s), (cx - 0.32*s, cy - 0.18*s),
    ]
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    draw.line([(cx, cy - 0.24*s), (cx, cy + 0.24*s)], fill=color, width=4)
    circle(draw, cx, cy, 0.07*s, fill=fg)

def draw_phantom_mirage(draw, cx, cy, s, color, fg):
    for dx, dy, col in ((-0.14*s, -0.10*s, blend(BG, color, 0.3)),
                       (0.14*s, 0.10*s, blend(BG, color, 0.4)),
                       (0, 0, fg)):
        draw.polygon(regular_polygon(cx + dx, cy + dy, 0.20*s, 3), outline=col, width=2)

def draw_phantom_nightshade(draw, cx, cy, s, color, fg):
    pts = [
        (cx, cy + 0.38*s), (cx + 0.24*s, cy + 0.15*s), (cx + 0.34*s, cy - 0.22*s),
        (cx + 0.10*s, cy - 0.38*s), (cx, cy - 0.18*s), (cx - 0.10*s, cy - 0.38*s),
        (cx - 0.34*s, cy - 0.22*s), (cx - 0.24*s, cy + 0.15*s),
    ]
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    circle(draw, cx, cy - 0.05*s, 0.08*s, fill=color)

def draw_phantom_nullifier(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.34*s, outline=fg, width=3)
    draw.line([(cx - 0.38*s, cy + 0.38*s), (cx + 0.38*s, cy - 0.38*s)], fill=color, width=4)
    circle(draw, cx, cy, 0.12*s, fill=color)

def draw_phantom_spectre(draw, cx, cy, s, color, fg):
    cowl = [
        (cx, cy - 0.44*s), (cx + 0.36*s, cy - 0.12*s), (cx + 0.26*s, cy + 0.38*s),
        (cx + 0.10*s, cy + 0.28*s), (cx, cy + 0.38*s), (cx - 0.10*s, cy + 0.28*s),
        (cx - 0.26*s, cy + 0.38*s), (cx - 0.36*s, cy - 0.12*s),
    ]
    draw.polygon(cowl, fill=blend(BG, color, 0.25), outline=fg, width=2)
    circle(draw, cx - 0.10*s, cy - 0.02*s, 0.04*s, fill=color)
    circle(draw, cx + 0.10*s, cy - 0.02*s, 0.04*s, fill=color)

def draw_phantom_whisper(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.08*s, fill=fg)
    for r in (0.18*s, 0.28*s, 0.38*s):
        draw.arc([cx - r, cy - r, cx + r, cy + r], -60, 60, fill=color, width=2)
        draw.arc([cx - r, cy - r, cx + r, cy + r], 120, 240, fill=color, width=2)

def draw_phantom_wraith(draw, cx, cy, s, color, fg):
    draw.arc([cx - 0.42*s, cy - 0.45*s, cx + 0.42*s, cy + 0.40*s], 210, 360, fill=fg, width=3)
    draw.line([(cx - 0.35*s, cy + 0.40*s), (cx + 0.18*s, cy - 0.30*s)], fill=color, width=3)
    circle(draw, cx + 0.20*s, cy - 0.32*s, 0.06*s, fill=fg)


# ============================================================================
# STREET RUNNERS (10 units)
# ============================================================================

def draw_runner_blitz(draw, cx, cy, s, color, fg):
    pts = [
        (cx + 0.10*s, cy - 0.45*s), (cx - 0.18*s, cy - 0.05*s),
        (cx - 0.02*s, cy - 0.05*s), (cx - 0.25*s, cy + 0.45*s),
        (cx + 0.15*s, cy + 0.02*s), (cx - 0.02*s, cy + 0.02*s),
    ]
    draw.polygon(pts, fill=color, outline=fg, width=2)

def draw_runner_dash(draw, cx, cy, s, color, fg):
    dart = [(cx + 0.38*s, cy), (cx - 0.20*s, cy - 0.30*s), (cx - 0.10*s, cy), (cx - 0.20*s, cy + 0.30*s)]
    draw.polygon(dart, fill=blend(BG, color, 0.3), outline=fg, width=2)
    draw.line([(cx - 0.44*s, cy - 0.18*s), (cx - 0.22*s, cy - 0.18*s)], fill=color, width=3)
    draw.line([(cx - 0.46*s, cy), (cx - 0.15*s, cy)], fill=color, width=3)
    draw.line([(cx - 0.44*s, cy + 0.18*s), (cx - 0.22*s, cy + 0.18*s)], fill=color, width=3)

def draw_runner_nexus(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.14*s, fill=blend(BG, color, 0.4), outline=fg, width=2)
    for ang in range(0, 360, 60):
        rad = math.radians(ang)
        nx, ny = cx + 0.34*s*math.cos(rad), cy + 0.34*s*math.sin(rad)
        draw.line([(cx, cy), (nx, ny)], fill=color, width=2)
        circle(draw, nx, ny, 0.05*s, fill=fg)

def draw_runner_overdrive(draw, cx, cy, s, color, fg):
    draw.arc([cx - 0.36*s, cy - 0.36*s, cx + 0.36*s, cy + 0.36*s], 135, 405, fill=fg, width=3)
    draw.line([(cx, cy + 0.05*s), (cx + 0.26*s, cy - 0.22*s)], fill=color, width=3)
    circle(draw, cx, cy + 0.05*s, 0.07*s, fill=fg)

def draw_runner_phantom(draw, cx, cy, s, color, fg):
    pts = [
        (cx + 0.35*s, cy - 0.20*s), (cx + 0.10*s, cy - 0.40*s),
        (cx - 0.15*s, cy - 0.10*s), (cx - 0.38*s, cy + 0.30*s),
        (cx - 0.10*s, cy + 0.15*s), (cx + 0.15*s, cy + 0.40*s),
    ]
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    circle(draw, cx + 0.22*s, cy - 0.32*s, 0.06*s, fill=color)

def draw_runner_rampart(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.35*s, cy - 0.30*s, cx + 0.35*s, cy + 0.35*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    rect(draw, cx - 0.22*s, cy - 0.12*s, cx + 0.22*s, cy - 0.02*s, fill=color)
    for x in (-0.24*s, 0.24*s):
        circle(draw, cx + x, cy + 0.18*s, 0.04*s, fill=fg)

def draw_runner_slasher(draw, cx, cy, s, color, fg):
    draw.polygon([(cx - 0.40*s, cy - 0.30*s), (cx + 0.35*s, cy + 0.35*s), (cx + 0.40*s, cy + 0.25*s), (cx - 0.30*s, cy - 0.38*s)], fill=fg)
    draw.polygon([(cx + 0.40*s, cy - 0.30*s), (cx - 0.35*s, cy + 0.35*s), (cx - 0.40*s, cy + 0.25*s), (cx + 0.30*s, cy - 0.38*s)], fill=color)
    circle(draw, cx, cy, 0.06*s, fill=blend(BG, color, 0.5))

def draw_runner_spark(draw, cx, cy, s, color, fg):
    pts = star_points(cx, cy, 0.44*s, 0.16*s, 8)
    draw.polygon(pts, fill=color, outline=fg, width=2)
    circle(draw, cx, cy, 0.08*s, fill=fg)

def draw_runner_volt(draw, cx, cy, s, color, fg):
    draw.line([(cx, cy - 0.42*s), (cx, cy + 0.40*s)], fill=fg, width=3)
    circle(draw, cx, cy - 0.32*s, 0.12*s, fill=blend(BG, color, 0.4), outline=color, width=2)
    draw.line([(cx - 0.32*s, cy - 0.20*s), (cx - 0.10*s, cy - 0.30*s)], fill=color, width=2)
    draw.line([(cx + 0.32*s, cy - 0.20*s), (cx + 0.10*s, cy - 0.30*s)], fill=color, width=2)
    rect(draw, cx - 0.25*s, cy + 0.25*s, cx + 0.25*s, cy + 0.42*s, fill=blend(BG, color, 0.25), outline=fg, width=2)

def draw_street_ghost(draw, cx, cy, s, color, fg):
    draw.arc([cx - 0.30*s, cy - 0.38*s, cx + 0.30*s, cy + 0.12*s], 180, 0, fill=fg, width=3)
    circle(draw, cx - 0.12*s, cy - 0.08*s, 0.07*s, fill=color)
    circle(draw, cx + 0.12*s, cy - 0.08*s, 0.07*s, fill=color)
    rect(draw, cx - 0.18*s, cy + 0.10*s, cx + 0.18*s, cy + 0.36*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    for y in (0.18*s, 0.28*s):
        draw.line([(cx - 0.14*s, cy + y), (cx + 0.14*s, cy + y)], fill=color, width=2)


# ============================================================================
# CORP ENFORCERS (10 units)
# ============================================================================

def draw_corp_apex(draw, cx, cy, s, color, fg):
    pts = [(cx, cy - 0.44*s), (cx + 0.38*s, cy + 0.36*s), (cx - 0.38*s, cy + 0.36*s)]
    draw.polygon(pts, fill=blend(BG, color, 0.25), outline=fg, width=2)
    cap = [(cx, cy - 0.44*s), (cx + 0.14*s, cy - 0.20*s), (cx - 0.14*s, cy - 0.20*s)]
    draw.polygon(cap, fill=color, outline=fg, width=1)
    circle(draw, cx, cy - 0.08*s, 0.05*s, fill=fg)

def draw_corp_auditor(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.26*s, cy - 0.36*s, cx + 0.26*s, cy + 0.40*s, fill=blend(BG, color, 0.2), outline=fg, width=2)
    rect(draw, cx - 0.12*s, cy - 0.44*s, cx + 0.12*s, cy - 0.32*s, fill=color)
    for y in (-0.16*s, 0, 0.16*s):
        draw.line([(cx - 0.16*s, cy + y), (cx + 0.16*s, cy + y)], fill=color, width=2)
    circle(draw, cx, cy, 0.26*s, outline=fg, width=1)

def draw_corp_breacher(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.30*s, cy - 0.22*s, cx + 0.30*s, cy + 0.08*s, fill=blend(BG, color, 0.4), outline=fg, width=2)
    draw.line([(cx, cy + 0.08*s), (cx, cy + 0.42*s)], fill=color, width=4)
    for x in (-0.20*s, 0, 0.20*s):
        draw.polygon([(cx + x - 0.05*s, cy - 0.22*s), (cx + x + 0.05*s, cy - 0.22*s), (cx + x, cy - 0.36*s)], fill=fg)

def draw_corp_commander(draw, cx, cy, s, color, fg):
    pts1 = [(cx - 0.34*s, cy - 0.10*s), (cx, cy - 0.38*s), (cx + 0.34*s, cy - 0.10*s)]
    pts2 = [(cx - 0.34*s, cy + 0.12*s), (cx, cy - 0.16*s), (cx + 0.34*s, cy + 0.12*s)]
    draw.line(pts1, fill=fg, width=3)
    draw.line(pts2, fill=color, width=3)
    star = star_points(cx, cy + 0.18*s, 0.16*s, 0.07*s, 5)
    draw.polygon(star, fill=color, outline=fg, width=1)

def draw_corp_deadeye(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.36*s, outline=fg, width=2)
    circle(draw, cx, cy, 0.18*s, outline=color, width=1)
    draw.line([(cx - 0.44*s, cy), (cx + 0.44*s, cy)], fill=fg, width=2)
    draw.line([(cx, cy - 0.44*s), (cx, cy + 0.44*s)], fill=fg, width=2)
    circle(draw, cx, cy, 0.04*s, fill=color)

def draw_corp_director(draw, cx, cy, s, color, fg):
    collar = [(cx - 0.32*s, cy - 0.36*s), (cx, cy - 0.10*s), (cx + 0.32*s, cy - 0.36*s)]
    draw.line(collar, fill=fg, width=3)
    tie = [(cx, cy - 0.10*s), (cx + 0.10*s, cy - 0.02*s), (cx + 0.14*s, cy + 0.32*s),
           (cx, cy + 0.44*s), (cx - 0.14*s, cy + 0.32*s), (cx - 0.10*s, cy - 0.02*s)]
    draw.polygon(tie, fill=color, outline=fg, width=2)

def draw_corp_operative(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.35*s, cy - 0.14*s, cx + 0.35*s, cy + 0.14*s, fill=blend(BG, color, 0.4), outline=fg, width=2)
    circle(draw, cx - 0.18*s, cy, 0.08*s, fill=color, outline=fg, width=1)
    circle(draw, cx, cy - 0.12*s, 0.08*s, fill=color, outline=fg, width=1)
    circle(draw, cx + 0.18*s, cy, 0.08*s, fill=color, outline=fg, width=1)

def draw_corp_patrol(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy - 0.12*s, 0.14*s, fill=blend(BG, color, 0.4), outline=fg, width=2)
    draw.line([(cx - 0.35*s, cy - 0.28*s), (cx + 0.35*s, cy + 0.04*s)], fill=color, width=2)
    draw.line([(cx + 0.35*s, cy - 0.28*s), (cx - 0.35*s, cy + 0.04*s)], fill=color, width=2)
    cone = [(cx, cy - 0.02*s), (cx + 0.36*s, cy + 0.42*s), (cx - 0.36*s, cy + 0.42*s)]
    draw.polygon(cone, fill=blend(BG, color, 0.15), outline=color, width=1)

def draw_corp_sentinel(draw, cx, cy, s, color, fg):
    draw.line([(cx - 0.08*s, cy - 0.42*s), (cx - 0.08*s, cy)], fill=fg, width=3)
    draw.line([(cx + 0.08*s, cy - 0.42*s), (cx + 0.08*s, cy)], fill=fg, width=3)
    rect(draw, cx - 0.22*s, cy - 0.10*s, cx + 0.22*s, cy + 0.16*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    draw.line([(cx, cy + 0.16*s), (cx - 0.30*s, cy + 0.44*s)], fill=color, width=3)
    draw.line([(cx, cy + 0.16*s), (cx + 0.30*s, cy + 0.44*s)], fill=color, width=3)

def draw_corp_tactician(draw, cx, cy, s, color, fg):
    rook = [
        (cx - 0.24*s, cy - 0.35*s), (cx - 0.14*s, cy - 0.35*s),
        (cx - 0.14*s, cy - 0.22*s), (cx - 0.05*s, cy - 0.22*s),
        (cx - 0.05*s, cy - 0.35*s), (cx + 0.05*s, cy - 0.35*s),
        (cx + 0.05*s, cy - 0.22*s), (cx + 0.14*s, cy - 0.22*s),
        (cx + 0.14*s, cy - 0.35*s), (cx + 0.24*s, cy - 0.35*s),
        (cx + 0.16*s, cy + 0.24*s), (cx + 0.26*s, cy + 0.38*s),
        (cx - 0.26*s, cy + 0.38*s), (cx - 0.16*s, cy + 0.24*s),
    ]
    draw.polygon(rook, fill=blend(BG, color, 0.3), outline=fg, width=2)
    circle(draw, cx, cy, 0.06*s, fill=color)


# ============================================================================
# FIXERS (10 units)
# ============================================================================

def draw_fixer_bouncer(draw, cx, cy, s, color, fg):
    draw.line([(cx - 0.38*s, cy + 0.22*s), (cx + 0.38*s, cy + 0.22*s)], fill=fg, width=4)
    for x in (-0.24*s, -0.08*s, 0.08*s, 0.24*s):
        circle(draw, cx + x, cy - 0.04*s, 0.10*s, fill=blend(BG, color, 0.2), outline=fg, width=2)
        circle(draw, cx + x, cy - 0.04*s, 0.04*s, fill=color)

def draw_fixer_broker(draw, cx, cy, s, color, fg):
    draw.line([(cx - 0.36*s, cy - 0.15*s), (cx + 0.36*s, cy - 0.15*s)], fill=fg, width=3)
    draw.line([(cx, cy - 0.35*s), (cx, cy + 0.38*s)], fill=color, width=3)
    draw.line([(cx - 0.32*s, cy - 0.15*s), (cx - 0.32*s, cy + 0.12*s)], fill=fg, width=1)
    draw.line([(cx + 0.32*s, cy - 0.15*s), (cx + 0.32*s, cy + 0.12*s)], fill=fg, width=1)
    draw.arc([cx - 0.44*s, cy + 0.02*s, cx - 0.20*s, cy + 0.22*s], 0, 180, fill=fg, width=2)
    draw.arc([cx + 0.20*s, cy + 0.02*s, cx + 0.44*s, cy + 0.22*s], 0, 180, fill=fg, width=2)

def draw_fixer_bruiser(draw, cx, cy, s, color, fg):
    pts = [(cx - 0.12*s, cy - 0.42*s), (cx + 0.12*s, cy - 0.42*s),
           (cx + 0.06*s, cy + 0.38*s), (cx - 0.06*s, cy + 0.38*s)]
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    for y in (-0.30*s, -0.15*s, 0):
        draw.line([(cx - 0.24*s, cy + y), (cx - 0.10*s, cy + y)], fill=color, width=3)
        draw.line([(cx + 0.10*s, cy + y), (cx + 0.24*s, cy + y)], fill=color, width=3)

def draw_fixer_chemist(draw, cx, cy, s, color, fg):
    flask = [
        (cx - 0.08*s, cy - 0.38*s), (cx + 0.08*s, cy - 0.38*s),
        (cx + 0.08*s, cy - 0.10*s), (cx + 0.34*s, cy + 0.38*s),
        (cx - 0.34*s, cy + 0.38*s), (cx - 0.08*s, cy - 0.10*s),
    ]
    draw.polygon(flask, fill=blend(BG, color, 0.25), outline=fg, width=2)
    draw.line([(cx - 0.24*s, cy + 0.18*s), (cx + 0.24*s, cy + 0.18*s)], fill=color, width=2)
    circle(draw, cx - 0.08*s, cy + 0.28*s, 0.04*s, fill=color)
    circle(draw, cx + 0.06*s, cy + 0.22*s, 0.05*s, fill=color)

def draw_fixer_dealer(draw, cx, cy, s, color, fg):
    for rot, dx, col in ((-20, -0.16*s, color), (0, 0, fg), (20, 0.16*s, color)):
        c_pts = regular_polygon(cx + dx, cy, 0.30*s, 4, rotation=45 + rot)
        draw.polygon(c_pts, fill=blend(BG, color, 0.25), outline=col, width=2)
    draw.polygon([(cx, cy - 0.08*s), (cx + 0.06*s, cy), (cx, cy + 0.08*s), (cx - 0.06*s, cy)], fill=fg)

def draw_fixer_doc(draw, cx, cy, s, color, fg):
    w, h = 0.36*s, 0.12*s
    rect(draw, cx - w, cy - h, cx + w, cy + h, fill=color, outline=fg, width=2)
    rect(draw, cx - h, cy - w, cx + h, cy + w, fill=color, outline=fg, width=2)
    circle(draw, cx, cy, 0.08*s, fill=fg)

def draw_fixer_hitman(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.40*s, cy - 0.20*s, cx + 0.15*s, cy - 0.05*s, fill=blend(BG, color, 0.4), outline=fg, width=2)
    rect(draw, cx - 0.46*s, cy - 0.22*s, cx - 0.40*s, cy - 0.03*s, fill=color)
    grip = [(cx + 0.02*s, cy - 0.05*s), (cx + 0.22*s, cy + 0.38*s),
            (cx + 0.08*s, cy + 0.40*s), (cx - 0.10*s, cy - 0.05*s)]
    draw.polygon(grip, fill=blend(BG, color, 0.25), outline=fg, width=2)

def draw_fixer_kingpin(draw, cx, cy, s, color, fg):
    pts = [
        (cx - 0.36*s, cy + 0.28*s), (cx - 0.36*s, cy - 0.15*s),
        (cx - 0.18*s, cy + 0.02*s), (cx, cy - 0.36*s),
        (cx + 0.18*s, cy + 0.02*s), (cx + 0.36*s, cy - 0.15*s),
        (cx + 0.36*s, cy + 0.28*s),
    ]
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    for x in (-0.24*s, 0, 0.24*s):
        circle(draw, cx + x, cy + 0.16*s, 0.05*s, fill=color)

def draw_fixer_scav(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.28*s, outline=color, width=2)
    draw.arc([cx - 0.25*s, cy - 0.38*s, cx + 0.25*s, cy + 0.20*s], 30, 240, fill=fg, width=3)
    draw.line([(cx, cy - 0.10*s), (cx, cy + 0.42*s)], fill=fg, width=4)

def draw_fixer_wiretap(draw, cx, cy, s, color, fg):
    draw.arc([cx - 0.34*s, cy - 0.30*s, cx + 0.34*s, cy + 0.30*s], 90, 270, fill=fg, width=3)
    draw.line([(cx - 0.34*s, cy), (cx + 0.10*s, cy)], fill=color, width=3)
    circle(draw, cx + 0.10*s, cy, 0.06*s, fill=fg)
    for r in (0.22*s, 0.34*s):
        draw.arc([cx + 0.10*s - r, cy - r, cx + 0.10*s + r, cy + r], -45, 45, fill=color, width=2)


# ============================================================================
# BOSSES (23 units)
# ============================================================================

def draw_boss_ai_prime_overmind(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.36*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    draw.line([(cx, cy - 0.36*s), (cx, cy + 0.36*s)], fill=color, width=2)
    circle(draw, cx, cy, 0.14*s, fill=color, outline=fg, width=2)
    circle(draw, cx - 0.18*s, cy - 0.10*s, 0.06*s, fill=fg)
    circle(draw, cx + 0.18*s, cy - 0.10*s, 0.06*s, fill=fg)

def draw_boss_algo_arbitrageur(draw, cx, cy, s, color, fg):
    for x, top, bot in ((-0.25*s, -0.05*s, 0.35*s), (0, -0.38*s, 0.25*s), (0.25*s, -0.20*s, 0.15*s)):
        draw.line([(cx + x, cy + top - 0.08*s), (cx + x, cy + bot + 0.08*s)], fill=fg, width=2)
        rect(draw, cx + x - 0.07*s, cy + top, cx + x + 0.07*s, cy + bot, fill=color, outline=fg, width=1)
    draw.line([(cx - 0.38*s, cy + 0.30*s), (cx + 0.38*s, cy - 0.38*s)], fill=fg, width=3)

def draw_boss_broker_prime(draw, cx, cy, s, color, fg):
    draw.line([(cx - 0.38*s, cy - 0.10*s), (cx + 0.38*s, cy - 0.10*s)], fill=fg, width=3)
    draw.line([(cx, cy - 0.35*s), (cx, cy + 0.40*s)], fill=color, width=4)
    crown = [(cx, cy - 0.44*s), (cx + 0.14*s, cy - 0.30*s), (cx, cy - 0.16*s), (cx - 0.14*s, cy - 0.30*s)]
    draw.polygon(crown, fill=color, outline=fg, width=1)
    circle(draw, cx - 0.30*s, cy + 0.16*s, 0.12*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    circle(draw, cx + 0.30*s, cy + 0.16*s, 0.12*s, fill=blend(BG, color, 0.3), outline=fg, width=2)

def draw_boss_chop_doc(draw, cx, cy, s, color, fg):
    pts = star_points(cx, cy, 0.42*s, 0.30*s, 12)
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    circle(draw, cx, cy, 0.16*s, fill=color, outline=fg, width=2)
    circle(draw, cx, cy, 0.06*s, fill=BG)

def draw_boss_corp_commander(draw, cx, cy, s, color, fg):
    pts = [
        (cx, cy - 0.44*s), (cx + 0.42*s, cy - 0.20*s), (cx + 0.24*s, cy + 0.18*s),
        (cx, cy + 0.44*s), (cx - 0.24*s, cy + 0.18*s), (cx - 0.42*s, cy - 0.20*s),
    ]
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    for x in (-0.18*s, -0.06*s, 0.06*s, 0.18*s):
        circle(draw, cx + x, cy - 0.02*s, 0.04*s, fill=color)

def draw_boss_director_panopticon(draw, cx, cy, s, color, fg):
    for r in (0.42*s, 0.28*s, 0.14*s):
        circle(draw, cx, cy, r, outline=fg if r == 0.42*s else color, width=2)
    for ang in range(0, 360, 45):
        rad = math.radians(ang)
        draw.line([(cx + 0.14*s*math.cos(rad), cy + 0.14*s*math.sin(rad)),
                   (cx + 0.42*s*math.cos(rad), cy + 0.42*s*math.sin(rad))], fill=color, width=1)
    circle(draw, cx, cy, 0.06*s, fill=fg)

def draw_boss_dock_foreman(draw, cx, cy, s, color, fg):
    draw.arc([cx - 0.34*s, cy - 0.20*s, cx + 0.34*s, cy + 0.38*s], 0, 180, fill=fg, width=4)
    draw.line([(cx, cy - 0.42*s), (cx, cy + 0.15*s)], fill=fg, width=4)
    circle(draw, cx, cy - 0.35*s, 0.08*s, outline=color, width=2)
    draw.polygon([(cx - 0.34*s, cy - 0.02*s), (cx - 0.42*s, cy - 0.18*s), (cx - 0.26*s, cy - 0.12*s)], fill=color)
    draw.polygon([(cx + 0.34*s, cy - 0.02*s), (cx + 0.42*s, cy - 0.18*s), (cx + 0.26*s, cy - 0.12*s)], fill=color)

def draw_boss_foundry_overseer(draw, cx, cy, s, color, fg):
    crucible = [(cx - 0.30*s, cy - 0.38*s), (cx + 0.30*s, cy - 0.38*s), (cx + 0.20*s, cy - 0.05*s), (cx - 0.20*s, cy - 0.05*s)]
    draw.polygon(crucible, fill=blend(BG, color, 0.4), outline=fg, width=2)
    draw.polygon([(cx - 0.06*s, cy - 0.05*s), (cx + 0.06*s, cy - 0.05*s), (cx + 0.10*s, cy + 0.40*s), (cx - 0.10*s, cy + 0.40*s)], fill=color)
    rect(draw, cx - 0.36*s, cy + 0.26*s, cx + 0.36*s, cy + 0.42*s, fill=blend(BG, color, 0.25), outline=fg, width=2)

def draw_boss_gala_security_chief(draw, cx, cy, s, color, fg):
    draw.line([(cx - 0.38*s, cy - 0.38*s), (cx + 0.38*s, cy + 0.38*s)], fill=color, width=3)
    draw.line([(cx + 0.38*s, cy - 0.38*s), (cx - 0.38*s, cy + 0.38*s)], fill=color, width=3)
    pts = [(cx, cy - 0.40*s), (cx + 0.28*s, cy - 0.20*s), (cx + 0.20*s, cy + 0.22*s),
           (cx, cy + 0.42*s), (cx - 0.20*s, cy + 0.22*s), (cx - 0.28*s, cy - 0.20*s)]
    draw.polygon(pts, fill=blend(BG, color, 0.35), outline=fg, width=2)

def draw_boss_ghost_daemon(draw, cx, cy, s, color, fg):
    draw.polygon([(cx - 0.22*s, cy - 0.15*s), (cx - 0.44*s, cy - 0.44*s), (cx - 0.10*s, cy - 0.30*s)], fill=color, outline=fg, width=1)
    draw.polygon([(cx + 0.22*s, cy - 0.15*s), (cx + 0.44*s, cy - 0.44*s), (cx + 0.10*s, cy - 0.30*s)], fill=color, outline=fg, width=1)
    pts = [(cx - 0.26*s, cy - 0.24*s), (cx + 0.26*s, cy - 0.24*s), (cx + 0.32*s, cy + 0.08*s),
           (cx + 0.18*s, cy + 0.38*s), (cx - 0.18*s, cy + 0.38*s), (cx - 0.32*s, cy + 0.08*s)]
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    draw.line([(cx - 0.18*s, cy), (cx - 0.06*s, cy + 0.04*s)], fill=color, width=4)
    draw.line([(cx + 0.18*s, cy), (cx + 0.06*s, cy + 0.04*s)], fill=color, width=4)

def draw_boss_highway_reaper(draw, cx, cy, s, color, fg):
    draw.line([(cx - 0.36*s, cy + 0.36*s), (cx - 0.36*s, cy - 0.35*s)], fill=fg, width=3)
    draw.line([(cx + 0.36*s, cy + 0.36*s), (cx + 0.36*s, cy - 0.35*s)], fill=fg, width=3)
    pts = [(cx - 0.28*s, cy - 0.20*s), (cx + 0.28*s, cy - 0.20*s), (cx, cy + 0.38*s)]
    draw.polygon(pts, fill=blend(BG, color, 0.4), outline=fg, width=2)
    for y in (-0.08*s, 0.06*s, 0.20*s):
        draw.line([(cx - 0.16*s, cy + y), (cx + 0.16*s, cy + y)], fill=color, width=2)

def draw_boss_house_dealer(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy, 0.36*s, outline=fg, width=2)
    for ang in range(0, 360, 30):
        rad = math.radians(ang)
        draw.line([(cx + 0.24*s*math.cos(rad), cy + 0.24*s*math.sin(rad)),
                   (cx + 0.36*s*math.cos(rad), cy + 0.36*s*math.sin(rad))], fill=color, width=1)
    spade = [(cx, cy - 0.22*s), (cx + 0.18*s, cy - 0.05*s), (cx + 0.06*s, cy + 0.12*s),
             (cx, cy + 0.06*s), (cx - 0.06*s, cy + 0.12*s), (cx - 0.18*s, cy - 0.05*s)]
    draw.polygon(spade, fill=color, outline=fg, width=1)
    draw.line([(cx, cy + 0.06*s), (cx, cy + 0.22*s)], fill=fg, width=3)

def draw_boss_machine_prophet(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy - 0.16*s, 0.26*s, outline=color, width=3)
    pts = [(cx, cy - 0.44*s), (cx + 0.18*s, cy + 0.40*s), (cx - 0.18*s, cy + 0.40*s)]
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=fg, width=2)
    circle(draw, cx, cy - 0.16*s, 0.08*s, fill=fg)

def draw_boss_mindbreaker(draw, cx, cy, s, color, fg):
    for r in (0.24*s, 0.36*s, 0.44*s):
        draw.arc([cx - r, cy - 0.10*s - r, cx + r, cy - 0.10*s + r], 200, 340, fill=color, width=2)
    pts1 = [(cx - 0.04*s, cy - 0.25*s), (cx - 0.28*s, cy - 0.10*s), (cx - 0.18*s, cy + 0.34*s), (cx - 0.04*s, cy + 0.34*s)]
    pts2 = [(cx + 0.04*s, cy - 0.25*s), (cx + 0.28*s, cy - 0.10*s), (cx + 0.18*s, cy + 0.34*s), (cx + 0.04*s, cy + 0.34*s)]
    draw.polygon(pts1, fill=blend(BG, color, 0.25), outline=fg, width=2)
    draw.polygon(pts2, fill=blend(BG, color, 0.25), outline=fg, width=2)

def draw_boss_nemesis_synthetic(draw, cx, cy, s, color, fg):
    pts = [(cx - 0.30*s, cy - 0.35*s), (cx + 0.30*s, cy - 0.35*s), (cx + 0.35*s, cy + 0.05*s),
           (cx + 0.20*s, cy + 0.38*s), (cx - 0.20*s, cy + 0.38*s), (cx - 0.35*s, cy + 0.05*s)]
    draw.polygon(pts, fill=blend(BG, color, 0.35), outline=fg, width=2)
    rect(draw, cx - 0.26*s, cy - 0.12*s, cx + 0.26*s, cy + 0.02*s, fill=BG, outline=fg, width=1)
    circle(draw, cx, cy - 0.05*s, 0.06*s, fill=color)

def draw_boss_railmaster(draw, cx, cy, s, color, fg):
    draw.line([(cx - 0.38*s, cy + 0.38*s), (cx - 0.15*s, cy - 0.38*s)], fill=color, width=2)
    draw.line([(cx + 0.38*s, cy + 0.38*s), (cx + 0.15*s, cy - 0.38*s)], fill=color, width=2)
    plow = [(cx, cy - 0.25*s), (cx + 0.32*s, cy + 0.25*s), (cx - 0.32*s, cy + 0.25*s)]
    draw.polygon(plow, fill=blend(BG, color, 0.35), outline=fg, width=2)
    draw.line([(cx, cy - 0.25*s), (cx, cy + 0.25*s)], fill=color, width=3)

def draw_boss_salvage_baron(draw, cx, cy, s, color, fg):
    circle(draw, cx, cy - 0.20*s, 0.18*s, fill=blend(BG, color, 0.35), outline=fg, width=2)
    for ang in (45, 135, 225, 315):
        rad = math.radians(ang)
        x1, y1 = cx + 0.16*s*math.cos(rad), cy + 0.16*s*math.sin(rad)
        x2, y2 = cx + 0.38*s*math.cos(rad), cy + 0.38*s*math.sin(rad)
        draw.line([(x1, y1), (x2, y2)], fill=color, width=4)
        circle(draw, x2, y2, 0.05*s, fill=fg)

def draw_boss_scrap_titan(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.20*s, cy + 0.15*s, cx + 0.20*s, cy + 0.42*s, fill=blend(BG, color, 0.4), outline=fg, width=2)
    rect(draw, cx - 0.34*s, cy - 0.25*s, cx + 0.34*s, cy + 0.15*s, fill=blend(BG, color, 0.25), outline=fg, width=2)
    for x in (-0.24*s, -0.08*s, 0.08*s, 0.24*s):
        rect(draw, cx + x - 0.06*s, cy - 0.40*s, cx + x + 0.06*s, cy - 0.25*s, fill=color, outline=fg, width=1)

def draw_boss_slum_enforcer(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.30*s, cy - 0.38*s, cx + 0.30*s, cy + 0.38*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    draw.line([(cx - 0.30*s, cy - 0.30*s), (cx + 0.30*s, cy + 0.30*s)], fill=color, width=2)
    draw.line([(cx - 0.30*s, cy + 0.30*s), (cx + 0.30*s, cy - 0.30*s)], fill=color, width=2)
    circle(draw, cx, cy, 0.08*s, fill=fg)

def draw_boss_static_warlord(draw, cx, cy, s, color, fg):
    pts = [(cx, cy - 0.44*s), (cx + 0.24*s, cy + 0.40*s), (cx - 0.24*s, cy + 0.40*s)]
    draw.polygon(pts, fill=blend(BG, color, 0.25), outline=fg, width=2)
    for y in (-0.15*s, 0.05*s, 0.25*s):
        draw.line([(cx - 0.12*s, cy + y), (cx + 0.12*s, cy + y)], fill=color, width=2)
    draw.line([(cx - 0.42*s, cy - 0.30*s), (cx - 0.15*s, cy - 0.40*s)], fill=fg, width=2)
    draw.line([(cx + 0.42*s, cy - 0.30*s), (cx + 0.15*s, cy - 0.40*s)], fill=fg, width=2)

def draw_boss_transit_warden(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.16*s, cy - 0.42*s, cx + 0.16*s, cy + 0.42*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    for y, col in ((-0.25*s, (255, 60, 60)), (0, (255, 200, 40)), (0.25*s, (60, 255, 100))):
        circle(draw, cx, cy + y, 0.08*s, fill=col, outline=fg, width=1)

def draw_boss_warrant_bot(draw, cx, cy, s, color, fg):
    circle(draw, cx - 0.18*s, cy, 0.16*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    circle(draw, cx + 0.18*s, cy, 0.16*s, fill=blend(BG, color, 0.3), outline=fg, width=2)
    circle(draw, cx - 0.18*s, cy, 0.07*s, fill=BG)
    circle(draw, cx + 0.18*s, cy, 0.07*s, fill=BG)
    rect(draw, cx - 0.10*s, cy - 0.04*s, cx + 0.10*s, cy + 0.04*s, fill=color)

def draw_boss_warren_overlord(draw, cx, cy, s, color, fg):
    rect(draw, cx - 0.38*s, cy - 0.38*s, cx + 0.38*s, cy + 0.38*s, outline=fg, width=2)
    draw.line([(cx - 0.38*s, cy - 0.15*s), (cx + 0.10*s, cy - 0.15*s), (cx + 0.10*s, cy + 0.18*s), (cx + 0.38*s, cy + 0.18*s)], fill=color, width=3)
    draw.line([(cx - 0.15*s, cy - 0.38*s), (cx - 0.15*s, cy + 0.38*s)], fill=color, width=3)
    circle(draw, cx + 0.22*s, cy - 0.15*s, 0.07*s, fill=fg)


# ============================================================================
# DISPATCH TABLE
# ============================================================================

UNIT_GLYPHS = {
    # Rogue AIs
    "ai_bastion": draw_ai_bastion,
    "ai_byte": draw_ai_byte,
    "ai_cipher": draw_ai_cipher,
    "ai_dreadnought": draw_ai_dreadnought,
    "ai_glitch": draw_ai_glitch,
    "ai_null_construct": draw_ai_null_construct,
    "ai_singularity": draw_ai_singularity,
    "ai_siphon": draw_ai_siphon,
    "ai_spindle": draw_ai_spindle,
    "ai_vector": draw_ai_vector,
    "ai_worm": draw_ai_worm,

    # Bio-Hackers
    "bio_abomination": draw_bio_abomination,
    "bio_chimera": draw_bio_chimera,
    "bio_fleshweaver": draw_bio_fleshweaver,
    "bio_gorgon": draw_bio_gorgon,
    "bio_hydra": draw_bio_hydra,
    "bio_leech": draw_bio_leech,
    "bio_manticore": draw_bio_manticore,
    "bio_plague_doctor": draw_bio_plague_doctor,
    "bio_symbiote": draw_bio_symbiote,
    "bio_viper": draw_bio_viper,

    # Net-Phantoms
    "phantom_aegis": draw_phantom_aegis,
    "phantom_assassin": draw_phantom_assassin,
    "phantom_bulwark": draw_phantom_bulwark,
    "phantom_eidolon": draw_phantom_eidolon,
    "phantom_mirage": draw_phantom_mirage,
    "phantom_nightshade": draw_phantom_nightshade,
    "phantom_nullifier": draw_phantom_nullifier,
    "phantom_spectre": draw_phantom_spectre,
    "phantom_whisper": draw_phantom_whisper,
    "phantom_wraith": draw_phantom_wraith,

    # Street Runners
    "runner_blitz": draw_runner_blitz,
    "runner_dash": draw_runner_dash,
    "runner_nexus": draw_runner_nexus,
    "runner_overdrive": draw_runner_overdrive,
    "runner_phantom": draw_runner_phantom,
    "runner_rampart": draw_runner_rampart,
    "runner_slasher": draw_runner_slasher,
    "runner_spark": draw_runner_spark,
    "runner_volt": draw_runner_volt,
    "street_ghost": draw_street_ghost,

    # Corp Enforcers
    "corp_apex": draw_corp_apex,
    "corp_auditor": draw_corp_auditor,
    "corp_breacher": draw_corp_breacher,
    "corp_commander": draw_corp_commander,
    "corp_deadeye": draw_corp_deadeye,
    "corp_director": draw_corp_director,
    "corp_operative": draw_corp_operative,
    "corp_patrol": draw_corp_patrol,
    "corp_sentinel": draw_corp_sentinel,
    "corp_tactician": draw_corp_tactician,

    # Fixers
    "fixer_bouncer": draw_fixer_bouncer,
    "fixer_broker": draw_fixer_broker,
    "fixer_bruiser": draw_fixer_bruiser,
    "fixer_chemist": draw_fixer_chemist,
    "fixer_dealer": draw_fixer_dealer,
    "fixer_doc": draw_fixer_doc,
    "fixer_hitman": draw_fixer_hitman,
    "fixer_kingpin": draw_fixer_kingpin,
    "fixer_scav": draw_fixer_scav,
    "fixer_wiretap": draw_fixer_wiretap,

    # Bosses
    "boss_ai_prime_overmind": draw_boss_ai_prime_overmind,
    "boss_algo_arbitrageur": draw_boss_algo_arbitrageur,
    "boss_broker_prime": draw_boss_broker_prime,
    "boss_chop_doc": draw_boss_chop_doc,
    "boss_corp_commander": draw_boss_corp_commander,
    "boss_director_panopticon": draw_boss_director_panopticon,
    "boss_dock_foreman": draw_boss_dock_foreman,
    "boss_foundry_overseer": draw_boss_foundry_overseer,
    "boss_gala_security_chief": draw_boss_gala_security_chief,
    "boss_ghost_daemon": draw_boss_ghost_daemon,
    "boss_highway_reaper": draw_boss_highway_reaper,
    "boss_house_dealer": draw_boss_house_dealer,
    "boss_machine_prophet": draw_boss_machine_prophet,
    "boss_mindbreaker": draw_boss_mindbreaker,
    "boss_nemesis_synthetic": draw_boss_nemesis_synthetic,
    "boss_railmaster": draw_boss_railmaster,
    "boss_salvage_baron": draw_boss_salvage_baron,
    "boss_scrap_titan": draw_boss_scrap_titan,
    "boss_slum_enforcer": draw_boss_slum_enforcer,
    "boss_static_warlord": draw_boss_static_warlord,
    "boss_transit_warden": draw_boss_transit_warden,
    "boss_warrant_bot": draw_boss_warrant_bot,
    "boss_warren_overlord": draw_boss_warren_overlord,
}

def draw_default_glyph(draw, cx, cy, s, color, fg, unit_id):
    h = sum(ord(c) * (i + 1) for i, c in enumerate(unit_id))
    sides = 3 + (h % 5)
    circle(draw, cx, cy, 0.36*s, outline=fg, width=2)
    pts = regular_polygon(cx, cy, 0.28*s, sides, rotation=(h * 23) % 360)
    draw.polygon(pts, fill=blend(BG, color, 0.3), outline=color, width=2)
    circle(draw, cx, cy, 0.08*s, fill=fg)


# ============================================================================
# CARD RENDERER
# ============================================================================

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

def make_portrait(unit, size=128):
    scale = 2
    hi = size * scale
    img = Image.new("RGBA", (hi, hi), BG)
    draw = ImageDraw.Draw(img)

    faction = unit.get("faction", 1)
    is_boss = unit["id"].startswith("boss_")
    color = (255, 180, 40) if is_boss else FACTION_COLORS.get(faction, (0, 245, 212))
    role = unit.get("role", 0)
    fg = (245, 250, 255, 255)

    # Frame polygon
    cx, cy = hi / 2, (hi / 2 - 4 * scale)
    r = hi * 0.36
    sides = 6 if is_boss else ROLE_SHAPE_SIDES.get(role, 6)
    rotation = -45 if sides == 4 else -90

    bg_poly = blend(BG, color, 0.12)
    border_poly = blend(BG, color, 0.75)
    inner_poly = blend(BG, color, 0.35)
    draw.polygon(regular_polygon(cx, cy, r, sides, rotation), fill=bg_poly, outline=border_poly, width=2*scale)
    draw.polygon(regular_polygon(cx, cy, r - 5*scale, sides, rotation), outline=inner_poly, width=scale)

    draw_corner_brackets(draw, hi, (*color, 255), margin=8*scale, length=14*scale, width=2*scale)

    # Unit glyph
    s = 56 * scale
    glyph_fn = UNIT_GLYPHS.get(unit["id"])
    if glyph_fn:
        glyph_fn(draw, cx, cy, s, color, fg)
    else:
        draw_default_glyph(draw, cx, cy, s, color, fg, unit["id"])

    # Labels
    font_small = ImageFont.truetype(FONT_BOLD, 11 * scale)
    if is_boss:
        label = "BOSS · THREAT"
    else:
        label = f'{ROLE_ABBR.get(role, "?")} · {FACTION_ABBR.get(faction, "?")}'
    draw_centered_text(draw, hi / 2, hi - 12 * scale, label, font_small, (*color, 255))

    font_id = ImageFont.truetype(FONT_REG, 9 * scale)
    draw_centered_text(draw, hi / 2, 11 * scale, unit["id"], font_id, (150, 160, 175, 220), max_w=hi - 48 * scale)

    return img.resize((size, size), Image.Resampling.LANCZOS)

def main():
    os.makedirs(PORTRAIT_OUT, exist_ok=True)
    units = load_units()
    print(f"Generating unique portraits for {len(units)} units...")
    for u in units:
        out_path = os.path.join(PORTRAIT_OUT, f"{u['id']}.png")
        img = make_portrait(u)
        img.save(out_path)
    print("All unit portraits generated successfully!")

if __name__ == "__main__":
    main()
