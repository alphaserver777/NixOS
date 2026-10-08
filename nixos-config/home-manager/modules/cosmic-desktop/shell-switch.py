"""Переключение готовой оболочки и прежней панели без смены сеанса."""

import fcntl
import os
from pathlib import Path
import socket
import subprocess
import sys
import time

STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "cosmic-desktop"
RUNTIME = Path(os.environ["XDG_RUNTIME_DIR"])
SERVICE = "cosmic-noctalia.service"


def systemctl(*args, check=True):
    return subprocess.run(["systemctl", "--user", *args], check=check,
                          capture_output=True, text=True, timeout=25)


def active():
    return systemctl("is-active", "--quiet", SERVICE, check=False).returncode == 0


def save(choice):
    STATE.mkdir(parents=True, exist_ok=True)
    temporary = STATE / "shell-selection.new"
    temporary.write_text(choice + "\n")
    temporary.replace(STATE / "shell-selection")


def selected():
    try:
        value = (STATE / "shell-selection").read_text().strip()
    except OSError:
        value = "original"
    return value if value in ("noctalia", "original") else "original"


def close_center():
    with socket.socket(socket.AF_UNIX) as client:
        try:
            client.connect(str(RUNTIME / "cosmic-control-center.sock"))
        except (FileNotFoundError, ConnectionRefusedError):
            pass


def original():
    systemctl("stop", SERVICE)
    systemctl("start", "hyprpanel.service")
    save("original")


def switch(choice):
    close_center()
    if choice == "original":
        original()
        return
    try:
        systemctl("reset-failed", SERVICE, check=False)
        systemctl("start", SERVICE)
        # Готовность проверяется через настоящий канал управления оболочкой.
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if not active():
                raise RuntimeError("Noctalia завершилась при запуске")
            result = subprocess.run(["cosmic-noctalia", "msg", "status"],
                                    capture_output=True, text=True, timeout=2, check=False)
            if result.returncode == 0:
                save("noctalia")
                return
            time.sleep(0.2)
        raise RuntimeError("Noctalia не ответила после запуска")
    except Exception:
        original()
        raise


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "status"
    if command == "status":
        print("Noctalia" if active() else "Прежнее оформление")
        return
    if command == "lock":
        # Служба пользователя находится вне графического сеанса: передаём
        # его номер явно, чтобы loginctl не искал сеанс по своему процессу.
        session = subprocess.run(
            ["loginctl", "show-user", str(os.getuid()), "--property=Display", "--value"],
            capture_output=True, text=True, check=True, timeout=5,
        ).stdout.strip()
        if not session:
            raise RuntimeError("Не найден графический сеанс для блокировки")
        os.execvp("loginctl", ["loginctl", "lock-session", session])
    if command in ("noctalia", "original", "resume", "recover"):
        # ExecStopPost только ставит восстановление в очередь: ожидание этой
        # блокировки происходит после завершения останавливаемой службы.
        with (RUNTIME / "cosmic-shell-switch.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            if command == "recover":
                if (not active() and systemctl("is-active", "--quiet", "graphical-session.target", check=False).returncode == 0):
                    systemctl("start", "hyprpanel.service")
                    save("original")
                return
            switch(selected() if command == "resume" else command)
        return
    actions = {
        "launcher": (["cosmic-noctalia", "msg", "panel-toggle", "launcher"], ["walker"]),
        "center": (["cosmic-noctalia", "msg", "panel-toggle", "control-center"], ["cosmic-control-center"]),
        "clipboard": (["cosmic-noctalia", "msg", "panel-toggle", "clipboard"], ["walker", "--provider", "clipboard"]),
        "notifications": (["cosmic-noctalia", "msg", "panel-toggle", "control-center", "notifications"], ["hyprpanel", "toggleWindow", "notificationsmenu"]),
    }
    if command not in actions:
        raise ValueError("Неизвестная команда оформления")
    new, old = actions[command]
    args = new if active() else old
    os.execvp(args[0], args)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Не удалось переключить оформление: {error}", file=sys.stderr)
        sys.exit(1)
