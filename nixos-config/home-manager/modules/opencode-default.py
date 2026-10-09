"""Задача 013: однократная смена модели без замены личных подключений."""

import json
import os
from pathlib import Path
import shutil
import stat
import tempfile


def initialize(config_home, state_home):
    state = state_home / "nixos-opencode-free"
    state.mkdir(mode=0o700, parents=True, exist_ok=True)
    state.chmod(0o700)
    marker = state / "default-initialized"
    if marker.exists():
        return
    path = config_home / "opencode/opencode.json"
    if path.is_symlink():
        raise RuntimeError("Настройки OpenCode должны оставаться изменяемыми")
    settings = json.loads(path.read_text()) if path.exists() else {}
    model = settings.get("model", "")
    if model and not model.startswith("a6api/"):
        marker.write_text("Сохранён текущий выбор пользователя\n")
        return
    backup = state / "config-before.json"
    if path.exists() and not backup.exists():
        shutil.copyfile(path, backup)
        backup.chmod(0o600)
    mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
    settings["model"] = "opencode/space-bunny-free"
    settings["small_model"] = "opencode/space-bunny-free"
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(dir=path.parent, prefix=".opencode-")
    try:
        with os.fdopen(descriptor, "w") as output:
            json.dump(settings, output, ensure_ascii=False, indent=2)
            output.write("\n")
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    marker.write_text("opencode/space-bunny-free\n")


if __name__ == "__main__":
    initialize(Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")),
               Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")))
