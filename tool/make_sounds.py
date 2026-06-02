"""Synthesize copyright-free sound effects (pure stdlib) for Revolver Roulette.
Outputs 16-bit mono PCM WAV files into assets/sounds/.
  - cylinder_spin.wav : metallic ratcheting clicks that slow down (cylinder spin)
  - gunshot.wav       : sharp loud bang with low boom (live round)
  - dry_click.wav     : single hammer click (optional, for trigger pull)
"""
import math, struct, wave, random, os

SR = 44100
random.seed(1234)

def write_wav(path, samples):
    # clamp & convert to 16-bit
    frames = bytearray()
    for s in samples:
        v = max(-1.0, min(1.0, s))
        frames += struct.pack('<h', int(v * 32767))
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(frames))
    print("wrote", path, len(samples), "samples")

def click(dur=0.012, freq=2200, amp=0.9):
    """A short metallic click: high-freq sine burst with fast decay + noise grain."""
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = math.exp(-t * 280.0)
        body = math.sin(2 * math.pi * freq * t)
        ring = 0.4 * math.sin(2 * math.pi * (freq * 1.97) * t)
        grain = 0.5 * (random.random() * 2 - 1) * math.exp(-t * 600.0)
        out.append(amp * env * (body + ring + grain) * 0.6)
    return out

def make_spin():
    """A cylinder spin: a sequence of clicks whose gaps grow (decelerating),
    ending in a soft 'lock' click. ~1.1s."""
    out = []
    # decelerating click train
    gap = 0.028
    t = 0.0
    total = 0.0
    pitch = 2400
    while total < 0.95:
        c = click(dur=0.013, freq=pitch + random.randint(-120, 120), amp=0.85)
        # place click then silence gap
        out.extend(c)
        silence = int(SR * gap)
        out.extend([0.0] * silence)
        total += len(c) / SR + gap
        gap *= 1.12     # decelerate
        pitch *= 0.992  # drop pitch slightly
    # final solid lock click (lower, meatier)
    out.extend([0.0] * int(SR * 0.04))
    lock = click(dur=0.05, freq=900, amp=1.0)
    out.extend(lock)
    # gentle overall fade-in on first 30ms
    fi = int(SR * 0.03)
    for i in range(min(fi, len(out))):
        out[i] *= i / fi
    return out

def make_gunshot():
    """A gunshot: instant attack white-noise crack + low-frequency boom + tail.
    ~0.9s."""
    n = int(SR * 0.9)
    out = []
    for i in range(n):
        t = i / SR
        # crack: broadband noise, very fast decay
        crack_env = math.exp(-t * 55.0)
        crack = (random.random() * 2 - 1) * crack_env
        # boom: low sine sweeping down 120->45 Hz, medium decay
        f = 120 * math.exp(-t * 6.0) + 45
        boom_env = math.exp(-t * 7.5)
        boom = 0.9 * math.sin(2 * math.pi * f * t) * boom_env
        # mid body thump
        body = 0.5 * math.sin(2 * math.pi * 220 * t) * math.exp(-t * 30.0)
        # tail: filtered noise reverberant-ish
        tail = 0.25 * (random.random() * 2 - 1) * math.exp(-t * 4.5)
        s = crack * 1.0 + boom + body + tail
        out.append(s * 0.9)
    # hard attack: ensure first sample is full
    return out

def make_dry_click():
    return click(dur=0.06, freq=1400, amp=0.9) + [0.0] * int(SR * 0.04)

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
outdir = os.path.join(here, "assets", "sounds")
os.makedirs(outdir, exist_ok=True)
write_wav(os.path.join(outdir, "cylinder_spin.wav"), make_spin())
write_wav(os.path.join(outdir, "gunshot.wav"), make_gunshot())
write_wav(os.path.join(outdir, "dry_click.wav"), make_dry_click())
print("done")
