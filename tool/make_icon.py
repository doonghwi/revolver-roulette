"""Generate a copyright-free app icon: a 6-shot cylinder, one chamber loaded
(red/brass), on a dark western background. 1024x1024 PNG."""
import math, os
from PIL import Image, ImageDraw

S = 1024
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# rounded dark background
bg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
bd = ImageDraw.Draw(bg)
bd.rounded_rectangle([0, 0, S, S], radius=180, fill=(26, 20, 16, 255))
# subtle vignette ring
for i in range(60):
    a = int(40 * (i / 60))
    bd.ellipse([i*2, i*2, S-i*2, S-i*2], outline=(60, 40, 24, a))
img = Image.alpha_composite(img, bg)
d = ImageDraw.Draw(img)

cx, cy = S/2, S/2
R = 360  # cylinder radius

# drum body (radial-ish shading via concentric circles)
for i in range(R, 0, -2):
    f = i / R
    c = (int(150 - 110*f), int(155 - 112*f), int(165 - 118*f), 255)
    d.ellipse([cx-i, cy-i, cx+i, cy+i], fill=c)
# outer rim
d.ellipse([cx-R, cy-R, cx+R, cy+R], outline=(20, 21, 26, 255), width=12)

# 6 chambers
hole_r = 200
ch_r = 78
live = 0  # which chamber is loaded
for k in range(6):
    a = (k/6)*2*math.pi - math.pi/2
    hx, hy = cx + math.cos(a)*hole_r, cy + math.sin(a)*hole_r
    if k == live:
        # brass loaded round with red primer
        d.ellipse([hx-ch_r, hy-ch_r, hx+ch_r, hy+ch_r], fill=(217, 178, 74, 255))
        d.ellipse([hx-ch_r, hy-ch_r, hx+ch_r, hy+ch_r], outline=(120, 90, 30, 255), width=8)
        pr = ch_r*0.42
        d.ellipse([hx-pr, hy-pr, hx+pr, hy+pr], fill=(192, 57, 43, 255))
    else:
        d.ellipse([hx-ch_r, hy-ch_r, hx+ch_r, hy+ch_r], fill=(16, 16, 19, 255))
        d.ellipse([hx-ch_r, hy-ch_r, hx+ch_r, hy+ch_r], outline=(150, 160, 170, 160), width=7)

# center pin
d.ellipse([cx-60, cy-60, cx+60, cy+60], fill=(40, 42, 47, 255))
d.ellipse([cx-60, cy-60, cx+60, cy+60], outline=(20, 21, 26, 255), width=8)
d.ellipse([cx-22, cy-22, cx+22, cy+22], fill=(150, 160, 170, 255))

here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
outdir = os.path.join(here, "assets", "icon")
os.makedirs(outdir, exist_ok=True)
img.save(os.path.join(outdir, "icon.png"))
print("wrote", os.path.join(outdir, "icon.png"))
