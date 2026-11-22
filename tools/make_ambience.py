"""Procedural ambience for Maelstrom. Quiet, low, seamless loops.

Base layers (one per place): town, road, camp.
Hero layers (laid over the base): oracle, engineer, gunslinger.
Writes 16-bit stereo WAVs; encode to Ogg afterwards.
"""
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
import wave, sys, os

SR = 22050
rng = np.random.default_rng(7)
OUT = sys.argv[1] if len(sys.argv) > 1 else "."


def t_axis(sec):
    return np.arange(int(sec * SR)) / SR


def lp(x, hz, order=2):
    return sosfilt(butter(order, hz, "low", fs=SR, output="sos"), x)


def hp(x, hz, order=2):
    return sosfilt(butter(order, hz, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], "band", fs=SR, output="sos"), x)


def pink(n):
    w = rng.standard_normal(n)
    f = np.fft.rfft(w)
    k = np.arange(len(f))
    k[0] = 1
    f /= np.sqrt(k)
    p = np.fft.irfft(f, n)
    return p / np.max(np.abs(p))


def slow_env(n, rate_hz, lo=0.3, hi=1.0):
    """A smooth random envelope: random points every 1/rate seconds, smoothly joined."""
    pts = int(n / SR * rate_hz) + 3
    v = rng.uniform(lo, hi, pts)
    x = np.linspace(0, pts - 1, n)
    i = np.floor(x).astype(int)
    fr = x - i
    fr = (1 - np.cos(fr * np.pi)) / 2
    return v[i] * (1 - fr) + v[np.minimum(i + 1, pts - 1)] * fr


def room(x, seconds=2.5, damp=3.0):
    """Cheap reverb: convolve with decaying noise."""
    n = int(seconds * SR)
    ir = rng.standard_normal(n) * np.exp(-np.linspace(0, damp * 3, n))
    ir = lp(ir, 3000)
    ir /= np.sum(np.abs(ir)) / 6
    return fftconvolve(x, ir)[: len(x)]


def bell(f0, dur=7.0, bright=1.0):
    t = t_axis(dur)
    partials = [(1.0, 1.0), (2.76, 0.5), (5.40, 0.25 * bright), (8.93, 0.12 * bright), (0.56, 0.35)]
    out = np.zeros_like(t)
    for ratio, amp in partials:
        decay = 1.2 + 3.5 / ratio
        out += amp * np.sin(2 * np.pi * f0 * ratio * t + rng.uniform(0, 6)) * np.exp(-t / decay)
    return out * np.minimum(1, t * 200)


def place(buf, sound, at):
    i = int(at * SR)
    j = min(len(buf), i + len(sound))
    buf[i:j] += sound[: j - i]


def seamless(x, fade=3.0):
    """Wraps the tail over the head so the loop has no seam."""
    n = int(fade * SR)
    head, body, tail = x[:n], x[n:-n] if n else x, x[-n:]
    ramp = np.linspace(0, 1, n)
    joined = head * ramp + tail * (1 - ramp)
    return np.concatenate([joined, x[n:-n]])


def stereo(x, width=0.25, delay_ms=11):
    d = int(delay_ms / 1000 * SR)
    r = np.concatenate([x[-d:], x[:-d]])
    l = x
    return np.stack([l * (1 - width / 2) + r * width / 2, r * (1 - width / 2) + l * width / 2], 1)


def write(name, x, peak=0.5):
    x = seamless(x)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    s = stereo(x)
    data = (np.clip(s, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("wrote", name, len(x) / SR, "s")


# ---------------------------------------------------------------- town
def town(sec=64):
    t = t_axis(sec + 3)
    n = len(t)
    drone = (np.sin(2 * np.pi * 55 * t) + 0.8 * np.sin(2 * np.pi * 55.35 * t)
             + 0.45 * np.sin(2 * np.pi * 82.4 * t + 1) + 0.2 * np.sin(2 * np.pi * 110.2 * t))
    drone *= 0.22 * slow_env(n, 0.06, 0.5, 1.0)
    wind = lp(pink(n), 380) * slow_env(n, 0.15, 0.2, 1.0) * 0.9
    out = drone + wind
    # distant bells: low, far, washed in room
    bells = np.zeros(n)
    at = 3.0
    while at < sec - 4:
        f = rng.choice([146.8, 164.8, 196.0, 110.0])
        b = bell(f, 8.0, bright=0.6) * rng.uniform(0.18, 0.3)
        place(bells, lp(b, 1400), at)
        at += rng.uniform(13, 22)
    out += room(bells, 4.0, 2.0)
    # creaks: timber settling somewhere
    at = 6.0
    while at < sec - 2:
        dur = rng.uniform(0.25, 0.6)
        tt = t_axis(dur)
        f = np.linspace(rng.uniform(180, 260), rng.uniform(120, 170), len(tt))
        ph = 2 * np.pi * np.cumsum(f) / SR
        creak = np.sign(np.sin(ph)) * 0.6 + np.sin(ph * 2) * 0.4
        creak = bp(creak * rng.standard_normal(len(tt)) * 0.3 + creak * 0.2, 200, 1400) * np.hanning(len(tt))
        place(out, creak * 0.12, at)
        at += rng.uniform(7, 15)
    return out


# ---------------------------------------------------------------- road
def road(sec=64):
    t = t_axis(sec + 3)
    n = len(t)
    sub = (np.sin(2 * np.pi * 36.7 * t) + 0.6 * np.sin(2 * np.pi * 37.1 * t)) * 0.3 * slow_env(n, 0.05, 0.4, 1)
    wind = lp(pink(n), 700) * slow_env(n, 0.22, 0.15, 1.0) * 1.1
    whistle = bp(rng.standard_normal(n), 820, 900, 2) * slow_env(n, 0.1, 0.0, 1.0) ** 3 * 0.9
    out = sub + wind + whistle
    # far groans: something big shifting out in the void
    at = 8.0
    while at < sec - 6:
        dur = rng.uniform(3, 5)
        tt = t_axis(dur)
        f = np.linspace(rng.uniform(62, 78), rng.uniform(44, 52), len(tt))
        ph = 2 * np.pi * np.cumsum(f) / SR
        g = (np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.3 * np.sin(3.01 * ph)) * np.hanning(len(tt)) ** 1.5
        place(out, lp(g, 500) * 0.35, at)
        at += rng.uniform(16, 26)
    # lantern: a faint hiss that gutters
    hiss = hp(rng.standard_normal(n), 3500) * 0.035 * slow_env(n, 2.0, 0.5, 1.0)
    return out + hiss


# ---------------------------------------------------------------- camp
def camp(sec=32):
    t = t_axis(sec + 3)
    n = len(t)
    roar = lp(rng.standard_normal(n), 260) * slow_env(n, 1.5, 0.5, 1.0) * 0.8
    crack = np.zeros(n)
    k = 0.0
    while k < sec:
        k += rng.exponential(0.18)
        i = int(k * SR)
        if i + 60 < n:
            c = rng.standard_normal(60) * np.exp(-np.arange(60) / 9) * rng.uniform(0.2, 1.0)
            crack[i:i + 60] += c
    crack = bp(crack, 900, 6000) * 0.9
    wind = lp(pink(n), 300) * 0.35 * slow_env(n, 0.2, 0.2, 1)
    return roar + crack + wind


# ---------------------------------------------------------------- hero layers
def oracle(sec=48):
    t = t_axis(sec + 3)
    n = len(t)
    out = np.zeros(n)
    # glass: high partials, each swelling in and out on its own slow cycle
    for f in [880.0, 1318.5, 1760.0, 2217.5]:
        swell = np.clip(np.sin(2 * np.pi * t / rng.uniform(9, 17) + rng.uniform(0, 6)), 0, 1) ** 3
        out += np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) * swell * (0.12 if f < 2000 else 0.06)
    # a choir somewhere far off: a minor chord with slow vibrato, very soft
    choir = np.zeros(n)
    for f in [220.0, 261.6, 329.6, 440.0]:
        vib = 1 + 0.004 * np.sin(2 * np.pi * rng.uniform(4.5, 5.5) * t)
        ph = 2 * np.pi * np.cumsum(f * vib) / SR
        choir += np.sin(ph) + 0.3 * np.sin(2 * ph) + 0.15 * np.sin(3 * ph)
    choir = lp(choir, 1200) * slow_env(n, 0.07, 0.0, 1.0) ** 2 * 0.09
    return room(out + choir, 3.5, 1.6)


def engineer(sec=48):
    t = t_axis(sec + 3)
    n = len(t)
    hum = (np.sin(2 * np.pi * 60 * t) + 0.45 * np.sin(2 * np.pi * 120 * t) + 0.18 * np.sin(2 * np.pi * 180 * t) + 0.08 * np.sin(2 * np.pi * 240 * t))
    hum = lp(hum, 500) * 0.10 * slow_env(n, 0.3, 0.6, 1.0)
    out = hum
    # data chirps: the swarm whispering to itself
    at = 2.0
    while at < sec - 1:
        for b in range(rng.integers(3, 8)):
            dur = rng.uniform(0.02, 0.07)
            tt = t_axis(dur)
            fc = rng.uniform(1800, 4200)
            chirp = np.sin(2 * np.pi * fc * tt + 3 * np.sin(2 * np.pi * rng.uniform(40, 160) * tt)) * np.hanning(len(tt))
            place(out, chirp * 0.07, at + b * rng.uniform(0.05, 0.12))
        at += rng.uniform(3.5, 8)
    # the cursor: a tiny tick, steady as a clock, almost under hearing
    tick = np.sin(2 * np.pi * 3100 * t_axis(0.008)) * np.hanning(int(0.008 * SR))
    k = 0.6
    while k < sec:
        place(out, tick * 0.035, k)
        k += 1.2
    return out


def gunslinger(sec=48):
    t = t_axis(sec + 3)
    n = len(t)
    out = np.zeros(n)
    # wind through a hull: resonant whistles that drift in pitch
    base = rng.standard_normal(n)
    for f0 in [620.0, 1040.0]:
        drift = f0 * (1 + 0.06 * np.sin(2 * np.pi * t / rng.uniform(11, 19)))
        seg = np.zeros(n)
        step = SR // 4
        for i in range(0, n, step):
            fc = float(drift[i])
            seg[i:i + step] = bp(base[i:i + step + 400], fc * 0.97, fc * 1.03, 2)[: len(seg[i:i + step])]
        out += seg * slow_env(n, 0.12, 0.0, 1.0) ** 2 * 1.2
    # the station settling: metal groans
    at = 5.0
    while at < sec - 4:
        dur = rng.uniform(1.2, 2.2)
        tt = t_axis(dur)
        f = np.linspace(rng.uniform(140, 190), rng.uniform(95, 120), len(tt))
        ph = 2 * np.pi * np.cumsum(f) / SR
        g = (np.sin(ph) + 0.6 * np.sin(2.7 * ph) + 0.4 * np.sin(4.1 * ph)) * np.hanning(len(tt))
        place(out, bp(g, 90, 1500) * 0.18, at)
        at += rng.uniform(9, 16)
    # someone at the saloon piano, a long way off and out of tune
    at = rng.uniform(10, 16)
    notes = [196.0, 233.1, 261.6, 293.7, 349.2]
    while at < sec - 3:
        for j in range(rng.integers(2, 4)):
            f = rng.choice(notes) * rng.uniform(0.99, 1.012)
            tt = t_axis(2.2)
            p = sum(np.sin(2 * np.pi * f * h * tt) / h for h in [1, 2, 3, 4]) * np.exp(-tt / 0.7)
            place(out, lp(p, 1600) * 0.05, at + j * 0.45)
        at += rng.uniform(18, 26)
    return room(out, 2.5, 2.2)


if __name__ == "__main__":
    write("town", town(), 0.55)
    write("road", road(), 0.55)
    write("camp", camp(), 0.5)
    write("hero_oracle", oracle(), 0.45)
    write("hero_engineer", engineer(), 0.4)
    write("hero_gunslinger", gunslinger(), 0.45)
