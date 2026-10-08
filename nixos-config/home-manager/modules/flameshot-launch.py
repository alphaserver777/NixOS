"""Размер окна Flameshot по расположению подключённых экранов Hyprland."""

import argparse
import json
import math
import os
import subprocess
import sys


def screen_bounds(monitors):
    screens = [m for m in monitors if not m.get("disabled") and m.get("mirrorOf", "none") in ("none", None, "")]
    if not screens:
        raise ValueError("Нет активных экранов")
    rectangles = []
    for monitor in screens:
        width, height = monitor["width"], monitor["height"]
        if monitor.get("transform", 0) % 2:
            width, height = height, width
        scale = monitor.get("scale", 1)
        rectangles.append((monitor["x"], monitor["y"], math.ceil(width / scale), math.ceil(height / scale)))
    left = min(r[0] for r in rectangles)
    top = min(r[1] for r in rectangles)
    right = max(r[0] + r[2] for r in rectangles)
    bottom = max(r[1] + r[3] for r in rectangles)
    anchor = min(screens, key=lambda m: (m["y"], m["x"], m["id"]))
    return anchor["id"], left - anchor["x"], top - anchor["y"], right - left, bottom - top


def configure(hyprctl):
    monitors = json.loads(subprocess.check_output([hyprctl, "monitors", "-j"], timeout=5))
    monitor, x, y, width, height = screen_bounds(monitors)
    # Именованное правило обновляется, а не добавляется при каждом запуске.
    values = {
        "match:title": "^flameshot$",
        "float": "on",
        "pin": "on",
        "rounding": "0",
        "border_size": "0",
        "fullscreen_state": "0 0",
        "monitor": str(monitor),
        "move": f"{x} {y}",
        "size": f"{width} {height}",
    }
    commands = "; ".join(f"keyword windowrule[flameshot-capture]:{key} {value}" for key, value in values.items())
    result = subprocess.run([hyprctl, "--batch", commands], capture_output=True, text=True, timeout=5, check=True)
    if any(line.strip() != "ok" for line in result.stdout.splitlines() if line.strip()):
        raise RuntimeError(result.stdout.strip())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--flameshot", required=True)
    parser.add_argument("--hyprctl", required=True)
    parser.add_argument("--configure-only", action="store_true")
    options, arguments = parser.parse_known_args()
    if arguments[:1] == ["--"]:
        arguments = arguments[1:]
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        try:
            configure(options.hyprctl)
        except (ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
            print(f"Flameshot: не удалось настроить размер окна: {error}", file=sys.stderr)
            if options.configure_only:
                return 1
        os.environ["QT_QPA_PLATFORM"] = "wayland"
        os.environ.pop("QT_SCREEN_SCALE_FACTORS", None)
    if not options.configure_only:
        os.execv(options.flameshot, [options.flameshot, *arguments])
    return 0


if __name__ == "__main__":
    sys.exit(main())
