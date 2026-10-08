"""Первоначальная настройка расширений без сброса оформления пользователя."""
import json
import os
from pathlib import Path

root = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "DankMaterialShell"
marker = root / ".cosmic-sands-layout-v1"


def write_json(path, value):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")
    temporary.chmod(0o600)
    temporary.replace(path)


if not marker.exists():
    path = root / "settings.json"
    data = json.loads(path.read_text())
    for bar in data.get("barConfigs", []):
        for key, widget in [
            ("centerWidgets", "smartTimer"),
            ("rightWidgets", {"id": "keyboard_layout_name", "enabled": True, "keyboardLayoutNameCompactMode": True}),
        ]:
            widgets = bar.setdefault(key, [])
            identifier = widget if isinstance(widget, str) else widget["id"]
            if not any((v if isinstance(v, str) else v.get("id")) == identifier for v in widgets):
                widgets.append(widget)
    write_json(path, data)
    path = root / "plugin_settings.json"
    data = json.loads(path.read_text()) if path.exists() else {}
    for name, defaults in {
        "smartTimer": {"enabled": True, "volume": 50, "ringDuration": 15, "noTrigger": True},
        "smartTimerLauncher": {"enabled": True, "noTrigger": True},
    }.items():
        settings = data.setdefault(name, {})
        for key, value in defaults.items():
            settings.setdefault(key, value)
    write_json(path, data)
    marker.touch(mode=0o600)
