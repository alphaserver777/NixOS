"""Переключение оболочек без смены сеанса с возвратом рабочего оформления."""

import fcntl
import os
from pathlib import Path
import subprocess
import sys
import time

STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "cosmic-desktop"
RUNTIME = Path(os.environ["XDG_RUNTIME_DIR"])
SERVICES = {"noctalia": "cosmic-noctalia.service", "dms": "cosmic-dms.service"}
NAMES = {"original": "Прежнее оформление", "noctalia": "Noctalia", "dms": "DankMaterialShell"}
READY = {
    "noctalia": ["cosmic-noctalia", "msg", "status"],
    "dms": ["cosmic-dms", "ipc", "bar", "status", "id", "default"],
}


def systemctl(*args, check=True):
    return subprocess.run(["systemctl", "--user", *args], check=check,
                          capture_output=True, text=True, timeout=25)


def active_choice():
    for choice, service in SERVICES.items():
        if systemctl("is-active", "--quiet", service, check=False).returncode == 0:
            return choice
    return "original"


def save(choice, filename="shell-selection"):
    STATE.mkdir(parents=True, exist_ok=True)
    temporary = STATE / (filename + ".new")
    temporary.write_text(choice + "\n")
    temporary.replace(STATE / filename)


def read_choice(filename="shell-selection", default="original"):
    try:
        value = (STATE / filename).read_text().strip()
    except OSError:
        return default
    return value if value in NAMES else default


def fallback(failed):
    choice = read_choice("shell-previous", "noctalia" if failed == "dms" else "original")
    return choice if choice != failed else "original"


def activate(choice):
    # Выбранная оболочка защищена от повторного запуска Hyprpanel при
    # применении системы. При ошибке restore() сразу возвращает прежний выбор.
    save(choice)
    other = [service for name, service in SERVICES.items() if name != choice]
    if choice != "original":
        other.append("hyprpanel.service")
    systemctl("stop", *other)
    # Прерванный запуск прежней панели может оставить состояние failed.
    systemctl("reset-failed", "hyprpanel.service", check=False)
    if choice == "original":
        systemctl("start", "hyprpanel.service")
        return
    service = SERVICES[choice]
    systemctl("reset-failed", service, check=False)
    systemctl("start", service)
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        if systemctl("is-active", "--quiet", service, check=False).returncode != 0:
            raise RuntimeError(f"{NAMES[choice]} завершилась при запуске")
        try:
            result = subprocess.run(READY[choice], capture_output=True, text=True,
                                    timeout=2, check=False)
        except subprocess.TimeoutExpired:
            time.sleep(0.2)
            continue
        # DMS может вернуть код 0 даже при ошибке команды управления.
        if result.returncode == 0 and (choice != "dms" or result.stdout.strip() in ("visible", "hidden")):
            return
        time.sleep(0.2)
    raise RuntimeError(f"{NAMES[choice]} не ответила после запуска")


def restore(choice):
    try:
        activate(choice)
    except Exception:
        choice = "original"
        activate(choice)
    save(choice)


def switch(choice, remember=True):
    previous = active_choice()
    try:
        activate(choice)
    except Exception:
        restore(previous if previous != choice else fallback(choice))
        raise
    if remember and previous != choice:
        save(previous, "shell-previous")
    save(choice)


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "status"
    if command == "status":
        print(NAMES[active_choice()])
        return
    if command == "allow-original":
        sys.exit(0 if read_choice() == "original" else 1)
    if command == "lock":
        # Служба пользователя находится вне графического сеанса.
        session = subprocess.run(
            ["loginctl", "show-user", str(os.getuid()), "--property=Display", "--value"],
            capture_output=True, text=True, check=True, timeout=5,
        ).stdout.strip()
        if not session:
            raise RuntimeError("Не найден графический сеанс для блокировки")
        os.execvp("loginctl", ["loginctl", "lock-session", session])
    if command in (*NAMES, "resume", "recover"):
        # ExecStopPost ставит восстановление в очередь без ожидания блокировки.
        with (RUNTIME / "cosmic-shell-switch.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            if command == "recover":
                if (active_choice() == "original" and
                        systemctl("is-active", "--quiet", "graphical-session.target", check=False).returncode == 0):
                    failed = read_choice()
                    restore(fallback(failed) if failed != "original" else "original")
                return
            switch(read_choice() if command == "resume" else command, remember=command != "resume")
        return
    actions = {
        "original": {
            "launcher": ["walker"],
            "center": ["hyprpanel", "toggleWindow", "dashboardmenu"],
            "dashboard": ["hyprpanel", "toggleWindow", "dashboardmenu"],
            "clipboard": ["walker", "--provider", "clipboard"],
            "notifications": ["hyprpanel", "toggleWindow", "notificationsmenu"],
        },
        "noctalia": {
            "launcher": ["cosmic-noctalia", "msg", "panel-toggle", "launcher"],
            "center": ["cosmic-noctalia", "msg", "panel-toggle", "control-center"],
            "dashboard": ["cosmic-noctalia", "msg", "panel-toggle", "control-center"],
            "clipboard": ["cosmic-noctalia", "msg", "panel-toggle", "clipboard"],
            "notifications": ["cosmic-noctalia", "msg", "panel-toggle", "control-center", "notifications"],
        },
        "dms": {
            "launcher": ["cosmic-dms", "ipc", "spotlight", "toggle"],
            "center": ["cosmic-dms", "ipc", "cosmic-center", "toggle"],
            "dashboard": ["cosmic-dms", "ipc", "dash", "toggle", ""],
            "clipboard": ["cosmic-dms", "ipc", "clipboard", "toggle"],
            "notifications": ["cosmic-dms", "ipc", "notifications", "toggle"],
        },
    }
    if command not in actions["original"]:
        raise ValueError("Неизвестная команда оформления")
    args = actions[active_choice()][command]
    os.execvp(args[0], args)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Не удалось переключить оформление: {error}", file=sys.stderr)
        sys.exit(1)
