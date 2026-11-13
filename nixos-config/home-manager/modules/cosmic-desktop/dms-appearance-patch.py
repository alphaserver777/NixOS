"""Задача 050: тихие уведомления и фокус Sands без изменения ручного DND."""
from pathlib import Path
import sys

root = Path(sys.argv[1])


def replace(path, before, after):
    target = root / path
    text = target.read_text()
    if text.count(before) != 1:
        raise RuntimeError(f"Изменилась структура DMS: {path}")
    target.write_text(text.replace(before, after))


replace("Services/NotificationService.qml", '    property var seenNotifications: []', '''    // Фокус зависит от состояния таймера, ручной DND не перезаписывается.
    readonly property var focusTimer: PluginService.pluginDaemonInstances["smartTimer"] ?? null
    readonly property bool focusTimerActive: focusTimer?.timers?.some(
        t => t.state === "running" && t.label === "Работа") ?? false
    readonly property bool quietMode: SessionData.doNotDisturb || focusTimerActive

    property var seenNotifications: []''')

replace("Services/NotificationService.qml",
        'const dndBlocked = SessionData.doNotDisturb && !_allowedInDnd(policy.urgency, policy.bypassDnd);',
        'const dndBlocked = root.quietMode && !_allowedInDnd(policy.urgency, policy.bypassDnd);')
replace("Services/NotificationService.qml",
        '(!SessionData.doNotDisturb || _allowedInDnd(w.urgency, w.bypassDnd))',
        '(!root.quietMode || _allowedInDnd(w.urgency, w.bypassDnd))')
replace("Services/NotificationService.qml", '''    Connections {
        target: SessionData
        function onDoNotDisturbChanged() {
            if (SessionData.doNotDisturb) {
                notificationQueue = notificationQueue.filter(w => w && _allowedInDnd(w.urgency, w.bypassDnd));
                for (const notif of visibleNotifications) {
                    if (!_allowedInDnd(notif.urgency, notif.bypassDnd))
                        notif.popup = false;
                }
            }
            processQueue();
        }
    }''', '''    onQuietModeChanged: {
        if (quietMode) {
            notificationQueue = notificationQueue.filter(w => w && _allowedInDnd(w.urgency, w.bypassDnd));
            for (const notif of visibleNotifications) {
                if (!_allowedInDnd(notif.urgency, notif.bypassDnd))
                    notif.popup = false;
            }
        }
        processQueue();
    }

    // Диагностика без содержимого личных уведомлений.
    IpcHandler {
        target: "cosmic-notifications"
        function status(): string {
            return JSON.stringify({
                focus: root.focusTimerActive,
                quiet: root.quietMode,
                manualDnd: SessionData.doNotDisturb,
                normalPopups: root.popups.filter(w => w.urgency !== NotificationUrgency.Critical).length,
                criticalPopups: root.popups.filter(w => w.urgency === NotificationUrgency.Critical).length,
                primary: Theme.primary.toString(),
                surface: Theme.surface.toString()
            });
        }
    }''')

# Приглушить только звуки уведомлений, сохранив штатную регулировку громкости.
for player in ("normalNotificationPlayer", "criticalNotificationPlayer"):
    replace("Services/AudioSoundPlayers.qml", f'''        id: {player}
        source: root.{player.replace("Player", "Source")}
        audioOutput: AudioOutput {{
            device: devices.defaultAudioOutput
            volume: root.volume''', f'''        id: {player}
        source: root.{player.replace("Player", "Source")}
        audioOutput: AudioOutput {{
            device: devices.defaultAudioOutput
            volume: root.volume * 0.35''')
