"""Synthesize an original ~32 s seamless ambient loop (soft pads + arpeggio). Pure math, no samples."""
import wave, struct, math, os
SR = 22050
BPM = 96
BEAT = 60 / BPM
BARS = 12  # 4 beats each
DUR = BARS * 4 * BEAT
N = int(SR * DUR)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out"); os.makedirs(OUT, exist_ok=True)

def hz(m): return 440 * 2 ** ((m - 69) / 12)
# chord progression (midi), 2 bars each: Cmaj7, Am7, Fmaj7, G6, Em7, Fmaj9
prog = [[48, 55, 64, 71], [45, 52, 60, 67], [41, 48, 57, 64], [43, 50, 59, 64], [40, 47, 55, 62], [41, 48, 55, 64]]
buf = [0.0] * N
# pads: two detuned sines per note, slow attack/release per 2-bar chord with crossfade
for ci, chord in enumerate(prog):
    start = int(ci * 8 * BEAT * SR); length = int(8 * BEAT * SR)
    for m in chord:
        f = hz(m)
        for det in (-0.15, 0.15):
            w = 2 * math.pi * (f * (1 + det / 100)) / SR
            for i in range(length + int(SR * 1.0)):
                idx = (start + i) % N
                t = i / SR
                env = min(1.0, t / 1.2) * (1.0 if i < length else max(0.0, 1 - (i - length) / (SR * 1.0)))
                buf[idx] += 0.035 * env * math.sin(w * i)
# arpeggio: plucked triangle, 8th notes, chord tones up an octave
step = BEAT / 2
for k in range(int(DUR / step)):
    ci = int((k * step) // (8 * BEAT)) % len(prog)
    chord = prog[ci]
    m = chord[[0, 2, 1, 3, 2, 1, 3, 2][k % 8]] + 24
    f = hz(m); s0 = int(k * step * SR); L = int(SR * 0.6)
    for i in range(L):
        t = i / SR
        ph = (f * t) % 1.0
        tri = 4 * abs(ph - 0.5) - 1
        buf[(s0 + i) % N] += 0.05 * tri * math.exp(-5.5 * t)
peak = max(abs(v) for v in buf)
k = 0.8 / peak
with wave.open(os.path.join(OUT, "music_loop.wav"), "w") as wv:
    wv.setnchannels(1); wv.setsampwidth(2); wv.setframerate(SR)
    wv.writeframes(b"".join(struct.pack("<h", int(v * k * 32767)) for v in buf))
print("music", DUR, "s")
