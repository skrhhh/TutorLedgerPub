#!/usr/bin/env python3
"""App Store 宣传图：iPhone 6.9\" 1320×2868 · iPad 13\" 2064×2752。"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent

ZH_FRAMES = [
    {
        "src": "home.png",
        "out": "01-log.png",
        "kicker": "个人辅导老师的口袋账本",
        "title": "下课记一笔\n对账不扯皮",
        "sub": "10 秒入账，单价自动带出",
    },
    {
        "src": "students.png",
        "out": "02-billing.png",
        "kicker": "先付 · 月结 · 现结",
        "title": "三种计费\n各走各的账",
        "sub": "按学生绑规则，记完自动分类",
    },
    {
        "src": "lessons.png",
        "out": "03-ledger.png",
        "kicker": "每一节都留得住",
        "title": "本月课时流水\n日期、时长、单价",
        "sub": "谁上了、收了没有，一眼能对",
    },
    {
        "src": "student.png",
        "out": "04-package.png",
        "kicker": "家长问还剩几节",
        "title": "课包流水\n打开就能答",
        "sub": "购课、扣课、请假返还按时间排列",
    },
    {
        "src": "bills.png",
        "out": "05-bills.png",
        "kicker": "发给家长之前",
        "title": "待出账按学生汇总\n一键生成账单",
        "sub": "待发送 / 已发送 / 已收款，状态清楚",
    },
    {
        "src": "stats.png",
        "out": "06-stats.png",
        "kicker": "完全离线 · 无需登录",
        "title": "按月看课时\n和已收",
        "sub": "数据在本机，换机前记得导出",
    },
]

EN_FRAMES = [
    {
        "src": "home.png",
        "out": "01-log.png",
        "kicker": "A pocket ledger for tutors",
        "title": "Log a lesson.\nSettle pay.",
        "sub": "In 10 seconds. Rate filled in.",
    },
    {
        "src": "students.png",
        "out": "02-billing.png",
        "kicker": "Prepaid · Monthly · Per session",
        "title": "Three billing modes.\nOne ledger.",
        "sub": "Rules live on the student, not your memory.",
    },
    {
        "src": "lessons.png",
        "out": "03-ledger.png",
        "kicker": "Every lesson stays dated",
        "title": "A ledger you\ncan explain",
        "sub": "Who, how long, what rate, paid or not.",
    },
    {
        "src": "student.png",
        "out": "04-package.png",
        "kicker": "“How many left?”",
        "title": "Package history\nin one tap",
        "sub": "Purchases, deductions, and void refunds.",
    },
    {
        "src": "bills.png",
        "out": "05-bills.png",
        "kicker": "Before you text parents",
        "title": "Group pending hours.\nGenerate a bill.",
        "sub": "Draft, sent, paid — status you can show.",
    },
    {
        "src": "stats.png",
        "out": "06-stats.png",
        "kicker": "Offline. No sign-in.",
        "title": "Monthly hours\nand received pay",
        "sub": "Your data stays on your device.",
    },
]


def font(size: int, weight: str = "semibold", english: bool = False) -> ImageFont.FreeTypeFont:
    if english:
        candidates = [
            ("/System/Library/Fonts/Avenir Next.ttc", 3 if weight in {"semibold", "bold"} else 0),
            ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 0),
        ]
    else:
        candidates = [
            ("/System/Library/Fonts/Hiragino Sans GB.ttc", 1 if weight in {"semibold", "bold"} else 0),
            ("/System/Library/Fonts/STHeiti Medium.ttc", 0),
        ]
    for path, index in candidates:
        try:
            return ImageFont.truetype(path, size=size, index=index)
        except OSError:
            continue
    return ImageFont.load_default()


def gradient(size: tuple[int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(186 + (244 - 186) * t)
        g = int(232 + (252 - 232) * t)
        b = int(236 + (248 - 236) * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((-int(w * 0.2), -int(h * 0.12), int(w * 0.62), int(h * 0.28)), fill=(72, 196, 192, 48))
    od.ellipse((int(w * 0.55), int(h * 0.72), int(w * 1.2), int(h * 1.08)), fill=(255, 176, 112, 36))
    return Image.alpha_composite(img.convert("RGBA"), overlay)


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont, max_w: int) -> list[str]:
    lines: list[str] = []
    for raw in text.split("\n"):
        cur = ""
        for ch in raw:
            trial = cur + ch
            if draw.textlength(trial, font=fnt) <= max_w:
                cur = trial
            else:
                if cur:
                    lines.append(cur)
                cur = ch
        if cur:
            lines.append(cur)
    return lines


def text_block(draw, text, xy, fnt, fill, max_w, gap=0) -> int:
    x, y = xy
    ascent, descent = fnt.getmetrics()
    line_h = ascent + descent + gap
    for line in wrap(draw, text, fnt, max_w):
        draw.text((x, y), line, font=fnt, fill=fill)
        y += line_h
    return y


def rounded(im: Image.Image, radius: int) -> Image.Image:
    im = im.convert("RGBA")
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0], im.size[1]), radius, fill=255)
    im.putalpha(mask)
    return im


def shadow(im: Image.Image, radius: int = 28, opacity: int = 55) -> Image.Image:
    pad = radius * 3
    canvas = Image.new("RGBA", (im.size[0] + pad * 2, im.size[1] + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", im.size, (18, 48, 46, opacity))
    canvas.paste(sh, (pad, pad + 16), sh)
    canvas = canvas.filter(ImageFilter.GaussianBlur(radius))
    canvas.paste(im, (pad, pad), im)
    return canvas


def compose(frame: dict, src: Path, size: tuple[int, int], english: bool) -> Image.Image:
    w, h = size
    canvas = gradient(size)
    draw = ImageDraw.Draw(canvas)
    scale = w / 1320
    ink = (24, 70, 68)
    teal = (32, 140, 136)
    muted = (74, 112, 110)
    pad = int(72 * scale)

    kicker_size = int(28 * scale) if english else int(30 * scale)
    title_size = int(64 * scale) if english else int(70 * scale)
    sub_size = int(28 * scale) if english else int(30 * scale)
    if w > 1800:
        kicker_size = int(36 * scale)
        title_size = int(58 * scale) if english else int(62 * scale)
        sub_size = int(26 * scale)
        pad = int(88 * scale)

    y = int(88 * scale) if w < 1800 else int(72 * scale)
    y = text_block(draw, frame["kicker"], (pad, y), font(kicker_size, "medium", english), teal, w - pad * 2)
    y = text_block(
        draw,
        frame["title"],
        (pad, y + int(10 * scale)),
        font(title_size, "bold", english),
        ink,
        w - pad * 2,
        gap=int(8 * scale),
    )
    y = text_block(
        draw,
        frame["sub"],
        (pad, y + int(14 * scale)),
        font(sub_size, "regular", english),
        muted,
        w - pad * 2,
    )

    footer_h = int(70 * scale)
    header_bottom = y + int(28 * scale)
    avail_h = h - header_bottom - footer_h - int(20 * scale)
    avail_w = int(w * 0.86)

    shot = Image.open(src).convert("RGBA")
    ratio = min(avail_w / shot.width, avail_h / shot.height)
    shot = shot.resize((int(shot.width * ratio), int(shot.height * ratio)), Image.Resampling.LANCZOS)
    shot = rounded(shot, int(54 * scale if w < 1800 else 42 * scale))
    framed = shadow(shot, radius=int(22 * scale), opacity=50)
    fx = (w - framed.width) // 2
    fy = header_bottom - int(18 * scale)
    if fy + framed.height > h - footer_h:
        fy = h - footer_h - framed.height
    canvas.alpha_composite(framed, (fx, max(header_bottom - int(8 * scale), fy)))

    brand = "TutorLedger" if english else "课酬记"
    bf = font(int(26 * scale), "semibold", english)
    draw = ImageDraw.Draw(canvas)
    bw = draw.textlength(brand, font=bf)
    draw.text(((w - bw) / 2, h - int(52 * scale)), brand, font=bf, fill=teal)
    return canvas.convert("RGB")


def export(device: str) -> None:
    if device == "ipad":
        size = (2064, 2752)
        raw_root = ROOT / "raw" / "ipad"
        out_zh = ROOT / "store-ipad-zh"
        out_en = ROOT / "store-ipad-en"
    else:
        size = (1320, 2868)
        raw_root = ROOT / "raw" / "iphone"
        out_zh = ROOT / "store-iphone-zh"
        out_en = ROOT / "store-iphone-en"

    out_zh.mkdir(parents=True, exist_ok=True)
    out_en.mkdir(parents=True, exist_ok=True)
    for frame in ZH_FRAMES:
        src = raw_root / "zh" / frame["src"]
        if not src.exists():
            print(f"skip {src}")
            continue
        compose(frame, src, size, False).save(out_zh / frame["out"], optimize=True)
        print(f"{device} zh {frame['out']} {size[0]}x{size[1]}")
    for frame in EN_FRAMES:
        src = raw_root / "en" / frame["src"]
        if not src.exists():
            print(f"skip {src}")
            continue
        compose(frame, src, size, True).save(out_en / frame["out"], optimize=True)
        print(f"{device} en {frame['out']} {size[0]}x{size[1]}")


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"
    if arg == "all":
        export("iphone")
        export("ipad")
    else:
        export(arg)
