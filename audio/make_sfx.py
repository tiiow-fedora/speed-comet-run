"""Synthesize original sound effects as 16-bit mono WAV (no samples, pure math)."""
import wave, struct, math, random, os
SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out"); os.makedirs(OUT, exist_ok=True)

def env(i, n, a=0.01, r=0.3):
    t = i / SR; dur = n / SR
    if t < a: return t / a
    return max(0.0, 1 - (t - a) / max(dur - a, 1e-6)) ** (1 / max(r, 0.05))

def tone(freq, dur, kind="sine", vol=0.5, a=0.005, decay=1.5, sweep=0.0):
    n = int(SR * dur); out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = freq * (1 + sweep * t / dur)
        ph += 2 * math.pi * f / SR
        if kind == "sine": v = math.sin(ph)
        elif kind == "square": v = 1.0 if math.sin(ph) > 0 else -1.0
        elif kind == "tri": v = 2 / math.pi * math.asin(math.sin(ph))
        else: v = random.uniform(-1, 1)
        e = min(1.0, t / a) * math.exp(-decay * t)
        out.append(v * e * vol)
    return out

def mix(*tracks, offsets=None):
    offsets = offsets or [0] * len(tracks)
    n = max(int(o * SR) + len(t) for t, o in zip(tracks, offsets))
    buf = [0.0] * n
    for t, o in zip(tracks, offsets):
        s = int(o * SR)
        for i, v in enumerate(t): buf[s + i] += v
    return buf

def save(name, buf):
    peak = max(1e-6, max(abs(v) for v in buf))
    k = 0.9 / peak
    with wave.open(os.path.join(OUT, name + ".wav"), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * k)) * 32767)) for v in buf))
    print("wrote", name, len(buf) / SR, "s")

def chord(freqs, dur, kind="tri", decay=3):
    return mix(*[tone(f, dur, kind, 0.3, decay=decay) for f in freqs])

C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0
save("gate", mix(tone(G5, 0.5, "tri", decay=5), tone(C6, 0.6, "tri", decay=4), tone(E6, 0.7, "sine", decay=3), offsets=[0, 0.07, 0.14]))
save("wins", mix(*[tone(f, 0.25, "square", 0.18, decay=10) for f in (C6, E6, G6, 2093.0)], offsets=[0, 0.06, 0.12, 0.18]))
save("buy", mix(tone(1567.98, 0.12, "square", 0.2, decay=20), tone(2093.0, 0.35, "square", 0.2, decay=8), offsets=[0, 0.08]))
save("error", mix(tone(180, 0.18, "square", 0.25, decay=8), tone(140, 0.25, "square", 0.25, decay=8), offsets=[0, 0.12]))
save("rebirth", mix(tone(220, 1.0, "tri", 0.4, decay=1.2, sweep=3.0), chord([C5, E5, G5, C6], 1.0), offsets=[0, 0.8]))
save("lap", mix(*[tone(f, 0.3, "tri", 0.35, decay=5) for f in (G5, C6, E6)] + [chord([C6, E6, G6], 0.9, decay=2)], offsets=[0, 0.12, 0.24, 0.4]))
