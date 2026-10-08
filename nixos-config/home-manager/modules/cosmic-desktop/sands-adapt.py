"""Адаптация Sands 1.4.3 к интерфейсу расширений DMS 1.4.6."""
import json
from pathlib import Path
import sys

root = Path(sys.argv[1])
sound_dir = sys.argv[2]

# В DMS 1.4 нет составных расширений. Движок живёт в одном экземпляре
# поставщика поиска, а виджет на каждом экране обращается к этому движку.
for name in ("TimerWidget.qml", "TimerSettings.qml", "TimerLauncher.qml"):
    path = root / name
    text = path.read_text()
    before = "PluginService.pluginDaemonInstances[pluginId] ?? null"
    assert text.count(before) == 1, name
    text = text.replace(before, 'PluginService.pluginInstances["smartTimerLauncher"]?.engine ?? null')
    if name == "TimerLauncher.qml":
        text = text.replace("    signal itemsChanged", """    readonly property alias engine: timerEngine
    TimerDaemon {
        id: timerEngine
        pluginService: root.pluginService
    }

    signal itemsChanged""")
        text = text.replace("PluginService.getPluginTrigger(pluginId)", 'PluginService.getPluginTrigger("smartTimerLauncher")')
    path.write_text(text)

for name in ("TimerDaemon.qml", "TimerSettings.qml"):
    path = root / name
    path.write_text(path.read_text().replace("/usr/share/sounds/freedesktop/stereo", sound_dir))

for path in root.rglob("*.qml"):
    text = path.read_text().replace("SettingsData.reduceMotion", "(SettingsData.animationSpeed === SettingsData.AnimationSpeed.None)")
    text = text.replace("Theme.onError", '(Theme.currentThemeData.errorText || "#601410")')
    # Измерение текста отдельно от ширины предотвращает цикл при сигнале.
    if path.name == "TimerWidget.qml":
        text = text.replace('width: pill.st === "ringing" ? implicitWidth : Math.ceil(metrics.advanceWidth)', 'width: pill.st === "ringing" ? doneMetrics.advanceWidth : Math.ceil(metrics.advanceWidth)')
        text = text.replace("                    id: timeLabel", """                    id: timeLabel
                    TextMetrics { id: doneMetrics; font: timeLabel.font; text: timeLabel.text }""")
    path.write_text(text)

manifest = json.loads((root / "plugin.json").read_text())
manifest.update(type="widget", component="./TimerWidget.qml", capabilities=["dankbar-widget"], requires_dms=">=1.4.6")
manifest.pop("components")
(root / "plugin.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
launcher = dict(manifest)
launcher.update(id="smartTimerLauncher", name="Sands — поиск и отсчёт", type="launcher", component="./TimerLauncher.qml", capabilities=["launcher"])
launcher.pop("settings")
(root / "launcher-plugin.json").write_text(json.dumps(launcher, ensure_ascii=False, indent=2) + "\n")
