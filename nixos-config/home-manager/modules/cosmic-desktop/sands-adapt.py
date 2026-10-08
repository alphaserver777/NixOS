"""Постоянный виджет и прямой запуск Sands для DMS 1.6."""
from pathlib import Path
import sys

root = Path(sys.argv[1])
sound_dir = sys.argv[2]


def replace_once(path, before, after):
    text = path.read_text()
    if text.count(before) != 1:
        raise RuntimeError(f"Изменились исходники Sands: {path.name}")
    path.write_text(text.replace(before, after))

# Виджет остаётся доступен без запущенного отсчёта.
widget = root / "TimerWidget.qml"
replace_once(widget, """        setVisibilityOverride(root.hasTimers);
        if (!root.hasTimers)
            root.closePopout();""", "        setVisibilityOverride(true);")
replace_once(widget, 'readonly property string timeText: st === "ringing" ? "Done" : TP.formatClock(rem)',
             'readonly property string timeText: st === "idle" ? "Таймер" : (st === "ringing" ? "Готово" : TP.formatClock(rem))')
replace_once(widget, 'readonly property bool showLabel: st === "ringing" || flashTimer !== null || hoverOpen',
             'readonly property bool showLabel: !!t && (st === "ringing" || flashTimer !== null || hoverOpen)')
replace_once(widget, '                        id: bell', '''                        visible: pill.st === "idle"
                        anchors.centerIn: parent
                        name: "hourglass_empty"
                        size: parent.width
                        color: Theme.primary
                    }

                    DankIcon {
                        id: bell''')
replace_once(widget, '                ProgressRing {\n                    anchors.fill: parent',
             '''                DankIcon {
                    anchors.centerIn: parent
                    visible: vpill.st === "idle"
                    name: "hourglass_empty"
                    size: parent.width
                    color: Theme.primary
                }
                ProgressRing {
                    visible: vpill.st !== "idle"
                    anchors.fill: parent''')
replace_once(widget, '                    const s = Math.ceil(Math.abs(vpill.rem) / 1000);',
             '                    if (vpill.st === "idle") return "25м";\n                    const s = Math.ceil(Math.abs(vpill.rem) / 1000);')
replace_once(widget, '    popoutHeight: 560', '    popoutHeight: 650')

# Прямой запуск интервала из окна песочных часов. Новый интервал заменяет
# показанный таймер, остальные независимо созданные таймеры сохраняются.
panel = root / "components/TimerPanelContent.qml"
replace_once(panel, '    // --- Hourglass ---', '''    function startPreset(minutes, label) {
        if (!pop.d) return;
        if (pop.t) pop.d.remove(pop.t.id);
        pop.selectedId = pop.d.start(minutes * 60000, label, "duration", 0, true);
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacingS
        DankButton {
            width: (pop.width - Theme.spacingS) / 2
            text: "Работа · 25 мин"
            enabled: !!pop.d
            onClicked: pop.startPreset(25, "Работа")
        }
        DankButton {
            width: (pop.width - Theme.spacingS) / 2
            text: "Отдых · 5 мин"
            enabled: !!pop.d
            onClicked: pop.startPreset(5, "Отдых")
        }
    }

    // --- Hourglass ---''')
replace_once(panel, '                text: pop.d ? pop.d.displayLabel(pop.t) : ""',
             '                text: pop.t && pop.d ? pop.d.displayLabel(pop.t) : "Выбери интервал выше"')
replace_once(panel, '                text: TP.formatClock(pop.rem)',
             '                text: pop.t ? TP.formatClock(pop.rem) : "25:00"')
replace_once(panel, '''    // --- Adjustments ---
    Row {''', '''    // --- Adjustments ---
    Row {
        visible: !!pop.t''')
replace_once(panel, '''    // --- Controls ---
    Item {''', '''    // --- Controls ---
    Item {
        visible: !!pop.t''')

for name in ("TimerDaemon.qml", "TimerSettings.qml"):
    path = root / name
    path.write_text(path.read_text().replace("/usr/share/sounds/freedesktop/stereo", sound_dir))

for path in root.rglob("*.qml"):
    text = path.read_text()
    # Измерение текста отдельно от ширины предотвращает цикл при сигнале.
    if path.name == "TimerWidget.qml":
        text = text.replace('width: pill.st === "ringing" ? implicitWidth : Math.ceil(metrics.advanceWidth)', 'width: pill.st === "ringing" || pill.st === "idle" ? doneMetrics.advanceWidth : Math.ceil(metrics.advanceWidth)')
        text = text.replace("                    id: timeLabel", """                    id: timeLabel
                    TextMetrics { id: doneMetrics; font: timeLabel.font; text: timeLabel.text }""")
    path.write_text(text)
