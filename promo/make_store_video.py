#!/usr/bin/env python3
"""App Preview：15–30 秒，H.264 + AAC 立体声，30fps。"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

import imageio_ffmpeg
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent

TITLE = {
    "zh": ("课酬记", "下课记一笔，对账不扯皮", "10 秒记课时 · 课包可追溯 · 一键出账单"),
    "en": ("TutorLedger", "Log a lesson. Settle pay.", "10-second logs · package history · parent-ready bills"),
}
END = {
    "zh": ("课酬记", "免费 · 离线 · 无需登录", "App Store 搜「课酬记」"),
    "en": ("TutorLedger", "Free. Offline. No sign-in.", "Search TutorLedger on the App Store"),
}
SCENES = ["01-log.png", "03-ledger.png", "04-package.png", "05-bills.png", "06-stats.png"]


def font(size: int, weight: str = "semibold", english: bool = False) -> ImageFont.FreeTypeFont:
    if english:
        path, index = "/System/Library/Fonts/Avenir Next.ttc", 3 if weight in {"semibold", "bold"} else 0
    else:
        path, index = "/System/Library/Fonts/Hiragino Sans GB.ttc", 1 if weight in {"semibold", "bold"} else 0
    try:
        return ImageFont.truetype(path, size=size, index=index)
    except OSError:
        return ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", size=size)


def card(size: tuple[int, int], brand: str, line: str, foot: str, english: bool) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        draw.line([(0, y), (w, y)], fill=(
            int(46 + (210 - 46) * t),
            int(150 + (240 - 150) * t),
            int(148 + (236 - 148) * t),
        ))
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((-w * 0.15, -h * 0.08, w * 0.7, h * 0.32), fill=(255, 255, 255, 38))
    canvas = Image.alpha_composite(img.convert("RGBA"), overlay)
    draw = ImageDraw.Draw(canvas)
    scale = w / 886
    bf = font(int(72 * scale), "bold", english)
    lf = font(int(36 * scale), "semibold", english)
    ff = font(int(24 * scale), "regular", english)
    ink = (18, 56, 54)
    def centered(text, fnt, y, fill):
        tw = draw.textlength(text, font=fnt)
        draw.text(((w - tw) / 2, y), text, font=fnt, fill=fill)
    centered(brand, bf, int(h * 0.36), ink)
    # wrap line
    max_w = w - int(80 * scale)
    words = line if not english else line
    # simple wrap by characters for both
    lines, cur = [], ""
    for ch in words:
        trial = cur + ch
        if draw.textlength(trial, font=lf) <= max_w:
            cur = trial
        else:
            lines.append(cur)
            cur = ch
    if cur:
        lines.append(cur)
    y = int(h * 0.48)
    for ln in lines:
        centered(ln, lf, y, (32, 92, 88))
        y += int(48 * scale)
    centered(foot, ff, int(h * 0.72), (40, 110, 106))
    return canvas.convert("RGB")


def stitch(title: Path, slides: list[Path], end: Path, out: Path, width: int, height: int) -> None:
    ff = imageio_ffmpeg.get_ffmpeg_exe()
    scale = (
        f"scale={width}:{height}:force_original_aspect_ratio=decrease,"
        f"pad={width}:{height}:(ow-iw)/2:(oh-ih)/2,fps=30,format=yuv420p,setsar=1"
    )
    cmd = [ff, "-y", "-loop", "1", "-t", "2.4", "-i", str(title)]
    for slide in slides:
        cmd += ["-loop", "1", "-t", "3.2", "-i", str(slide)]
    cmd += ["-loop", "1", "-t", "2.8", "-i", str(end)]
    cmd += ["-f", "lavfi", "-t", "30", "-i", "anullsrc=channel_layout=stereo:sample_rate=44100"]
    n = 2 + len(slides)
    parts = "".join(f"[{i}:v]{scale}[v{i}];" for i in range(n))
    concat_in = "".join(f"[v{i}]" for i in range(n))
    cmd += [
        "-filter_complex", f"{parts}{concat_in}concat=n={n}:v=1:a=0[v]",
        "-map", "[v]",
        "-map", f"{n}:a",
        "-c:v", "libx264",
        "-profile:v", "high",
        "-level", "4.0",
        "-b:v", "10M",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "256k",
        "-ac", "2",
        "-ar", "44100",
        "-shortest",
        "-movflags", "+faststart",
        str(out),
    ]
    subprocess.check_call(cmd)
    print(f"wrote {out} ({out.stat().st_size} bytes) {width}x{height}")


def export(device: str, lang: str) -> None:
    english = lang == "en"
    if device == "ipad":
        store = ROOT / f"store-ipad-{lang}"
        dest = ROOT / "video" / "ipad" / lang
        preview = (1200, 1600)
        card_size = (1200, 1600)
    else:
        store = ROOT / f"store-iphone-{lang}"
        dest = ROOT / "video" / "iphone" / lang
        preview = (886, 1920)
        card_size = (886, 1920)

    dest.mkdir(parents=True, exist_ok=True)
    title_copy = TITLE[lang]
    end_copy = END[lang]
    title = dest / "title.png"
    end = dest / "end.png"
    card(card_size, *title_copy, english).save(title)
    card(card_size, *end_copy, english).save(end)

    slides = []
    for name in SCENES:
        src = store / name
        if not src.exists():
            raise SystemExit(f"missing {src}")
        slides.append(src)

    stitch(title, slides, end, dest / "TutorLedger-preview.mp4", *preview)


def main() -> None:
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"
    devices = ["iphone", "ipad"] if arg == "all" else [arg]
    for device in devices:
        export(device, "zh")
        export(device, "en")


if __name__ == "__main__":
    main()
