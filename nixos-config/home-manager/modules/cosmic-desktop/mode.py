"""Режимы рабочего стола. Возврат сохраняет приложения открытыми."""
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

LABELS = {"normal": "Обычный", "work": "Работа", "video": "Видео", "show": "Показ"}
STATE = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "cosmic-desktop"


def command(*args):
    return subprocess.check_output(args, text=True, timeout=10).strip()


def hypr(query):
    return json.loads(command("hyprctl", query, "-j"))


def dispatch(name, argument=""):
    result = command("hyprctl", "dispatch", name, argument)
    if result != "ok":
        raise RuntimeError(result)


def load():
    try:
        state = json.loads((STATE / "mode.json").read_text())
        if state.get("session") == os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            return state
    except (FileNotFoundError, ValueError):
        pass
    return {"mode": "normal"}


def save(state):
    state["session"] = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    temporary = STATE / "mode.tmp"
    temporary.write_text(json.dumps(state, ensure_ascii=False))
    temporary.replace(STATE / "mode.json")


def release(state):
    if state.get("mode") == "show":
        dispatch("overview:close", "all")
    if state.get("owned_fullscreen"):
        address = state["owned_fullscreen"]
        previous = hypr("activewindow").get("address")
        window = next((w for w in hypr("clients") if w["address"] == address), None)
        if window and window.get("fullscreen") == 2:
            dispatch("focuswindow", f"address:{address}")
            dispatch("fullscreen", "0")
            if previous and previous != address:
                dispatch("focuswindow", f"address:{previous}")
    if state.get("owned_idle"):
        command("cosmic-dms", "ipc", "inhibit", "disable")
    if state.get("layout"):
        available = {m["name"] for m in hypr("monitors")}
        for workspace in state["layout"]:
            if workspace["monitor"] in available:
                dispatch("moveworkspacetomonitor", f"{workspace['id']} {workspace['monitor']}")
    if state.get("windows"):
        clients = {w["address"]: w for w in hypr("clients")}
        for old in state["windows"]:
            current = clients.get(old["address"])
            if current and current["workspace"]["id"] == old["target"]:
                dispatch("movetoworkspacesilent", f"{old['workspace']},address:{old['address']}")
    if state.get("views"):
        available = {m["name"] for m in hypr("monitors")}
        for view in state["views"]:
            if view["monitor"] in available and view["workspace"] > 0:
                dispatch("focusmonitor", view["monitor"])
                dispatch("workspace", str(view["workspace"]))
        if state.get("focused") in available:
            dispatch("focusmonitor", state["focused"])


def work(state):
    monitors = [m for m in hypr("monitors") if not m.get("disabled") and m.get("mirrorOf", "none") in ("none", None, "")]
    if not monitors:
        raise RuntimeError("Нет активных экранов")
    # Нижний левый экран — основной, затем правый и верхний.
    lower = max(m["y"] for m in monitors)
    ordered = sorted(monitors, key=lambda m: (m["y"] != lower, m["x"], -m["y"]))
    state["layout"] = [{"id": w["id"], "monitor": w["monitor"]} for w in hypr("workspaces") if w["id"] in (1, 2, 4)]
    state["views"] = [{"monitor": m["name"], "workspace": m["activeWorkspace"]["id"]} for m in monitors]
    state["focused"] = next((m["name"] for m in monitors if m.get("focused")), ordered[0]["name"])
    targets = [(1, ordered[0], "google-chrome-stable", r"google-chrome"),
               (4, ordered[min(1, len(ordered) - 1)], "code", r"^(code|Code|code-oss|VSCodium)$"),
               (2, ordered[min(2, len(ordered) - 1)], "alacritty", r"(?i)^Alacritty$")]
    clients = hypr("clients")
    state["windows"] = [{"address": w["address"], "workspace": w["workspace"]["id"], "target": workspace}
                        for workspace, _, _, pattern in targets for w in clients
                        if w["workspace"]["id"] > 0 and re.search(pattern, w.get("class", ""))]
    save(state)
    # Сначала создаём недостающие столы, чтобы перенос имел однозначную цель.
    original = hypr("activeworkspace")["id"]
    for workspace, monitor, application, pattern in targets:
        dispatch("workspace", str(workspace))
        dispatch("moveworkspacetomonitor", f"{workspace} {monitor['name']}")
        matching = [w for w in clients if re.search(pattern, w.get("class", ""))]
        for window in matching:
            dispatch("movetoworkspacesilent", f"{workspace},address:{window['address']}")
        if not matching and shutil.which(application):
            dispatch("exec", f"[workspace {workspace} silent] {application}")
    dispatch("workspace", str(original))
    # По одному видимому столу на экран; редактор имеет приоритет перед терминалом.
    for workspace, _, _, _ in reversed(targets):
        dispatch("workspace", str(workspace))


def activate(kind):
    state = load()
    if state.get("mode") == kind:
        return
    release(state)
    save({"mode": "normal"})
    state = {"mode": kind}
    if kind == "work":
        work(state)
    elif kind == "video":
        active = hypr("activewindow")
        if not active.get("address"):
            raise RuntimeError("Сначала открой окно с видео")
        if not active.get("fullscreen"):
            dispatch("fullscreen", "0")
            state["owned_fullscreen"] = active["address"]
            save(state)
        if command("cosmic-dms", "ipc", "inhibit", "status").strip().lower().endswith("is disabled"):
            command("cosmic-dms", "ipc", "inhibit", "enable")
            state["owned_idle"] = True
            save(state)
    elif kind == "show":
        dispatch("overview:open", "all")
    save(state)
    subprocess.run(["notify-send", "Рабочий стол", f"Режим «{LABELS[kind]}»"], check=False)


def main():
    kind = sys.argv[1] if len(sys.argv) > 1 else "menu"
    if kind == "status":
        print(LABELS.get(load().get("mode"), LABELS["normal"]))
        return
    if kind == "menu":
        result = subprocess.run(["zenity", "--list", "--title=Режим рабочего стола",
                                 "--column=Режим", *LABELS.values()],
                                text=True, capture_output=True, timeout=120)
        kind = next((k for k, label in LABELS.items() if label == result.stdout.strip()), None)
        if not kind:
            return
    if kind not in LABELS:
        raise ValueError("Неизвестный режим рабочего стола")
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / "mode.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        activate(kind)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(error, file=sys.stderr)
        subprocess.run(["notify-send", "Режим рабочего стола", str(error)], check=False)
        sys.exit(1)
