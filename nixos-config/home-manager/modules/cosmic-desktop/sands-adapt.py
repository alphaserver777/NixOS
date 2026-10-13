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
replace_once(panel, '    // --- Hourglass ---', '''    // Задача 028: проверяем длительность до изменения текущего таймера.
    readonly property real customMs: /^[0-9]+([.,][0-9]+)?$/.test(durationInput.text.trim())
        ? Math.round(Number(durationInput.text.trim().replace(",", ".")) * 60000) : 0
    readonly property bool customValid: customMs >= 1000 && customMs <= TP.MAX_MS
    property bool editingDuration: !pop.t
    onTChanged: {
        if (!pop.t) pop.editingDuration = true;
        else if (!durationInput.activeFocus) pop.editingDuration = false;
    }

    function startInterval(ms, label) {
        if (!pop.d || !isFinite(ms) || ms < 1000 || ms > TP.MAX_MS) return;
        const previousId = pop.t ? pop.t.id : -1;
        const startedId = pop.d.start(ms, label, "duration", 0, true);
        if (startedId < 0) return;
        if (previousId >= 0) pop.d.remove(previousId);
        pop.selectedId = startedId;
        pop.editingDuration = false;
        pop.forceActiveFocus();
    }

    function startPreset(minutes, label) {
        pop.startInterval(minutes * 60000, label);
    }

    function startCustom() {
        if (customValid) pop.startInterval(customMs, "Таймер");
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
replace_once(panel, '        enabled: pop.shown && !!pop.t && !!pop.d',
             '        enabled: pop.shown && !!pop.t && !!pop.d && !pop.editingDuration')
replace_once(panel, '                text: pop.d ? pop.d.displayLabel(pop.t) : ""',
             '                text: pop.editingDuration ? "Своя длительность" : (pop.t && pop.d ? pop.d.displayLabel(pop.t) : "Таймер")')
replace_once(panel, '                text: TP.formatClock(pop.rem)',
             '                text: pop.t ? TP.formatClock(pop.rem) : "25:00"')
replace_once(panel, '                id: bigTime', '''                id: bigTime
                visible: !pop.editingDuration
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        durationInput.text = String(Math.max(1, Math.ceil(pop.rem / 60000)));
                        pop.editingDuration = true;
                        durationInput.forceActiveFocus();
                        durationInput.selectAll();
                    }
                }''')
replace_once(panel, '''            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4''', '''            Row {
                visible: pop.editingDuration
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingS
                TextInput {
                    id: durationInput
                    text: "25"
                    width: Math.max(72, Math.min(220, implicitWidth + 12))
                    font: bigTime.font
                    color: activeFocus ? Theme.primary : Theme.surfaceText
                    selectionColor: Theme.primaryContainer
                    selectedTextColor: Theme.primary
                    horizontalAlignment: TextInput.AlignHCenter
                    selectByMouse: true
                    activeFocusOnTab: true
                    maximumLength: 12
                    clip: true
                    onAccepted: pop.startCustom()
                    Keys.onEscapePressed: event => {
                        if (pop.t) {
                            pop.editingDuration = false;
                            pop.forceActiveFocus();
                            event.accepted = true;
                        } else event.accepted = false;
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.primary
                        opacity: durationInput.activeFocus ? 0.7 : 0.2
                    }
                }
                StyledText {
                    anchors.verticalCenter: durationInput.verticalCenter
                    text: "мин"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }
            }

            Row {
                visible: !pop.editingDuration
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4''')
replace_once(panel, '''    // --- Adjustments ---
    Row {''', '''    Row {
        visible: pop.editingDuration
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacingS
        DankButton {
            width: 140
            text: "Начать"
            enabled: !!pop.d && pop.customValid
            onClicked: pop.startCustom()
        }
        RoundButton {
            visible: !!pop.t
            iconName: "close"
            tooltip: "Вернуться к таймеру"
            onClicked: { pop.editingDuration = false; pop.forceActiveFocus(); }
        }
    }

    // --- Adjustments ---
    Row {
        visible: !!pop.t && !pop.editingDuration''')
replace_once(panel, '''    // --- Controls ---
    Item {''', '''    // --- Controls ---
    Item {
        visible: !!pop.t && !pop.editingDuration''')

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
