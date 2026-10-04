"""Flat 512x512 icons for passes/products, drawn with PIL shapes (no emoji fonts, no external art)."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os, math
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out"); os.makedirs(OUT, exist_ok=True)
FONT = "C:/Windows/Fonts/arialbd.ttf"

def base(c1, c2):
    im = Image.new("RGB", (512, 512), c1)
    d = ImageDraw.Draw(im)
    for r in range(360, 0, -6):  # radial glow
        t = r / 360
        col = tuple(int(c2[i] * (1 - t) + c1[i] * t) for i in range(3))
        d.ellipse((256 - r, 256 - r, 256 + r, 256 + r), fill=col)
    return im, d

def text(d, s, y, size, fill=(255, 255, 255)):
    f = ImageFont.truetype(FONT, size)
    w = d.textlength(s, font=f)
    d.text(((512 - w) / 2, y), s, font=f, fill=fill, stroke_width=max(4, size // 14), stroke_fill=(20, 15, 40))

def bolt(d, cx, cy, s, fill):
    pts = [(0.15, -1), (-0.55, 0.1), (-0.05, 0.1), (-0.25, 1), (0.55, -0.15), (0.05, -0.15), (0.3, -1)]
    d.polygon([(cx + x * s, cy + y * s) for x, y in pts], fill=fill, outline=(30, 20, 50), width=8)

def star(d, cx, cy, r, fill):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    d.polygon(pts, fill=fill, outline=(30, 20, 50), width=8)

def trophy(d, cx, cy, s, fill):
    d.rounded_rectangle((cx - 0.55 * s, cy - 0.8 * s, cx + 0.55 * s, cy + 0.05 * s), radius=int(0.35 * s), fill=fill, outline=(30, 20, 50), width=8)
    for side in (-1, 1):
        d.arc((cx + side * 0.55 * s - 0.3 * s, cy - 0.65 * s, cx + side * 0.55 * s + 0.3 * s, cy - 0.1 * s), 0, 360, fill=fill, width=int(0.12 * s))
    d.rectangle((cx - 0.12 * s, cy + 0.05 * s, cx + 0.12 * s, cy + 0.45 * s), fill=fill, outline=(30, 20, 50), width=6)
    d.rounded_rectangle((cx - 0.45 * s, cy + 0.45 * s, cx + 0.45 * s, cy + 0.7 * s), radius=10, fill=fill, outline=(30, 20, 50), width=8)

def arrows(d, cx, cy, s, fill):
    for off in (-0.45, 0.25):
        x = cx + off * s
        d.polygon([(x - 0.3 * s, cy - 0.5 * s), (x + 0.4 * s, cy), (x - 0.3 * s, cy + 0.5 * s)], fill=fill, outline=(30, 20, 50), width=8)

def flask(d, cx, cy, s, fill):
    d.rectangle((cx - 0.15 * s, cy - 0.85 * s, cx + 0.15 * s, cy - 0.35 * s), fill=(220, 230, 255), outline=(30, 20, 50), width=8)
    d.ellipse((cx - 0.6 * s, cy - 0.45 * s, cx + 0.6 * s, cy + 0.75 * s), fill=fill, outline=(30, 20, 50), width=8)
    d.ellipse((cx - 0.3 * s, cy - 0.2 * s, cx - 0.1 * s, cy), fill=(255, 255, 255))

icons = {
    "Speed2x": ((20, 30, 70), (60, 200, 255), lambda d: (bolt(d, 256, 230, 170, (255, 225, 60)), text(d, "2x", 360, 120))),
    "Wins2x": ((40, 25, 10), (255, 190, 50), lambda d: (trophy(d, 256, 230, 190, (255, 210, 60)), text(d, "2x", 360, 120))),
    "VIP": ((50, 30, 5), (255, 200, 60), lambda d: (star(d, 256, 220, 170, (255, 220, 70)), text(d, "VIP", 360, 120))),
    "SpeedBurst": ((15, 30, 60), (90, 220, 255), lambda d: (bolt(d, 256, 220, 190, (255, 240, 120)), text(d, "BURST", 380, 90))),
    "SkipStage": ((50, 25, 5), (255, 150, 40), lambda d: (arrows(d, 256, 220, 200, (255, 245, 220)), text(d, "SKIP", 380, 100))),
    "Potion3x": ((40, 10, 50), (255, 90, 220), lambda d: (flask(d, 256, 210, 170, (255, 90, 220)), text(d, "3x", 370, 110))),
    "WinsS": ((40, 25, 10), (255, 190, 50), lambda d: (trophy(d, 256, 220, 170, (255, 210, 60)), text(d, "750", 370, 110))),
    "WinsL": ((40, 25, 10), (255, 220, 90), lambda d: (trophy(d, 256, 220, 190, (255, 230, 90)), text(d, "5,000", 370, 100))),
}
for name, (c1, c2, draw) in icons.items():
    im, d = base(c1, c2)
    draw(d)
    im.save(os.path.join(OUT, name + ".png"))
    print("icon", name)
