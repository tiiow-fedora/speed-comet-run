"""Over-the-top "hype" edit of the real gameplay take (raw/run2.mp4).
No music. Every sound effect is synthesized here from math (no samples), same approach as audio/make_sfx.py.
Effects: speed ramps, punch zooms, screen shake, white flashes, RGB split, word-pop captions, logo slam end card.
Outputs: out/comet_run_hype_vertical.mp4 (1080x1920) and out/comet_run_hype_16x9.mp4 (1920x1080)."""
import subprocess, pathlib, math, wave, struct
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from scipy.signal import butter, lfilter

ROOT = pathlib.Path(__file__).resolve().parent
RAW, OUT, TMP = ROOT / "raw", ROOT / "out", ROOT / "tmp"
OUT.mkdir(exist_ok=True); TMP.mkdir(exist_ok=True)
SRC = RAW / "run2.mp4"
FONT = "C:/Windows/Fonts/ariblk.ttf"
THUMB = ROOT.parent / "assets/thumbnails/ai/thumb_ai_d_logo.jpg"
GAME_SFX = ROOT.parent / "audio/out"
FPS, SR = 30, 44100

# ---------------- timeline ----------------
# (src_start, src_end, speed). Output time accumulates.
SEGMENTS = [(0.0, 2.0, 1.0), (2.0, 9.0, 1.45), (21.0, 33.3, 1.3)]
END_LEN = 3.2

def src_to_out(ts):
    t = 0.0
    for a, b, sp in SEGMENTS:
        if a <= ts <= b: return t + (ts - a) / sp
        t += (b - a) / sp
    raise ValueError(ts)

SEG_STARTS = []
_t = 0.0
for a, b, sp in SEGMENTS:
    SEG_STARTS.append(_t); _t += (b - a) / sp
MAIN_LEN = _t
TOTAL = MAIN_LEN + END_LEN

E_WINS10, E_SHARD, E_GATE, E_WINS50 = (src_to_out(x) for x in (6.7, 22.6, 30.4, 32.0))
CUT = SEG_STARTS[2]
# punch zooms: (time, strength, shake_px, flash, rgb_split)
PUNCHES = [(0.0, 0.0, 26, 0.0, 10), (E_WINS10, 0.35, 18, 0.0, 6), (CUT, 0.45, 22, 0.55, 12),
           (E_SHARD, 0.55, 28, 0.35, 14), (E_GATE, 0.6, 34, 0.9, 18), (E_WINS50, 0.45, 22, 0.3, 10)]
# captions: (start, end, text, color)
Y, W_ = (255, 228, 30), (255, 255, 255)
CAPTIONS = [(0.05, 0.75, "EVERY SECOND", W_), (0.75, 2.0, "= +1 SPEED", Y),
            (2.0, E_WINS10, "HIT THE\nGOLD PADS", W_), (E_WINS10, CUT, "+10 WINS!!", Y),
            (CUT, E_SHARD, "MARS?!", W_), (E_SHARD, E_SHARD + 1.6, "COMET SHARD\n+75 SPEED!!", Y),
            (E_SHARD + 1.6, E_GATE, "WATCH THIS", W_), (E_GATE, E_WINS50, "BREAK\nTHROUGH!!", Y),
            (E_WINS50, MAIN_LEN, "+50 WINS!!!", Y)]

# ---------------- sound design (all synthesized) ----------------
def tvec(d): return np.arange(int(d * SR)) / SR
def boom(d=1.1, f0=140, f1=38):
    t = tvec(d); f = f1 + (f0 - f1) * np.exp(-t * 9); ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * np.exp(-t * 3.2) + 0.5 * np.random.uniform(-1, 1, t.size) * np.exp(-t * 60)
    return np.tanh(2.2 * x)
def whoosh(d=0.45, up=True):
    t = tvec(d); n = np.random.uniform(-1, 1, t.size)
    b, a = butter(2, [400 / (SR / 2), 6000 / (SR / 2)], "band"); n = lfilter(b, a, n)
    env = np.sin(np.pi * np.clip(t / d, 0, 1)) ** 2
    return n * env * 2.5
def riser(d=1.6):
    t = tvec(d); f = 200 * (10 ** (t / d)); ph = 2 * np.pi * np.cumsum(f) / SR
    n = np.random.uniform(-1, 1, t.size); b, a = butter(2, 3000 / (SR / 2), "high"); n = lfilter(b, a, n)
    return (0.5 * np.sin(ph) + 0.6 * n) * (t / d) ** 2
def bling():
    t = tvec(0.7); x = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * k) for f, k in ((2093, 6), (3136, 8), (4186, 10)))
    return x / 2
def pop():
    t = tvec(0.09); f = 500 + 1400 * t / 0.09
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 40)
def horn(d=0.7):
    t = tvec(d); x = np.zeros_like(t)
    for f in (233.08, 349.23, 466.16):  # Bb3, F4, Bb4 stack; sawtooth with a little vibrato
        ph = 2 * np.pi * np.cumsum(f * (1 + 0.006 * np.sin(2 * np.pi * 6 * t))) / SR
        x += 2 * ((ph / (2 * np.pi)) % 1) - 1
    env = np.minimum(1, t / 0.02) * np.where(t > d - 0.1, (d - t) / 0.1, 1)
    return np.tanh(1.5 * x / 3 * env)
def bass_drop(d=1.6):
    t = tvec(d); f = 35 + 60 * np.exp(-t * 2.5); ph = 2 * np.pi * np.cumsum(f) / SR
    return np.tanh(3 * np.sin(ph) * np.exp(-t * 1.1))
def load_wav(name):
    with wave.open(str(GAME_SFX / f"{name}.wav")) as w:
        x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
    return x

def build_audio(path):
    mixbuf = np.zeros(int((TOTAL + 1) * SR))
    def put(x, t, g):
        s = int(t * SR); mixbuf[s:s + x.size] += g * x[: max(0, mixbuf.size - s)]
    put(boom(), 0.0, 0.9); put(pop(), 0.05, 0.5); put(pop(), 0.75, 0.5); put(boom(0.6, 200, 60), 0.75, 0.5)
    put(whoosh(), 1.75, 0.5); put(pop(), 2.0, 0.45)
    put(load_wav("wins"), E_WINS10, 0.7); put(bling(), E_WINS10, 0.35); put(boom(0.7, 180, 50), E_WINS10, 0.55)
    put(whoosh(0.5), CUT - 0.3, 0.7); put(boom(), CUT, 0.7); put(pop(), CUT + 0.02, 0.4)
    put(bling(), E_SHARD, 0.5); put(boom(0.9, 160, 45), E_SHARD, 0.75); put(whoosh(0.3), E_SHARD + 0.05, 0.35)
    put(pop(), E_SHARD + 1.6, 0.45); put(riser(E_GATE - (E_SHARD + 1.6)), E_SHARD + 1.6, 0.4)
    put(boom(1.3), E_GATE, 1.0); put(horn(), E_GATE + 0.02, 0.5); put(load_wav("gate"), E_GATE, 0.6)
    put(load_wav("wins"), E_WINS50, 0.75); put(bling(), E_WINS50, 0.4); put(boom(0.7, 180, 50), E_WINS50, 0.55)
    put(riser(1.0), MAIN_LEN - 1.0, 0.45); put(whoosh(0.4), MAIN_LEN - 0.25, 0.6)
    put(bass_drop(), MAIN_LEN, 1.0); put(boom(1.4), MAIN_LEN, 0.8); put(horn(0.5), MAIN_LEN + 0.05, 0.35)
    put(pop(), MAIN_LEN + 0.45, 0.5); put(bling(), MAIN_LEN + 0.45, 0.35)
    mixbuf = mixbuf[: int(TOTAL * SR)]
    mixbuf = np.tanh(1.3 * mixbuf / max(1e-6, np.abs(mixbuf).max())) * 0.95
    st = np.stack([mixbuf, mixbuf], 1)
    with wave.open(str(path), "w") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((st * 32767).astype(np.int16).tobytes())

# ---------------- video ----------------
def punch_state(t):
    z, sx, sy, fl, rgb = 0.0, 0.0, 0.0, 0.0, 0.0
    for te, zs, sh, f, r in PUNCHES:
        dt = t - te
        if dt < -0.05 or dt > 1.0: continue
        k = (dt + 0.05) / 0.05 if dt < 0 else math.exp(-dt / 0.22)
        z += zs * k; fl = max(fl, f * (math.exp(-dt / 0.12) if dt >= 0 else 0))
        rgb = max(rgb, r * k); a = sh * (math.exp(-dt / 0.18) if dt >= 0 else 0)
        sx += a * math.sin(dt * 91 + te); sy += a * math.cos(dt * 77 + te * 2)
    return z, sx, sy, fl, rgb

def caption_img(text, color, size):
    f = ImageFont.truetype(FONT, size)
    tmp = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    box = [int(math.ceil(v)) for v in tmp.multiline_textbbox((0, 0), text, font=f, align="center", spacing=6, stroke_width=12)]
    im =Image.new("RGBA", (box[2] - box[0] + 40, box[3] - box[1] + 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.multiline_text((20 - box[0] + 8, 20 - box[1] + 10), text, font=f, align="center", spacing=6, fill=(0, 0, 0, 160),
                     stroke_width=12, stroke_fill=(0, 0, 0, 160))  # drop shadow
    d.multiline_text((20 - box[0], 20 - box[1]), text, font=f, align="center", spacing=6, fill=color,
                     stroke_width=12, stroke_fill=(25, 8, 45))
    return im

def frame_reader(a, b, sp):
    """Yields source frames for output frames of this segment (nearest-frame speed ramp)."""
    w, h = 1920, 1080
    p = subprocess.Popen(["ffmpeg", "-hide_banner", "-loglevel", "error", "-ss", str(a), "-t", str(b - a + 0.2),
                          "-i", str(SRC), "-f", "rawvideo", "-pix_fmt", "rgb24", "-r", str(FPS), "-"],
                         stdout=subprocess.PIPE)
    n_out = int(round((b - a) / sp * FPS)); src_idx = -1; cur = None
    for i in range(n_out):
        want = int(i * sp)
        while src_idx < want:
            buf = p.stdout.read(w * h * 3)
            if len(buf) < w * h * 3: break
            cur = np.frombuffer(buf, np.uint8).reshape(h, w, 3); src_idx += 1
        yield cur
    p.stdout.close(); p.wait()

def render(name, W, H, vertical):
    cap_cache = {}
    cap_size = 96 if vertical else 100
    cap_y = int(H * (0.74 if vertical else 0.78))
    base_crop_w = 608 if vertical else 1920
    enc = subprocess.Popen(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
                            "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-c:v", "libx264", "-preset", "medium",
                            "-crf", "19", "-pix_fmt", "yuv420p", str(TMP / f"hype_{name}_v.mp4")], stdin=subprocess.PIPE)
    fi = 0
    for (a, b, sp), t0 in zip(SEGMENTS, SEG_STARTS):
        for k, src in enumerate(frame_reader(a, b, sp)):
            t = t0 + k / FPS
            z, sx, sy, fl, rgb = punch_state(t)
            if t < 1.4:  # hook: start zoomed into the Speed counter, ease out
                e = 1 - min(1, t / 1.4) ** 2
                z += (0.45 if vertical else 1.3) * e; cy = 540 - (540 - (330 if vertical else 260)) * e
            else:
                cy = 540
            zz = 1 + z
            cw, ch = base_crop_w / zz, 1080 / zz
            cx = 960 + sx; cyy = min(max(cy + sy, ch / 2), 1080 - ch / 2)
            cx = min(max(cx, cw / 2), 1920 - cw / 2)
            im = Image.fromarray(src).crop((int(cx - cw / 2), int(cyy - ch / 2), int(cx + cw / 2), int(cyy + ch / 2)))
            im = im.resize((W, H), Image.BILINEAR)
            arr = np.asarray(im).astype(np.int16)
            if rgb > 0.5:
                r = int(rgb); arr = arr.copy(); arr[:, :, 0] = np.roll(arr[:, :, 0], r, 1); arr[:, :, 2] = np.roll(arr[:, :, 2], -r, 1)
            if fl > 0.01:
                arr = arr + (255 - arr) * fl
            im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
            for s, e, text, col in CAPTIONS:
                if s <= t < e:
                    key = (text, col)
                    if key not in cap_cache: cap_cache[key] = caption_img(text, col, cap_size)
                    c = cap_cache[key]; dt = t - s
                    sc = 1.0 + 0.6 * math.exp(-dt / 0.07) * (1 if dt < 0.25 else 0) - 0.08 * math.sin(min(dt, 0.3) * 20) * math.exp(-dt / 0.1)
                    maxw = W * 0.94
                    sc *= min(1.0, maxw / c.width)
                    cs = c.resize((max(1, int(c.width * sc)), max(1, int(c.height * sc))), Image.BILINEAR)
                    ang = 4 * math.sin(fi * 0.15) if "!!" in text else 0
                    if ang: cs = cs.rotate(ang, resample=Image.BILINEAR, expand=True)
                    im.paste(cs, ((W - cs.width) // 2, cap_y - cs.height // 2), cs)
            enc.stdin.write(im.tobytes()); fi += 1
    # end card: logo slam
    th = Image.open(THUMB).convert("RGB")
    bgw = W if not vertical else int(H * 16 / 9)
    bg = th.resize((bgw, H)).filter(ImageFilter.GaussianBlur(28)).point(lambda v: int(v * 0.55))
    bg = bg.crop(((bg.width - W) // 2, 0, (bg.width - W) // 2 + W, H))
    fg_w = W if vertical else int(W * 0.7)
    fg = th.resize((fg_w, int(fg_w * 9 / 16)))
    play = caption_img("PLAY NOW\nON ROBLOX" if vertical else "PLAY NOW ON ROBLOX", Y, 92 if vertical else 80)
    srch = caption_img("search: +1 Speed Comet Run", W_, 50 if vertical else 46)
    fg_y = (H - fg.height) // 2 - (120 if vertical else 110)
    for k in range(int(END_LEN * FPS)):
        dt = k / FPS
        frame = bg.copy()
        sc = 1 + 0.9 * math.exp(-dt / 0.08); shake = 30 * math.exp(-dt / 0.15)
        f2 = fg.resize((int(fg.width * sc), int(fg.height * sc)), Image.BILINEAR)
        ox = int(shake * math.sin(dt * 90)); oy = int(shake * math.cos(dt * 70))
        frame.paste(f2, ((W - f2.width) // 2 + ox, fg_y + (fg.height - f2.height) // 2 + oy))
        if dt >= 0.45:
            d2 = dt - 0.45; s2 = 1 + 0.5 * math.exp(-d2 / 0.07)
            p2 = play.resize((int(play.width * s2), int(play.height * s2)), Image.BILINEAR)
            py = fg_y + fg.height + (40 if vertical else 10)
            frame.paste(p2, ((W - p2.width) // 2, py), p2)
            frame.paste(srch, ((W - srch.width) // 2, py + play.height - 10), srch)
        arr = np.asarray(frame).astype(np.int16)
        fl = 0.8 * math.exp(-dt / 0.1)
        arr = np.clip(arr + (255 - arr) * fl, 0, 255).astype(np.uint8)
        enc.stdin.write(arr.tobytes())
    enc.stdin.close(); enc.wait()
    wav = TMP / "hype_sfx.wav"
    if not wav.exists(): build_audio(wav)
    final = OUT / f"comet_run_hype_{name}.mp4"
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(TMP / f"hype_{name}_v.mp4"), "-i", str(wav),
                    "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest",
                    "-movflags", "+faststart", str(final)], check=True)
    print(final, f"{TOTAL:.1f}s")

if __name__ == "__main__":
    np.random.seed(7)
    (TMP / "hype_sfx.wav").unlink(missing_ok=True)
    print("events (out s):", dict(wins10=round(E_WINS10, 2), cut=round(CUT, 2), shard=round(E_SHARD, 2), gate=round(E_GATE, 2), wins50=round(E_WINS50, 2), end=round(MAIN_LEN, 2)))
    render("vertical", 1080, 1920, True)
    render("16x9", 1920, 1080, False)
