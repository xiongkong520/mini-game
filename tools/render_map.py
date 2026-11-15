#!/usr/bin/env python3
"""把字符地图渲染成 PNG：python3 tools/render_map.py"""
from PIL import Image
import os, sys
PAL = {
 '.': (0,0,0,0), 'W': (255,255,255,255), 'K': (20,17,17,255),
 'H': (243,212,138,255), 'h': (222,184,106,255), 'S': (255,228,212,255),
 'E': (255,255,255,255), 'P': (250,150,150,255), 'D': (252,252,250,255),
 'B': (150,120,88,255),
}
src = os.path.join(os.path.dirname(__file__), "..", "assets/art/blocky/bailing_map.txt")
rows = [l.rstrip("\n") for l in open(src, encoding="utf-8") if l.strip() and not l.startswith("#")]
w = max(len(r) for r in rows); h = len(rows)
img = Image.new("RGBA", (w, h), (0,0,0,0)); px = img.load()
for y, row in enumerate(rows):
    for x, ch in enumerate(row):
        if ch in PAL: px[x, y] = PAL[ch]
out = os.path.join(os.path.dirname(src), "bailing_map.png")
img.save(out)
img.resize((w*16, h*16), Image.NEAREST).save(out.replace(".png", "_x16.png"))
print(f"渲染完成 {w}x{h} → {out}")
