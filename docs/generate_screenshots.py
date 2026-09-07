#!/usr/bin/env python3
"""Gera screenshots e GIF animado do OSD para o README do repositório.

Renderiza o OSD (speaker + onda senoidal) fora da tela usando Cairo — a mesma
função `draw_osd` que o `bin/voxtype-osd` usa em runtime — e monta um GIF
animado com Pillow.

Uso: python3 docs/generate_screenshots.py
"""
import math
import os
import sys

import cairo

ROOT = os.path.join(os.path.dirname(__file__), "..")

# Carrega a função de desenho do OSD sem executar o main() (exec com namespace
# próprio mantém __name__ != "__main__").
_ns = {"__name__": "voxtype_osd_screenshot"}
with open(os.path.join(ROOT, "bin", "voxtype-osd")) as f:
    exec(compile(f.read(), "voxtype-osd", "exec"), _ns)
draw_osd = _ns["draw_osd"]

W, H = 380, 118
OUT = os.path.join(os.path.dirname(__file__), "imgs")


def render_frame(state, level, phase, tick, path):
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, W, H)
    cr = cairo.Context(surface)
    draw_osd(cr, W, H, state, level, phase, tick)
    surface.write_to_png(path)
    print(f"  ✓ {path}")


def main():
    os.makedirs(OUT, exist_ok=True)

    # GIF animado: gravação com volume crescente/decrescente (onda reage à voz)
    levels = [0.0, 0.15, 0.35, 0.6, 0.85, 1.0, 0.8, 0.5, 0.25, 0.1, 0.0]
    frames = []
    for i, lvl in enumerate(levels):
        png = f"/tmp/osd_frame_{i}.png"
        render_frame("recording", lvl, i * 0.5, i, png)
        frames.append(png)

    from PIL import Image

    imgs = [Image.open(f) for f in frames]
    imgs[0].save(
        os.path.join(OUT, "voxtype-osd-recording.gif"),
        save_all=True,
        append_images=imgs[1:],
        duration=140,
        loop=0,
        optimize=True,
    )
    print("  ✓ docs/imgs/voxtype-osd-recording.gif")

    # Estados estáticos
    render_frame("recording", 0.8, 1.2, 3, os.path.join(OUT, "voxtype-osd-recording.png"))
    render_frame("transcribing", 0.5, 0.0, 2, os.path.join(OUT, "voxtype-osd-transcribing.png"))


if __name__ == "__main__":
    main()