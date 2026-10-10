"""Подставить выбранный экран и передать блокировку настоящему Hyprlock."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from display_selection import select_monitor


def place_widgets(content, monitor):
    section = None
    lines = []
    for line in content.splitlines(keepends=True):
        stripped = line.strip()
        if stripped.endswith("{"):
            section = stripped[:-1].strip()
        elif stripped == "}":
            section = None
        elif section in ("label", "input-field") and stripped.split("=", 1)[0].strip() == "monitor":
            indent = line[:len(line) - len(line.lstrip())]
            line = f"{indent}monitor={monitor}\n"
        lines.append(line)
    return "".join(lines)


def main():
    executable, template, *arguments = sys.argv[1:]
    if any(argument in ("-c", "--config", "-h", "--help", "-V", "--version")
           or argument.startswith("--config=") for argument in arguments):
        os.execv(executable, [executable, *arguments])

    try:
        result = subprocess.run(["hyprctl", "-j", "monitors"], check=True,
                                capture_output=True, text=True, timeout=2)
        monitor = select_monitor(json.loads(result.stdout))["name"]
    except (OSError, subprocess.SubprocessError, ValueError, TypeError, KeyError, RuntimeError):
        # Ошибка выбора экрана не должна отменять блокировку.
        monitor = ""

    try:
        content = place_widgets(Path(template).read_text(), monitor)
        runtime = Path(os.environ["XDG_RUNTIME_DIR"])
        config = runtime / "cosmic-hyprlock.conf"
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=runtime,
                                         prefix=".cosmic-hyprlock-", delete=False) as file:
            file.write(content)
            temporary = Path(file.name)
        temporary.replace(config)
    except (OSError, KeyError):
        # Сохраняем штатный поиск настройки, если копию создать не удалось.
        os.execv(executable, [executable, *arguments])
    os.execv(executable, [executable, "--config", str(config), *arguments])


if __name__ == "__main__":
    main()
