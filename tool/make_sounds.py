"""High-effort, copyright-free sound design for Revolver Roulette.

Synthesizes realistic effects with numpy + scipy (no sampled/copyrighted audio):
  - cylinder_spin.wav : a hand-spun revolver cylinder — metallic ratchet clicks
                        that accelerate-then-decelerate, over a low drum ring,
                        ending in a heavy "lock" clunk. Light room reverb.
  - gunshot.wav       : supersonic crack + low muzzle blast + mechanical action
                        + reverb tail, soft-clipped for punch.
  - hammer_cock.wav   : a single firm single-action hammer cock click.
  - dry_click.wav     : a light mechanism tick (used for trigger feedback).

Everything is procedural and deterministic (fixed seed) so it is reproducible.
"""
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
import wave, struct, os

SR = 44100
rng = np.random.default_rng(7)

# ----------------------------- helpers --------------------------------------

def _sos(kind, cutoff, order=4):
    return butter(order, cutoff, btype=kind, fs=SR, output='sos')

def lp(x, fc, order=4):  return sosfilt(_sos('low', fc, order), x)
def hp(x, fc, order=4):  return sosfilt(_sos('high', fc, order), x)
def bp(x, lo, hi, order=4): return sosfilt(_sos('band', [lo, hi], order), x)

def noise(n):
    return rng.standard_normal(n)

def env_exp(n, rate):
    """Exponential decay envelope of length n."""
    t = np.arange(n) / SR
    return np.exp(-t * rate)

def env_ar(n, attack, release):
    """Attack-release envelope (seconds)."""
    e = np.ones(n)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] = np.linspace(1, 0, r)
    return e

def metallic_ping(n, freqs, decay, amp=1.0):
    """Sum of inharmonic decaying sines -> a metallic 'ting'."""
    t = np.arange(n) / SR
    out = np.zeros(n)
    for f, a, d in freqs:
        out += a * np.sin(2 * np.pi * f * t) * np.exp(-t * d)
    return out * amp * env_exp(n, decay) * 0 + out * amp  # keep partials' own decay

def schroeder_reverb(x, decay=0.55, mix=0.28, room=1.0):
    """Small Schroeder reverb: 4 comb filters + 2 allpass. Returns wet/dry mix."""
    def comb(sig, delay_s, g):
        d = max(1, int(delay_s * room * SR))
        y = np.zeros(len(sig) + d)
        y[:len(sig)] = sig
        # feedback comb
        for i in range(d, len(y)):
            y[i] += g * y[i - d]
        return y[:len(sig)]

    def allpass(sig, delay_s, g):
        d = max(1, int(delay_s * SR))
        y = np.zeros(len(sig) + d)
        buf = np.concatenate([sig, np.zeros(d)])
        for i in range(d, len(buf)):
            y[i] = -g * buf[i] + buf[i - d] + g * y[i - d]
        return y[:len(sig)]

    combs = [(0.0297, 0.78), (0.0371, 0.74), (0.0411, 0.71), (0.0437, 0.68)]
    wet = np.zeros_like(x)
    for ds, g in combs:
        wet += comb(x, ds, g * decay)
    wet /= len(combs)
    wet = allpass(wet, 0.005, 0.7)
    wet = allpass(wet, 0.0017, 0.7)
    wet = lp(wet, 7000)  # darker tail
    return (1 - mix) * x + mix * wet

def normalize(x, peak=0.95):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak

def softclip(x, drive=1.6):
    return np.tanh(x * drive)

def write_wav(path, x):
    x = np.clip(x, -1.0, 1.0)
    pcm = (x * 32767).astype('<i2')
    with wave.open(path, 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"wrote {os.path.basename(path)}  {len(x)/SR:.2f}s  peak={np.max(np.abs(x)):.2f}")

# --------------------------- one ratchet click ------------------------------

def ratchet_click(pitch=1.0, amp=1.0):
    """A single metallic ratchet tick: a short filtered-noise transient plus a
    bright inharmonic metallic ring. ~16 ms."""
    n = int(SR * 0.018)
    t = np.arange(n) / SR
    # transient: band-passed noise, extremely fast decay
    trans = bp(noise(n), 1800 * pitch, 6500 * pitch) * np.exp(-t * 520)
    # metallic ring: a few inharmonic partials
    base = 2400 * pitch
    ring = (1.00 * np.sin(2*np.pi*base*t)        * np.exp(-t*260) +
            0.55 * np.sin(2*np.pi*base*2.76*t)   * np.exp(-t*340) +
            0.32 * np.sin(2*np.pi*base*5.40*t)   * np.exp(-t*430))
    click = 0.7 * trans + 0.5 * ring
    return click * amp

# --------------------------- cylinder spin ----------------------------------

def make_spin():
    dur = 1.45
    total = int(SR * dur)
    out = np.zeros(total)

    # 1) low metal drum ring under the whole spin (the cylinder mass)
    t = np.arange(total) / SR
    drum = (0.18 * np.sin(2*np.pi*140*t) * np.exp(-t*3.0) +
            0.10 * np.sin(2*np.pi*220*t) * np.exp(-t*4.0))
    drum += 0.04 * lp(noise(total), 400) * np.exp(-t*2.2)
    out += drum

    # 2) ratchet click train: accelerate briefly, then decelerate (hand spin)
    times = []
    gap = 0.045          # initial gap
    tcur = 0.02
    phase = 0
    while tcur < 1.02:
        times.append(tcur)
        # accelerate for first few, then decelerate
        if phase < 4:
            gap *= 0.86
        else:
            gap *= 1.13
        gap = min(max(gap, 0.022), 0.16)
        tcur += gap
        phase += 1

    for i, tc in enumerate(times):
        # pitch drops slightly as it slows; clicks get a touch louder near lock
        frac = i / len(times)
        pitch = 1.12 - 0.30 * frac + rng.uniform(-0.03, 0.03)
        amp = 0.55 + 0.35 * frac
        click = ratchet_click(pitch=pitch, amp=amp)
        s = int(tc * SR)
        e = min(total, s + len(click))
        out[s:e] += click[:e - s]

    # 3) heavy final "lock" clunk — lower, meatier, with a short ring
    lock_at = int((times[-1] + 0.05) * SR)
    ln = int(SR * 0.12)
    lt = np.arange(ln) / SR
    lock = (bp(noise(ln), 300, 2200) * np.exp(-lt * 90) * 0.9 +
            0.6 * np.sin(2*np.pi*620*lt) * np.exp(-lt*70) +
            0.4 * np.sin(2*np.pi*300*lt) * np.exp(-lt*55))
    e = min(total, lock_at + ln)
    out[lock_at:e] += lock[:e - lock_at]

    out = schroeder_reverb(out, decay=0.45, mix=0.18, room=0.7)
    # gentle fade in/out
    out *= env_ar(total, 0.004, 0.05)
    return normalize(out, 0.92)

# ------------------------------- gunshot ------------------------------------

def make_gunshot():
    dur = 1.05
    n = int(SR * dur)
    t = np.arange(n) / SR
    out = np.zeros(n)

    # 1) supersonic crack: full-band noise, near-instant decay (the "snap")
    crack = noise(n) * np.exp(-t * 130)
    crack = hp(crack, 1200) * 1.0
    out += 1.0 * crack

    # 2) muzzle blast: low/mid filtered-noise body + descending sine boom
    blast_noise = lp(noise(n), 900) * np.exp(-t * 26)
    boom_f = 60 + 90 * np.exp(-t * 30)            # 150 -> 60 Hz sweep
    boom = np.sin(2 * np.pi * np.cumsum(boom_f) / SR) * np.exp(-t * 16)
    out += 0.9 * blast_noise + 0.85 * boom

    # 3) mid "punch" body for weight
    out += 0.5 * np.sin(2*np.pi*180*t) * np.exp(-t * 40)
    out += 0.3 * np.sin(2*np.pi*90*t)  * np.exp(-t * 22)

    # 4) a touch of mechanical grit right at the start
    out[:int(SR*0.03)] += 0.4 * bp(noise(int(SR*0.03)), 2000, 7000) * \
        np.exp(-np.arange(int(SR*0.03))/SR * 200)

    # punch + loudness, then reverb tail (outdoor-ish)
    out = softclip(out, drive=1.5)
    out = schroeder_reverb(out, decay=0.6, mix=0.30, room=1.4)
    # extra long, dark tail
    tail = lp(noise(n), 1800) * np.exp(-t * 5.5) * 0.12
    out += tail
    out *= env_ar(n, 0.0004, 0.08)
    return normalize(out, 0.97)

# ---------------------------- hammer / clicks -------------------------------

def make_hammer_cock():
    n = int(SR * 0.09)
    t = np.arange(n) / SR
    # two-stage: sear slip then lock
    a = bp(noise(n), 800, 4500) * np.exp(-t * 120) * 0.9
    b = np.zeros(n); s = int(SR*0.045)
    bt = np.arange(n-s)/SR
    b[s:] = bp(noise(n-s), 400, 2600) * np.exp(-bt*150) * 0.8 + \
            0.4*np.sin(2*np.pi*520*bt)*np.exp(-bt*120)
    out = a + b
    out = schroeder_reverb(out, decay=0.3, mix=0.12, room=0.5)
    return normalize(out, 0.85)

def make_dry_click():
    n = int(SR * 0.05)
    t = np.arange(n) / SR
    out = bp(noise(n), 1500, 6000) * np.exp(-t * 240) * 0.9
    out += 0.4 * np.sin(2*np.pi*1800*t) * np.exp(-t*200)
    return normalize(out, 0.7)

# ---------------------------------- main ------------------------------------

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
outdir = os.path.join(here, "assets", "sounds")
os.makedirs(outdir, exist_ok=True)
write_wav(os.path.join(outdir, "cylinder_spin.wav"), make_spin())
write_wav(os.path.join(outdir, "gunshot.wav"), make_gunshot())
write_wav(os.path.join(outdir, "hammer_cock.wav"), make_hammer_cock())
write_wav(os.path.join(outdir, "dry_click.wav"), make_dry_click())
print("done")
