"""Выбор заставки и управление существующей службой простоя."""

import subprocess
import sys

from effects import EFFECTS, select, selected


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "start"
    if command in ("start", "stop"):
        return subprocess.call(["systemctl", "--user", command, "cosmic-screensaver.service"])
    if command == "status":
        print(EFFECTS[selected()])
        return 0
    if command == "set" and len(sys.argv) == 3:
        select(sys.argv[2])
        return 0
    if command == "choose":
        labels = list(EFFECTS.values())
        result = subprocess.run(
            ["zenity", "--list", "--title=Заставка с часами", "--column=Заставка", *labels],
            capture_output=True, text=True, check=False,
        )
        if result.returncode == 0 and result.stdout.strip() in labels:
            select(next(key for key, label in EFFECTS.items() if label == result.stdout.strip()))
        return 0
    print("Использование: cosmic-screensaver start|stop|choose|status|set <название>", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
