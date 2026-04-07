#!/usr/bin/env python3
"""Generate the DMG installer window background for flourish.

Output: assets/dmg-background.png  (660 × 400 px)
        assets/dmg-background@2x.png (1320 × 800 px)

Design language:
  Background  #F8F7F4   warm off-white (flourish canvas)
  Accent      #5B7B4E   forest green   (flourish primary)
  Text        #3A3A35   near-black
  Subtext     #888880   muted warm grey
"""

from PIL import Image, ImageDraw, ImageFont
import os, math

W, H = 1320, 800  # retina; halved for 1x
BG      = (248, 247, 244)
GREEN   = (91, 123, 78)
GREEN_L = (180, 205, 170)   # lighter green for arrow shaft
TEXT    = (58, 58, 53)
SUB     = (136, 136, 128)

img  = Image.new("RGBA", (W, H), BG)
draw = ImageDraw.Draw(img)

# ── subtle top bar (forest green, full width, 6 px) ─────────────────────────
draw.rectangle([0, 0, W, 6], fill=GREEN)

# ── icon positions (retina coordinates) ─────────────────────────────────────
# App icon centred at x=330, Applications folder at x=990 — icons are 128 pt
APP_CX,   APP_CY   = 330, 320
APPS_CX,  APPS_CY  = 990, 320
ICON_R = 80  # icon placeholder radius (actual icons are drawn by Finder)

# ── arrow  ──────────────────────────────────────────────────────────────────
# A simple filled arrow pointing right, from 430 to 890, centred at y=APP_CY
AX0, AX1, AY = 460, 860, APP_CY
SHAFT_H  = 28
HEAD_H   = 68
HEAD_W   = 90

shaft_top    = AY - SHAFT_H // 2
shaft_bottom = AY + SHAFT_H // 2
head_left    = AX1 - HEAD_W

# shaft
draw.rectangle([AX0, shaft_top, head_left, shaft_bottom], fill=GREEN_L)
# arrowhead
arrow_head = [
    (head_left, AY - HEAD_H // 2),
    (AX1,       AY),
    (head_left, AY + HEAD_H // 2),
]
draw.polygon(arrow_head, fill=GREEN)

# ── "Drag to install" caption below the arrow ────────────────────────────────
# (Do NOT draw "flourish.app" or "Applications" — Finder renders those itself)
try:
    font_sm = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 36)
except Exception:
    font_sm = ImageFont.load_default()

draw.text(
    ((AX0 + AX1) // 2, AY + 80),
    "Drag to install",
    font=font_sm, fill=SUB, anchor="mm",
)

# ── subtle bottom rule ────────────────────────────────────────────────────────
draw.rectangle([0, H - 4, W, H], fill=GREEN_L)

# ── save ────────────────────────────────────────────────────────────────────
out_dir = os.path.join(os.path.dirname(__file__), "..", "assets")
os.makedirs(out_dir, exist_ok=True)

out2x = os.path.join(out_dir, "dmg-background@2x.png")
img.save(out2x, "PNG")

out1x = os.path.join(out_dir, "dmg-background.png")
img.resize((W // 2, H // 2), Image.LANCZOS).save(out1x, "PNG")

print(f"Written: {out1x}")
print(f"Written: {out2x}")
