#!/usr/bin/env python3
"""Generate the DMG installer window background for flourish.

Output: assets/dmg-background.png  (1320 × 800 px — used as both 1× and 2× by build-dmg.sh)

Design language:
  Background  #C8DFC0   sage green  (matches SignInView header)
  Arrow       #3D6135   forest dark green (matches logo mark)
  Text        #6E826A   muted sage-grey
"""

from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1320, 800
BG   = (200, 223, 192, 255)   # #C8DFC0
FG   = (61,  97,  53,  255)   # #3D6135
TEXT = (110, 130, 105, 255)

img  = Image.new("RGBA", (W, H), BG)
draw = ImageDraw.Draw(img, "RGBA")


def cbez(p0, p1, p2, p3, n=2000):
    pts = []
    for i in range(n + 1):
        t = i / n; u = 1 - t
        x = u**3*p0[0] + 3*u**2*t*p1[0] + 3*u*t**2*p2[0] + t**3*p3[0]
        y = u**3*p0[1] + 3*u**2*t*p1[1] + 3*u*t**2*p2[1] + t**3*p3[1]
        pts.append((x, y))
    return pts


def paint_stroke(pts, r, color=FG):
    """Splat overlapping circles along a bezier path — smooth, no PIL banding."""
    px_prev = None
    step = max(1, r // 4)
    for x, y in pts:
        ix, iy = int(x), int(y)
        if px_prev is None or abs(ix - px_prev[0]) + abs(iy - px_prev[1]) >= step:
            draw.ellipse([ix-r, iy-r, ix+r, iy+r], fill=color)
            px_prev = (ix, iy)


R = 7   # stroke radius

# ── Shaft: wobbly S-curve ──────────────────────────────────────────────────────
shaft = cbez((450, 356), (560, 370), (730, 336), (838, 352))
paint_stroke(shaft, R)

# ── Chevron: two separate arms meeting at the tip (">" shape) ─────────────────
tip = (880, 352)

top = cbez((838, 324), (848, 318), (868, 334), tip)
paint_stroke(top, R)

bot = cbez(tip, (868, 370), (848, 386), (838, 380))
paint_stroke(bot, R)

# ── "Drag to install" caption ─────────────────────────────────────────────────
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 26)
except Exception:
    font = ImageFont.load_default()

label = "Drag to install"
bb = draw.textbbox((0, 0), label, font=font)
lx = (W - (bb[2] - bb[0])) // 2
draw.text((lx, 352 + 42), label, fill=TEXT, font=font)

# ── save ──────────────────────────────────────────────────────────────────────
out_dir = os.path.join(os.path.dirname(__file__), "..", "assets")
os.makedirs(out_dir, exist_ok=True)

out = os.path.join(out_dir, "dmg-background.png")
img.save(out, "PNG")
print(f"Written: {out}")
