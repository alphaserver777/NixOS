import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

DankOSD {
    id: root
    blurNamespace: "dms:keyboard-layout"
    modelData: CompositorService.getFocusedScreen()
    osdWidth: 170
    osdHeight: 110
    autoHideInterval: 1100
    enableMouseInteraction: false
    anchors { top: false; bottom: false; left: false; right: false }
    WlrLayershell.margins { top: 0; bottom: 0; left: 0; right: 0 }

    property string layoutCode: ""
    property string layoutName: ""
    property bool initialized: false

    function refresh() {
        Proc.runCommand("cosmic-layout-osd", ["hyprctl", "-j", "devices"], (output, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const keyboard = JSON.parse(output).keyboards.find(k => k.main);
                if (!keyboard) return;
                const codes = keyboard.layout.split(",");
                const code = codes[keyboard.active_layout_index] || keyboard.active_keymap;
                const changed = root.initialized && code !== root.layoutCode;
                root.layoutCode = code;
                root.layoutName = keyboard.active_keymap;
                root.initialized = true;
                if (changed && !SessionService.locked && !IdleService.isShellLocked && !IdleService.monitorsOff)
                    root.show();
            } catch (e) {
                console.warn("Не удалось определить раскладку:", e);
            }
        }, 70);
    }
    Component.onCompleted: refresh()
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") root.refresh();
        }
    }
    content: Column {
        anchors.centerIn: parent
        spacing: Theme.spacingXS
        DankIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "keyboard"
            size: Theme.iconSize
            color: Theme.primary
        }
        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: Qt.resolvedUrl("../assets/flags/" + (root.layoutCode === "ru" ? "ru" : "us") + ".svg")
            width: 70
            height: 44
            fillMode: Image.PreserveAspectFit
        }
    }
}
