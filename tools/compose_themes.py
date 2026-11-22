"""Maelstrom themes. Six short pieces, all centred on D so any two sit together.

Each theme is a one-shot (with a soft head and tail) the game plays in turn over the
ambient beds. Synthesized from scratch: music box, glass, choir, plucked strings,
whistle, horn, chip pulse, soft drums.
"""
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve, lfilter
import wave, os, sys

SR = 32000
rng = np.random.default_rng(11)
OUT = sys.argv[1] if len(sys.argv) > 1 else "."


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def tt(sec):
    return np.arange(max(1, int(sec * SR))) / SR


def lp(x, f, o=2):
    return sosfilt(butter(o, f, "low", fs=SR, output="sos"), x)


def hp(x, f, o=2):
    return sosfilt(butter(o, f, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi, o=2):
    return sosfilt(butter(o, [lo, hi], "band", fs=SR, output="sos"), x)


def adsr(n, a, d, s, r):
    a, d, r = int(a * SR), int(d * SR), int(r * SR)
    env = np.full(n, s)
    if a:
        env[:a] = np.linspace(0, 1, a)[: n]
    if d and a < n:
        env[a:a + d] = np.linspace(1, s, d)[: max(0, min(d, n - a))]
    if r:
        env[-r:] *= np.linspace(1, 0, min(r, n))
    return env


def reverb(x, sec=3.5, damp=2.2, mix=0.35, bright=4000):
    n = int(sec * SR)
    ir = rng.standard_normal(n) * np.exp(-np.linspace(0, damp * 3, n))
    ir = lp(ir, bright)
    ir[: int(0.012 * SR)] = 0  # a little predelay
    ir /= np.sqrt(np.sum(ir ** 2))
    wet = fftconvolve(x, ir)[: len(x)]
    wet *= np.max(np.abs(x)) / (np.max(np.abs(wet)) + 1e-9)
    return x * (1 - mix) + wet * mix


# ---------------------------------------------------------------- instruments
def music_box(f, dur, vel=1.0):
    t = tt(dur + 2.5)
    mod = np.sin(2 * np.pi * f * 3.5 * t) * 2.2 * np.exp(-t * 6)
    y = np.sin(2 * np.pi * f * t + mod) + 0.25 * np.sin(2 * np.pi * f * 2.0 * t) * np.exp(-t * 3)
    y += 0.4 * np.sin(2 * np.pi * f * 1.003 * t)
    return y * np.exp(-t * 1.6) * np.minimum(1, t * 400) * vel


def glass(f, dur, vel=1.0):
    t = tt(dur + 1.5)
    y = sum(a * np.sin(2 * np.pi * f * r * t + rng.uniform(0, 6)) for r, a in [(1, 1), (2.0, 0.35), (3.01, 0.15), (4.2, 0.06)])
    trem = 1 + 0.12 * np.sin(2 * np.pi * 5.2 * t)
    return y * trem * adsr(len(t), 0.18, 0.3, 0.8, 1.4) * vel


def choir(freqs, dur, vel=1.0):
    t = tt(dur + 2.0)
    y = np.zeros(len(t))
    for f in freqs:
        for det in (0.997, 1.003):
            vib = 1 + 0.005 * np.sin(2 * np.pi * rng.uniform(4.6, 5.4) * t + rng.uniform(0, 6))
            ph = np.cumsum(f * det * vib) / SR
            y += 2 * (ph % 1.0) - 1  # saw
    # an "ah": three formants
    v = bp(y, 600, 820) * 1.0 + bp(y, 1100, 1350) * 0.6 + bp(y, 2400, 2800) * 0.25
    return v * adsr(len(t), 1.2, 0.5, 0.85, 1.8) * vel / max(1, len(freqs))


def pad(freqs, dur, vel=1.0, cutoff=900):
    t = tt(dur + 2.5)
    y = np.zeros(len(t))
    for f in freqs:
        for det in (0.995, 1.0, 1.005):
            ph = np.cumsum(np.full(len(t), f * det)) / SR
            y += 2 * (ph % 1.0) - 1
    y = lp(y, cutoff, 2)
    return y * adsr(len(t), 1.5, 0.5, 0.9, 2.2) * vel / (3 * max(1, len(freqs)))


def pluck(f, dur, vel=1.0, bright=0.6, decay=0.996):
    n = int((dur + 2.0) * SR)
    N = max(2, int(SR / f))
    exc = np.zeros(n)
    burst = rng.uniform(-1, 1, N)
    burst = lp(burst, 1500 + 6000 * bright)
    exc[:N] = burst
    a = np.zeros(N + 2)
    a[0] = 1.0
    a[N] = -decay * 0.5
    a[N + 1] = -decay * 0.5
    y = lfilter([1.0], a, exc)
    return y * vel


def twang(f, dur, vel=1.0):
    """A pluck with a fast tremolo and some bite: a Western guitar."""
    y = pluck(f, dur, vel, bright=0.95, decay=0.997)
    t = np.arange(len(y)) / SR
    y = y * (1 + 0.25 * np.sin(2 * np.pi * 6.5 * t))
    return np.tanh(y * 1.8) * 0.7


def whistle(f, dur, vel=1.0, glide_from=None):
    t = tt(dur + 0.6)
    f0 = glide_from if glide_from else f
    glide = np.minimum(1, t / 0.18)
    fr = f0 + (f - f0) * (1 - (1 - glide) ** 2)
    vib = 1 + 0.008 * np.sin(2 * np.pi * 5.6 * t) * np.minimum(1, t / 0.5)
    ph = 2 * np.pi * np.cumsum(fr * vib) / SR
    tone = np.sin(ph) + 0.06 * np.sin(2 * ph)
    breath = bp(rng.standard_normal(len(t)), f * 0.9, f * 1.15) * 0.12
    return (tone + breath) * adsr(len(t), 0.06, 0.2, 0.85, 0.5) * vel


def horn(f, dur, vel=1.0):
    t = tt(dur + 1.0)
    ph = np.cumsum(f * (1 + 0.003 * np.sin(2 * np.pi * 4.8 * t))) / SR
    y = 2 * (ph % 1.0) - 1
    env = adsr(len(t), 0.45, 0.4, 0.85, 0.9)
    # the brightness swells with the note
    y = lp(y, 700, 2) * (0.5 + 0.5 * env) + lp(y, 1600, 2) * 0.3 * env
    return y * env * vel


def chip(f, dur, vel=1.0, duty=0.3, wobble=0.0, crush=0):
    t = tt(dur + 0.4)
    drift = 1 + wobble * np.sin(2 * np.pi * 3.1 * t) * np.minimum(1, t / 0.6)
    ph = np.cumsum(f * drift) / SR
    y = np.where((ph % 1.0) < duty, 1.0, -1.0)
    y = lp(y, 2400, 2)
    if crush:
        y = np.round(y * crush) / crush
    return y * adsr(len(t), 0.01, 0.15, 0.6, 0.25) * vel


def soft_bass(f, dur, vel=1.0):
    t = tt(dur + 1.0)
    y = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)
    return y * np.exp(-t * 1.5) * np.minimum(1, t * 200) * vel


def step(vel=1.0):
    t = tt(0.35)
    thump = np.sin(2 * np.pi * (70 * np.exp(-t * 9) + 40) * t) * np.exp(-t * 14)
    grit = lp(rng.standard_normal(len(t)), 900) * np.exp(-t * 30) * 0.4
    return (thump + grit) * vel


def timp(f, vel=1.0):
    t = tt(2.5)
    y = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 1.5 * t)
    y += lp(rng.standard_normal(len(t)), 600) * np.exp(-t * 25) * 0.6
    return y * np.exp(-t * 1.8) * vel


def click(vel=1.0):
    t = tt(0.06)
    return bp(rng.standard_normal(len(t)), 2000, 6000) * np.exp(-t * 90) * vel


# ---------------------------------------------------------------- sequencing
class Track:
    def __init__(self, bpm, beats_total, head=1.5, tail=5.0):
        self.spb = 60.0 / bpm
        self.head = head
        self.buf = np.zeros(int((head + beats_total * self.spb + tail) * SR))

    def at(self, beat):
        return self.head + beat * self.spb

    def put(self, sound, beat, gain=1.0):
        i = int(self.at(beat) * SR)
        j = min(len(self.buf), i + len(sound))
        if i < len(self.buf):
            self.buf[i:j] += sound[: j - i] * gain

    def beats(self, b):
        return b * self.spb


def melody(track, notes, inst, start=0.0, gain=1.0, swing=0.0, **kw):
    """notes: (midi or None, beats). swing pushes off-beat eighths late (shuffle)."""
    b = start
    for m, length in notes:
        if m is not None:
            pos = b
            if swing and abs((b * 2) % 2 - 1) < 1e-6:
                pos = b + swing * 0.5
            track.put(inst(hz(m), track.beats(length), **kw), pos, gain)
        b += length
    return b


def finish(x, name, peak=0.7):
    # soft head and tail so the piece arrives and leaves rather than starts and stops
    n = len(x)
    fade_in = int(1.0 * SR)
    fade_out = int(4.0 * SR)
    x[:fade_in] *= np.linspace(0, 1, fade_in)
    x[-fade_out:] *= np.linspace(1, 0, fade_out) ** 1.5
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    d = int(0.013 * SR)
    r = np.concatenate([np.zeros(d), x[:-d]])
    st = np.stack([x * 0.9 + r * 0.1, r * 0.9 + x * 0.1], 1)
    data = (np.clip(st, -1, 1) * 32767).astype(np.int16)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"{name}: {n / SR:.1f}s")


D3, E3, F3, G3, A3, Bb3, C4, Cs4 = 50, 52, 53, 55, 57, 58, 60, 61
D4, E4, F4, G4, Gs4, A4, Bb4, C5, Cs5 = 62, 64, 65, 67, 68, 69, 70, 72, 73
D5, E5, F5, G5, Gs5, A5, C6 = 74, 76, 77, 79, 80, 81, 84
R = None

CHORDS = {
    "Dm": [50, 57, 62, 65], "Gm": [43, 55, 58, 62], "F": [41, 53, 57, 60], "Bb": [46, 53, 58, 62],
    "C": [48, 55, 60, 64], "A": [45, 57, 61, 64], "Asus": [45, 57, 62, 64], "E": [40, 56, 59, 64],
    "Gm6": [43, 55, 58, 64], "Dm9": [50, 57, 64, 65],
}


def chord_hz(name, drop=0):
    return [hz(m + drop) for m in CHORDS[name]]


# ---------------------------------------------------------------- the town: a half-remembered waltz
def theme_town():
    bpm, bar = 66, 3
    prog = ["Dm", "Dm", "Dm", "Gm", "F", "Bb", "Gm", "C", "Dm", "Asus",
            "Dm", "Gm", "F", "Bb", "Gm", "C", "A", "Dm9", "Dm9"]
    tr = Track(bpm, len(prog) * bar)
    for i, c in enumerate(prog):
        tr.put(pad(chord_hz(c), tr.beats(bar) * 1.05, 0.55, 700), i * bar)
        root = CHORDS[c][0]
        tr.put(pluck(hz(root), 2.5, 0.5, 0.3), i * bar)
        tr.put(pluck(hz(root + 7), 1.5, 0.22, 0.3), i * bar + 1)
        tr.put(pluck(hz(root + 12), 1.5, 0.18, 0.3), i * bar + 2)
    a = [(A4, 2), (F4, 1), (G4, 1.5), (A4, 0.5), (Bb4, 1), (A4, 3), (R, 1), (D5, 1), (C5, 1),
         (Bb4, 2), (A4, 1), (G4, 1), (F4, 1), (E4, 1), (F4, 2), (D4, 1), (E4, 3)]
    a2 = [(A4, 2), (F4, 1), (G4, 1.5), (A4, 0.5), (Bb4, 1), (A4, 3), (R, 1), (D5, 1), (C5, 1),
          (Bb4, 1), (C5, 1), (D5, 1), (E5, 2), (D5, 1), (Cs5, 1.5), (Bb4, 0.5), (A4, 1), (A4, 3)]
    b = melody(tr, a, music_box, start=2 * bar, gain=0.9)
    melody(tr, a2, music_box, start=b, gain=0.9)
    return reverb(tr.buf, 4.0, 1.8, 0.4)


# ---------------------------------------------------------------- the road: footsteps and a searching horn
def theme_road():
    bpm, bar = 72, 4
    bars = 15
    tr = Track(bpm, bars * bar)
    ost_d = [D3, A3, D4, A3, 63, A3, D4, A3]       # Eb: the Phrygian second, the dread in the road
    ost_c = [48, G3, C4, G3, 62, G3, C4, G3]
    for i in range(bars):
        for k in range(4):
            tr.put(step(0.55 if k % 2 == 0 else 0.35), i * bar + k)
        ost = ost_c if i in (8, 9) else ost_d
        for k, m in enumerate(ost):
            tr.put(pluck(hz(m), 0.6, 0.32 if k == 0 else 0.2, 0.25, 0.993), i * bar + k * 0.5)
        root = 48 if i in (8, 9) else 50
        tr.put(pad([hz(root - 12), hz(root - 5)], tr.beats(bar), 0.5, 400), i * bar)
    lead = [(R, 8), (A4, 4), (G4, 2), (F4, 2), (63 + 1 - 1, 3), (F4, 1), (D4, 4),
            (R, 2), (A4, 1), (Bb4, 1), (C5, 3), (Bb4, 1), (A4, 2), (G4, 1), (F4, 1), (G4, 4),
            (F4, 2), (63, 2), (D4, 4)]
    melody(tr, lead, horn, gain=0.75)
    return reverb(tr.buf, 5.0, 1.6, 0.42, 3000)


# ---------------------------------------------------------------- camp: guitar by the fire, a hummed tune
def theme_camp():
    eighths_per_min = 138
    bar = 6
    prog = ["Dm9", "Dm9", "Bb", "Bb", "Gm6", "Gm6", "Asus", "A", "Dm9", "Bb", "Gm6", "Dm9"]
    tr = Track(eighths_per_min, len(prog) * bar, tail=6.0)
    for i, c in enumerate(prog):
        notes = CHORDS[c]
        arp = [notes[0], notes[1], notes[2], notes[3], notes[2], notes[1]]
        for k, m in enumerate(arp):
            tr.put(pluck(hz(m), 1.5, 0.4 if k == 0 else 0.26, 0.45, 0.995), i * bar + k + (0.04 if k % 3 else 0))
    hum = [(R, 12), (F4, 3), (E4, 1), (D4, 2), (D4, 6), (A4, 3), (G4, 1), (F4, 2), (E4, 6),
           (F4, 2), (G4, 1), (A4, 3), (Bb4, 2), (A4, 2), (G4, 2), (F4, 3), (E4, 3), (D4, 6)]

    def hummed(f, dur, vel=1.0):
        t = tt(dur + 0.8)
        vib = 1 + 0.006 * np.sin(2 * np.pi * 5.0 * t) * np.minimum(1, t / 0.4)
        ph = 2 * np.pi * np.cumsum(f * vib) / SR
        y = np.sin(ph) + 0.2 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)
        return lp(y, 1200) * adsr(len(t), 0.15, 0.2, 0.8, 0.6) * vel

    melody(tr, hum, hummed, gain=0.42)
    return reverb(tr.buf, 2.2, 2.6, 0.25, 5000)


# ---------------------------------------------------------------- the Oracleborn: a broken processional
def theme_oracle():
    bpm, bar = 54, 4
    prog = ["Dm", "Bb", "E", "A", "Dm", "Gm", "A", "Dm", "Bb", "E", "Gm6", "A"]
    tr = Track(bpm, (len(prog) + 1) * bar, tail=6.0)
    for i, c in enumerate(prog):
        tr.put(choir(chord_hz(c), tr.beats(bar) * 1.02, 0.6), i * bar)
        if i % 2 == 0:
            tr.put(timp(hz(CHORDS[c][0] - 12), 0.5), i * bar)
        tr.put(pluck(hz(CHORDS[c][1]), 2.5, 0.22, 0.5), i * bar + 2)
    lead = [(D4, 2), (A4, 2), (D5, 3), (C5, 1), (Bb4, 2), (A4, 1), (Gs4, 1), (A4, 4),
            (F4, 2), (G4, 1), (A4, 1), (Bb4, 2), (D5, 2), (Cs5, 2), (E5, 1), (D5, 1), (D5, 4),
            (R, 2), (A5, 2), (Gs5, 1), (F5, 1), (E5, 2), (D5, 2), (Cs5, 1), (Bb4, 1), (A4, 4)]
    melody(tr, lead, glass, gain=0.85)
    return reverb(tr.buf, 5.5, 1.4, 0.48, 3500)


# ---------------------------------------------------------------- the Engineer: a level-start jingle, played slow, failing
def theme_engineer():
    bpm, bar = 92, 4
    bars = 16
    prog = ["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "Asus", "Asus"] * 2
    tr = Track(bpm, bars * bar, tail=5.0)
    pattern = [0, 1, 2, 3, 2, 1, 0]  # seven against sixteen: never quite lining up
    k = 0
    for i in range(bars):
        notes = CHORDS[prog[i]]
        for s in range(16):
            m = notes[pattern[k % 7]] + 12
            k += 1
            fade = 1.0 if i < 12 else (16 - i) / 4.0
            tr.put(chip(hz(m), tr.beats(0.25), 0.16 * fade, duty=0.5), i * bar + s * 0.25)
        tr.put(soft_bass(hz(notes[0] - 12), tr.beats(bar), 0.5), i * bar)
    jingle = [(D5, 0.5), (F5, 0.5), (A5, 1), (G5, 0.5), (F5, 0.5), (D5, 1), (C5, 2), (R, 2),
              (D5, 0.5), (F5, 0.5), (A5, 1), (C6, 1), (A5, 1), (G5, 3), (R, 1),
              (F5, 1), (G5, 1), (A5, 1), (F5, 1), (D5, 2), (C5, 1), (A4, 1), (C5, 1), (D5, 3), (R, 4)]
    end = melody(tr, jingle, chip, gain=0.55, duty=0.25, wobble=0.003)
    # the second time it fails: a skipped note, a held note that warbles, a note that sticks
    broken = [(D5, 0.5), (F5, 0.5), (A5, 1), (R, 0.5), (F5, 0.5), (D5, 1), (C5, 4),
              (D5, 0.5), (F5, 0.5), (A5, 1), (C6, 0.5), (C6, 0.5), (C6, 1), (R, 4),
              (F5, 1), (G5, 1), (A5, 2), (R, 4), (D5, 4)]
    melody(tr, broken, chip, start=end, gain=0.5, duty=0.25, wobble=0.02, crush=4)
    return reverb(tr.buf, 2.8, 2.0, 0.3, 5000)


# ---------------------------------------------------------------- Alysia: a lonely Western
def theme_gunslinger():
    bpm, bar = 80, 4
    prog = ["Dm", "Dm", "Dm", "C", "Gm", "Dm", "Dm", "A", "Dm", "Dm", "F", "C", "Gm", "A", "Dm"]
    tr = Track(bpm, len(prog) * bar, tail=6.0)
    for i, c in enumerate(prog):
        root = CHORDS[c][0]
        fifth = root + 7
        # boom-chick with a loping shuffle
        for k in range(4):
            m = root if k % 2 == 0 else fifth
            tr.put(twang(hz(m), 1.0, 0.55 if k == 0 else 0.38), i * bar + k)
            tr.put(twang(hz(CHORDS[c][2]), 0.4, 0.18), i * bar + k + 2.0 / 3.0)
        tr.put(click(0.25), i * bar + 1)
        tr.put(click(0.25), i * bar + 3)
    lead = [(R, 8), (A4, 3), (D5, 1), (C5, 2), (A4, 2), (Bb4, 1.5), (A4, 0.5), (G4, 2), (A4, 4),
            (D5, 3), (F5, 1), (E5, 2), (D5, 1), (C5, 1), (D5, 4), (R, 4),
            (F5, 2), (E5, 1), (D5, 1), (C5, 2), (A4, 2), (Bb4, 2), (G4, 1), (E4, 1), (D4, 4)]
    b = 0.0
    prev = None
    for m, length in lead:
        if m is not None:
            leap = prev is not None and abs(m - prev) >= 5
            tr.put(whistle(hz(m), tr.beats(length), 0.7, glide_from=hz(prev) if leap else None), b)
            prev = m
        b += length
    return reverb(tr.buf, 4.5, 1.5, 0.45, 4000)


if __name__ == "__main__":
    for name, fn in [("theme_town", theme_town), ("theme_road", theme_road), ("theme_camp", theme_camp),
                     ("theme_oracle", theme_oracle), ("theme_engineer", theme_engineer), ("theme_gunslinger", theme_gunslinger)]:
        finish(fn(), name)
