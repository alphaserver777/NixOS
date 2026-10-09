"""Однократная настройка готового календаря; личные записи остаются изменяемыми."""
import datetime as dt
import json
import os
from pathlib import Path
import shutil
import socket
import sys
import time
from zoneinfo import ZoneInfo

home = Path.home()
config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config")) / "dankcal"
data = Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")) / "dankcal"
config.mkdir(parents=True, exist_ok=True)


def call(method, **params):
    # CLI выпуска 1.6.1 передаёт значения строками; штатный сокет принимает
    # массивы повторений и напоминаний в их исходном виде.
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    sockets = sorted(runtime.glob("dankcal-*.sock"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not sockets:
        raise OSError("Служба календаря ещё не запущена")
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(20)
        client.connect(str(sockets[0]))
        client.sendall((json.dumps({"id": 1, "method": method, "params": params}, ensure_ascii=False) + "\n").encode())
        with client.makefile() as stream:
            for line in stream:
                response = json.loads(line)
                if response.get("id") == 1:
                    break
            else:
                raise RuntimeError("Служба календаря закрыла соединение")
    if response.get("error"):
        raise RuntimeError(response["error"])
    return response.get("result")


def items(value, key):
    return value if isinstance(value, list) else value.get(key, [])


if sys.argv[1] == "settings":
    marker = config / ".cosmic-settings-v1"
    if not marker.exists():
        path = config / "ui-settings.json"
        settings = json.loads(path.read_text()) if path.exists() else {}
        if path.exists():
            shutil.copy2(path, config / "ui-settings.before-cosmic.json")
        settings.update(remindersEnabled=True, notificationSounds=True,
                        use24HourClock=True, timeFormat="24h", firstDayOfWeek=1)
        temporary = config / "ui-settings.tmp"
        temporary.write_text(json.dumps(settings, ensure_ascii=False, indent=2) + "\n")
        temporary.chmod(0o600)
        temporary.replace(path)
        marker.touch(mode=0o600)
elif sys.argv[1] == "events":
    marker = config / ".cosmic-stretch-events-v1"
    if not marker.exists():
        for attempt in range(30):
            try:
                accounts = items(call("accounts.list"), "accounts")
                break
            except (OSError, RuntimeError, json.JSONDecodeError):
                if attempt == 29:
                    raise
                time.sleep(0.5)
        account = next((a for a in accounts if a.get("kind") == "local" and a.get("displayName") == "Личные дела"), None)
        if account is None:
            directory = data / "personal"
            directory.mkdir(parents=True, exist_ok=True)
            call("accounts.local.add", root=str(directory), displayName="Личные дела")
            call("accounts.refresh")
            accounts = items(call("accounts.list"), "accounts")
            account = next(a for a in accounts if a.get("kind") == "local" and a.get("displayName") == "Личные дела")
        for attempt in range(30):
            calendars = items(call("calendars.list"), "calendars")
            calendar = next((c for c in calendars if c.get("accountId") == account["id"] and not c.get("readOnly")), None)
            if calendar:
                break
            time.sleep(0.5)
        else:
            raise RuntimeError("Личный календарь не появился после синхронизации")
        zone = ZoneInfo("Europe/Moscow")
        now = dt.datetime.now(zone)
        events = items(call("events.list", calendarId=calendar["id"],
                            **{"from": now.isoformat(), "to": (now + dt.timedelta(days=3)).isoformat()}), "events")
        for hour in (8, 17):
            tag = f"cosmic-stretch-{hour:02d}15-v1"
            if any(tag in e.get("description", "") for e in events):
                continue
            start = now.replace(hour=hour, minute=15, second=0, microsecond=0)
            if start <= now:
                start += dt.timedelta(days=1)
            call("events.create", calendarId=calendar["id"], summary="Разминка",
                 description=f"Пора встать и размяться. [{tag}]",
                 start=start.isoformat(), end=(start + dt.timedelta(minutes=5)).isoformat(),
                 recurrence=["FREQ=DAILY"], reminders=[{"method": "popup", "minutes": 0}])
        marker.touch(mode=0o600)
