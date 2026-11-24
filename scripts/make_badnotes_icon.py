"""Draws the BadNotes launcher icon: white notebook with blue spine and a
handwritten squiggle on a blue background. Writes Android mipmaps."""
import sys, math
from PIL import Image, ImageDraw

RES = sys.argv[1]  # android/app/src/main/res
BLUE = (47, 124, 246)
BLUE_DARK = (28, 86, 196)
INK = (32, 48, 90)
S = 1728  # 4x of 432 (xxxhdpi foreground) for antialiasing

def notebook(mono=False):
    """Foreground on a 108dp canvas; art kept inside the 66dp safe zone."""
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    u = S / 108  # px per dp
    x0, y0, x1, y1 = 34 * u, 27 * u, 76 * u, 81 * u
    white = (255, 255, 255, 255)
    if not mono:  # soft shadow
        d.rounded_rectangle((x0 + 1.5*u, y0 + 2*u, x1 + 1.5*u, y1 + 2*u), 5*u, fill=(0, 0, 0, 50))
    d.rounded_rectangle((x0, y0, x1, y1), 5 * u, fill=white)
    spine = white if mono else BLUE_DARK
    if mono:  # cut the spine out so the shape still reads as a notebook
        d.rectangle((x0 + 5*u, y0, x0 + 6.5*u, y1), fill=(0, 0, 0, 0))
    else:
        d.rounded_rectangle((x0, y0, x0 + 8 * u, y1), 5 * u, fill=spine)
        d.rectangle((x0 + 4 * u, y0, x0 + 8 * u, y1), fill=spine)
    # handwritten "b" squiggle
    ink = (0, 0, 0, 0) if mono else INK + (255,)
    w = int(3.2 * u)
    # stem
    d.line((47 * u, 37 * u, 47 * u, 69 * u), fill=ink, width=w)
    d.ellipse((47*u - w/2, 37*u - w/2, 47*u + w/2, 37*u + w/2), fill=ink)
    # bowl: circle touching the stem
    r = 7.5
    d.ellipse(((47 - w/u/2) * u, (69 - 2*r + w/u/2) * u - 0, (47 + 2*r - w/u/2) * u, (69 + w/u/2) * u), outline=ink, width=w)
    # ruled lines
    line = (0, 0, 0, 0) if mono else (BLUE[0], BLUE[1], BLUE[2], 90)
    for y in (46, 53, 60, 67, 74):
        d.line((64 * u, y * u, 71 * u, y * u), fill=line, width=int(1.2 * u))
    return im

def legacy(fg):
    """Pre-Android-8 icon: blue rounded square + foreground, 48dp."""
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    u = S / 108
    d.rounded_rectangle((9*u, 9*u, 99*u, 99*u), 20 * u, fill=BLUE + (255,))
    im.alpha_composite(fg)
    return im.crop((int(9*u), int(9*u), int(99*u), int(99*u)))

fg, mono = notebook(), notebook(mono=True)
leg = legacy(fg)
for name, scale in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}.items():
    n = int(108 * scale)
    fg.resize((n, n), Image.LANCZOS).save(f"{RES}/mipmap-{name}/ic_launcher_foreground.png")
    mono.resize((n, n), Image.LANCZOS).save(f"{RES}/mipmap-{name}/ic_launcher_monochrome.png")
    m = int(48 * scale)
    leg.resize((m, m), Image.LANCZOS).save(f"{RES}/mipmap-{name}/ic_launcher.png")
# preview for humans
prev = Image.new("RGBA", (S, S), BLUE + (255,)); prev.alpha_composite(fg)
prev.resize((512, 512), Image.LANCZOS).save(sys.argv[2])
