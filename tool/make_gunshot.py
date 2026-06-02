"""Make the gunshot heavier & scarier: layer the real mixkit recording with a
synthesized sub-bass boom + low-shelf boost + soft-clip punch + a short dark
reverb tail. Output assets/sounds/gunshot.wav (copyright: mixkit recording under
Mixkit License + original synthesized layers)."""
import os
import numpy as np
import soundfile as sf
from scipy.signal import butter, sosfilt

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# original mixkit recording kept under the audit folder
src = r'C:\dev\dailyapp\_audit\sfx\game_gunshot.mp3'
x, sr = sf.read(src)
if x.ndim > 1:
    x = x.mean(1)
x = x / (np.max(np.abs(x)) + 1e-9)
n = len(x)
t = np.arange(n) / sr

def lp(sig, fc):
    return sosfilt(butter(2, fc, btype='low', fs=sr, output='sos'), sig)

# 1) INSTANT impact transient at 0 ms — a full-scale broadband burst so the
#    sound hits like a "팡!" the very first millisecond (startle).
imp_n = int(sr * 0.035)
imp = np.random.default_rng(5).standard_normal(imp_n)
imp *= np.exp(-np.arange(imp_n) / sr * 140)        # very fast decay
imp = imp - lp(imp, 450) * 0.6                      # keep the snap bright
imp[:int(sr * 0.001)] = 1.0                          # 1 ms full-scale spike
crack = np.zeros(n)
crack[:imp_n] = imp

# 2) sub-bass boom: fast attack so its energy lands early, not at 125 ms
boom_f = 38 + 110 * np.exp(-t * 16)
boom = np.sin(2 * np.pi * np.cumsum(boom_f) / sr) * np.exp(-t * 10)

# 3) deep low-shelf body for weight
body = lp(x, 200) * 0.8

y = 0.8 * x + 0.7 * boom + 0.55 * body + 1.6 * crack

# 4) aggressive soft-clip for a loud, punchy, menacing blast
y = np.tanh(y * 2.4)

# 5) short dark reverb tail (lighter, so the loud body dominates -> bigger bang)
rev = np.zeros(len(y) + int(sr * 0.3))
rev[:len(y)] = y
for d, g in [(0.03, 0.28), (0.06, 0.18), (0.1, 0.11), (0.16, 0.06)]:
    k = int(d * sr)
    rev[k:k + len(y)] += lp(y, 2500) * g
y = rev

# loudness: light limiter (lift the body without raising the peak), then normalize
y = np.tanh(y * 1.25)
y = y / (np.max(np.abs(y)) + 1e-9) * 0.99
out = os.path.join(here, 'assets', 'sounds', 'gunshot.wav')
sf.write(out, y.astype(np.float32), sr)
print(f"wrote {out}  {len(y)/sr:.2f}s  peak={np.max(np.abs(y)):.2f}")
