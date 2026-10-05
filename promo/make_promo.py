"""Builds the promo clips from real gameplay recordings (promo/raw/run2.mp4).
Outputs: promo/out/comet_run_vertical.mp4 (1080x1920, TikTok/Shorts/Reels)
         promo/out/comet_run_16x9.mp4   (1920x1080, X/Twitter, YouTube)
Captions are rendered with PIL (ffmpeg drawtext has no fontconfig here) and overlaid."""
import subprocess, pathlib
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent
RAW, OUT, TMP = ROOT / "raw", ROOT / "out", ROOT / "tmp"
OUT.mkdir(exist_ok=True); TMP.mkdir(exist_ok=True)
FONT = "C:/Windows/Fonts/ariblk.ttf"
THUMB = ROOT.parent / "assets/thumbnails/ai/thumb_ai_d_logo.jpg"
SEGMENTS = [(0.0, 9.0), (21.0, 33.3)]  # clean stretches of run2 (no falls)
CAPTIONS = [  # (start, end, text) on the edited timeline
    (0.0, 3.2, "EVERY SECOND\n= +1 SPEED"),
    (3.2, 9.0, "HIT THE GOLD PADS\nFOR WINS"),
    (9.0, 14.5, "COMET SHARDS =\nINSTANT SPEED"),
    (14.5, 19.5, "BREAK THROUGH\nTHE GATES"),
    (19.5, 23.0, "15 STAGES.\nHOW FAR CAN YOU GO?"),
]
END_SECONDS = 3.0

def run(args):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args], check=True)

def caption_png(text, W, H, y_center, size, path):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, size)
    box = d.multiline_textbbox((0, 0), text, font=f, align="center", spacing=10, stroke_width=10)
    tw, th = box[2] - box[0], box[3] - box[1]
    d.multiline_text(((W - tw) / 2 - box[0], y_center - th / 2 - box[1]), text, font=f, align="center",
                     spacing=10, fill=(255, 230, 40), stroke_width=10, stroke_fill=(20, 10, 40))
    im.save(path)

def end_card(W, H, path):
    th = Image.open(THUMB).convert("RGB")
    bg = th.resize((max(W, int(H * 16 / 9)), H) if W < H else (W, H)).filter(ImageFilter.GaussianBlur(30))
    bg = bg.crop(((bg.width - W) // 2, 0, (bg.width - W) // 2 + W, H)).point(lambda v: int(v * 0.6))
    fg = th.resize((W, int(W * 9 / 16))) if W < H else th.resize((int(W * 0.68), int(H * 0.68)))
    bg.paste(fg, ((W - fg.width) // 2, (H - fg.height) // 2 - (0 if W < H else 90)))
    d = ImageDraw.Draw(bg); f1 = ImageFont.truetype(FONT, 74 if W < H else 64); f2 = ImageFont.truetype(FONT, 46 if W < H else 40)
    y1 = (H + fg.height) // 2 + (90 if W < H else -70)
    for txt, f, y, col in [("PLAY NOW ON ROBLOX", f1, y1, (255, 230, 40)), ("search: +1 Speed Comet Run", f2, y1 + (110 if W < H else 80), (255, 255, 255))]:
        w = d.textlength(txt, font=f)
        d.text(((W - w) / 2, y), txt, font=f, fill=col, stroke_width=8, stroke_fill=(20, 10, 40))
    bg.save(path)

def build(name, W, H, crop, cap_y, cap_size):
    caps = []
    for i, (s, e, t) in enumerate(CAPTIONS):
        p = TMP / f"{name}_cap{i}.png"; caption_png(t, W, H, cap_y, cap_size, p); caps.append((s, e, p))
    end = TMP / f"{name}_end.png"; end_card(W, H, end)
    inputs = ["-i", str(RAW / "run2.mp4")] + sum([["-i", str(p)] for _, _, p in caps], [])
    parts = [f"[0:v]trim={s}:{e},setpts=PTS-STARTPTS,{crop}scale={W}:{H},setsar=1[s{i}]" for i, (s, e) in enumerate(SEGMENTS)]
    parts.append("".join(f"[s{i}]" for i in range(len(SEGMENTS))) + f"concat=n={len(SEGMENTS)}:v=1:a=0[base]")
    last = "base"
    for i, (s, e, _) in enumerate(caps):
        parts.append(f"[{last}][{i+1}:v]overlay=0:0:enable='between(t,{s},{e})'[o{i}]"); last = f"o{i}"
    main = TMP / f"{name}_main.mp4"
    run(inputs + ["-filter_complex", ";".join(parts), "-map", f"[{last}]", "-r", "30", "-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p", str(main)])
    endv = TMP / f"{name}_end.mp4"
    run(["-loop", "1", "-t", str(END_SECONDS), "-i", str(end), "-r", "30", "-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p", str(endv)])
    final = OUT / f"comet_run_{name}.mp4"
    run(["-i", str(main), "-i", str(endv), "-f", "lavfi", "-t", "40", "-i", "anullsrc=r=44100:cl=stereo",
         "-filter_complex", "[0:v][1:v]concat=n=2:v=1:a=0[v]", "-map", "[v]", "-map", "2:a", "-shortest",
         "-c:v", "libx264", "-crf", "20", "-pix_fmt", "yuv420p", "-c:a", "aac", "-movflags", "+faststart", str(final)])
    print(final)

# vertical: centre 608x1080 column of the 1920x1080 recording (keeps the runner + Speed counter)
build("vertical", 1080, 1920, "crop=608:1080:656:0,", 1560, 78)
build("16x9", 1920, 1080, "", 880, 84)
