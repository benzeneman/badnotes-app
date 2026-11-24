#!/usr/bin/env python3
"""Draws the BadNotes mark (a loose line of handwriting ending in a yellow
ink dot) into every launcher and splash size Android needs.

Run from the repository root: python3 assets/icon/generate_icons.py
(Needs Pillow. The icons workflow runs it and keeps the pictures.)
"""
from PIL import Image, ImageDraw

PAPER = (255, 252, 238, 255)
YELLOW = (255, 224, 102, 255)
PURPLE_TOP = (122, 98, 219)
PURPLE_BOTTOM = (74, 54, 153)
BACKGROUND = (94, 70, 196, 255)  # the flat colour the adaptive icon sits on
RES = "android/app/src/main/res"
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
SUPERSAMPLE = 4

# the line, in a 100 x 100 square: cubic curves, each (start, c1, c2, end)
CURVES = [
    ((15, 66), (21, 34), (36, 29), (40, 50)),
    ((40, 50), (44, 71), (52, 84), (62, 52)),
    ((62, 52), (72, 20), (74, 28), (84, 42)),
]
DOT = (84, 42, 7.5)
STROKE = 10


def _along(curve, steps):
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = curve
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        yield (
            u**3 * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t**3 * x3,
            u**3 * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t**3 * y3,
        )


def draw_mark(draw, size, inset, line, dot):
    """The line and its dot, [inset] pixels in from each side."""
    scale = (size - 2 * inset) / 100

    def at(v):
        return inset + v * scale

    r = STROKE / 2 * scale
    for curve in CURVES:
        for x, y in _along(curve, 160):
            draw.ellipse([at(x) - r, at(y) - r, at(x) + r, at(y) + r], fill=line)
    cx, cy, cr = DOT
    draw.ellipse(
        [at(cx - cr), at(cy - cr), at(cx + cr), at(cy + cr)], fill=dot
    )


def gradient(px):
    image = Image.new("RGBA", (px, px))
    pixels = image.load()
    for y in range(px):
        for x in range(px):
            t = (x + y) / (2 * px - 2)
            pixels[x, y] = tuple(
                round(a + (b - a) * t) for a, b in zip(PURPLE_TOP, PURPLE_BOTTOM)
            ) + (255,)
    return image


def legacy(px):
    """A full-square launcher picture for phones without adaptive icons."""
    big = px * SUPERSAMPLE
    image = gradient(big)
    draw_mark(ImageDraw.Draw(image), big, big * 0.12, PAPER, YELLOW)
    return image.resize((px, px), Image.LANCZOS)


def foreground(px, line, dot, inset):
    """The mark alone on transparent, for the adaptive icon's top layer."""
    big = px * SUPERSAMPLE
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw_mark(ImageDraw.Draw(image), big, big * inset, line, dot)
    return image.resize((px, px), Image.LANCZOS)


def main():
    for name, scale in DENSITIES.items():
        folder = f"{RES}/mipmap-{name}"
        # 108dp canvas: the system crops it, so the mark stays in the middle
        fg = int(108 * scale)
        foreground(fg, PAPER, YELLOW, 0.2).save(f"{folder}/ic_launcher_foreground.png")
        foreground(fg, (255, 255, 255, 255), (255, 255, 255, 255), 0.2).save(
            f"{folder}/ic_launcher_monochrome.png"
        )
        legacy(int(48 * scale)).save(f"{folder}/ic_launcher.png")

    foreground(288, PAPER, YELLOW, 0.1).save(f"{RES}/drawable-xxxhdpi/splash_logo.png")
    legacy(1024).save("assets/icon/icon.png")


if __name__ == "__main__":
    main()
