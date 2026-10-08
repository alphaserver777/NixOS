"""Общий выбор заставки; состояние хранится отдельно от настроек Nix."""

import os
from pathlib import Path

EFFECTS = {
    "aurora": "Северное сияние",
    "meteors": "Метеорный дождь",
    "constellations": "Созвездия",
    "stars": "Космический полёт",
}
STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "cosmic-desktop"


def selected():
    try:
        value = (STATE / "screensaver-effect").read_text().strip()
    except OSError:
        value = "aurora"
    return value if value in EFFECTS else "aurora"


def select(value):
    if value not in EFFECTS:
        raise ValueError("Неизвестная заставка")
    STATE.mkdir(parents=True, exist_ok=True)
    temporary = STATE / "screensaver-effect.new"
    temporary.write_text(value + "\n")
    temporary.replace(STATE / "screensaver-effect")
