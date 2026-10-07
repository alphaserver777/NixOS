"""Непрерывные обои по общей геометрии экранов, включая поворот и масштаб."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import socket
import subprocess
import time

from PIL import Image, ImageOps


def rectangles(monitors):
    result = []
    for monitor in monitors:
        if monitor.get("disabled") or monitor.get("mirrorOf", "none") not in ("none", None, ""):
            continue
        width, height = monitor["width"], monitor["height"]
        if monitor.get("transform", 0) % 2:
            width, height = height, width
        scale = monitor.get("scale", 1)
        result.append({
            "name": monitor["name"], "x": monitor["x"], "y": monitor["y"],
            "w": math.ceil(width / scale), "h": math.ceil(height / scale),
            "pixels": (width, height),
        })
    if not result:
        raise ValueError("Нет активных экранов")
    return sorted(result, key=lambda r: r["name"])


def bounds(rects):
    left, top = min(r["x"] for r in rects), min(r["y"] for r in rects)
    right = max(r["x"] + r["w"] for r in rects)
    bottom = max(r["y"] + r["h"] for r in rects)
    return left, top, right - left, bottom - top


def prepare(image, rects, cache):
    key = hashlib.sha256((str(image) + json.dumps(rects, sort_keys=True)).encode()).hexdigest()[:20]
    directory = cache / key
    directory.mkdir(parents=True, exist_ok=True)
    files = [(r, directory / f"screen-{i}.png") for i, r in enumerate(rects)]
    if all(path.is_file() for _, path in files):
        return files
    left, top, width, height = bounds(rects)
    if width > 16384 or height > 16384:
        raise ValueError("Область экранов превышает 16384 точки по одной стороне")
    with Image.open(image) as source:
        canvas = ImageOps.fit(source.convert("RGB"), (width, height), method=Image.Resampling.LANCZOS)
    for rect, path in files:
        x, y = rect["x"] - left, rect["y"] - top
        crop = canvas.crop((x, y, x + rect["w"], y + rect["h"]))
        if crop.size != tuple(rect["pixels"]):
            crop = crop.resize(rect["pixels"], Image.Resampling.LANCZOS)
        temporary = path.with_suffix(".tmp")
        crop.save(temporary, format="PNG")
        temporary.replace(path)
    return files


def monitors():
    return json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"], timeout=5))


def apply(image, cache):
    rects = rectangles(monitors())
    files = prepare(image, rects, cache)
    for rect, path in files:
        result = subprocess.run(
            ["hyprctl", "hyprpaper", "wallpaper", f"{rect['name']},{path}"],
            capture_output=True, text=True, timeout=5, check=True,
        )
        # hyprpaper 0.8 может подтверждать успех пустым ответом.
        if result.stdout.strip() not in ("", "ok"):
            raise RuntimeError(result.stdout.strip() or result.stderr.strip())
    print(f"Обои установлены: {len(files)} экран(а), область {bounds(rects)[2:]}", flush=True)
    return rects


def watch(image, cache):
    # События Hyprland вместо непрерывного опроса и повторной обработки изображения.
    signature = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
    address = Path(os.environ["XDG_RUNTIME_DIR"]) / "hypr" / signature / ".socket2.sock"
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as events:
        events.connect(str(address))
        events.settimeout(30)
        current = apply(image, cache)
        pending = b""
        while True:
            try:
                data = events.recv(65536)
                if not data:
                    return
                pending += data
                lines = pending.split(b"\n")
                pending = lines.pop()
                changed = any(line.split(b">>", 1)[0] in {
                    b"monitoradded", b"monitoraddedv2", b"monitorremoved", b"configreloaded"
                } for line in lines)
                if changed:
                    time.sleep(0.4)
                    current = apply(image, cache)
            except socket.timeout:
                # Также учитывает изменение масштаба без подключения нового экрана.
                updated = rectangles(monitors())
                if updated != current:
                    current = apply(image, cache)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True, type=Path)
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()
    cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "cosmic-desktop/panorama"
    if args.once:
        apply(args.image, cache)
    else:
        watch(args.image, cache)


if __name__ == "__main__":
    main()
