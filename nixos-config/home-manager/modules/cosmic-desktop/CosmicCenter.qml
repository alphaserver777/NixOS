import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modals.Common
import qs.Modules.DankDash
import qs.Modules.Settings
import qs.Modules.ProcessList
import qs.Modules.ControlCenter.Details
import qs.Modules.ControlCenter.Widgets

DankModal {
    id: root
    layerNamespace: "dms:cosmic-center"
    modalWidth: Math.min(920, screenWidth - 40)
    modalHeight: Math.min(650, screenHeight - 80)
    backgroundColor: Theme.surfaceContainer
    keepContentLoaded: false
    property int sectionIndex: 0
    readonly property var sections: [
        {title: "Главная", icon: "home"},
        {title: "Звук", icon: "volume_up"},
        {title: "Сеть", icon: "wifi"},
        {title: "Bluetooth", icon: "bluetooth"},
        {title: "Экраны", icon: "monitor"},
        {title: "Нагрузка", icon: "monitoring"},
        {title: "Система", icon: "computer"}
    ]

    function selectSection(index) {
        sectionIndex = ((index % sections.length) + sections.length) % sections.length;
    }
    Component.onCompleted: PopoutService.cosmicCenter = root
    Component.onDestruction: PopoutService.cosmicCenter = null
    onBackgroundClicked: close()
    HyprlandFocusGrab {
        windows: [root.contentWindow]
        active: root.useHyprlandFocusGrab && root.shouldHaveFocus
    }

    Shortcut {
        sequence: "Ctrl+Down"
        enabled: root.shouldBeVisible
        onActivated: root.selectSection(root.sectionIndex + 1)
    }
    Shortcut {
        sequence: "Ctrl+Up"
        enabled: root.shouldBeVisible
        onActivated: root.selectSection(root.sectionIndex - 1)
    }

    IpcHandler {
        target: "cosmic-center"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function section(index: int): void { root.selectSection(index); }
        function status(): string {
            return JSON.stringify({visible: root.shouldBeVisible, section: root.sectionIndex,
                coffee: SessionService.idleInhibited,
                screen: root.effectiveScreen?.name ?? "", x: root.alignedX, y: root.alignedY,
                width: root.modalWidth, height: root.modalHeight});
        }
    }

    content: FocusScope {
        id: panel
        focus: true
        Keys.priority: Keys.AfterItem
        Keys.onPressed: event => {
            const control = (event.modifiers & Qt.ControlModifier) !== 0;
            if ((sidebar.activeFocus || control) &&
                    [Qt.Key_Up, Qt.Key_Down, Qt.Key_Left, Qt.Key_Right].includes(event.key)) {
                if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                    root.selectSection(root.sectionIndex + (event.key === Qt.Key_Down ? 1 : -1));
                    sidebar.forceActiveFocus();
                } else if (event.key === Qt.Key_Left) {
                    sidebar.forceActiveFocus();
                } else {
                    page.forceActiveFocus();
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            }
        }
        Component.onCompleted: Qt.callLater(() => sidebar.forceActiveFocus())
        Shortcut {
            sequence: "Ctrl+Left"
            enabled: root.shouldBeVisible
            onActivated: sidebar.forceActiveFocus()
        }

        Rectangle {
            x: 12; y: 12
            width: 64; height: parent.height - 24
            radius: Theme.cornerRadius
            color: Theme.nestedSurface
            FocusScope {
                id: sidebar
                anchors.fill: parent
                focus: true
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 12
                    spacing: 10
                    Repeater {
                        model: root.sections
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: 44; height: 44
                            radius: 14
                            color: root.sectionIndex === index ? Theme.primary : "transparent"
                            border.width: sidebar.activeFocus && root.sectionIndex === index ? 2 : 0
                            border.color: Theme.surfaceText
                            DankIcon {
                                anchors.centerIn: parent
                                name: modelData.icon
                                size: 24
                                color: root.sectionIndex === index ? Theme.surface : Theme.surfaceText
                            }
                            StateLayer {
                                tooltipText: modelData.title
                                tooltipSide: "right"
                                cornerRadius: 14
                                onClicked: {
                                    root.selectSection(index);
                                    sidebar.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            x: 94; y: 18
            width: parent.width - 112
            height: parent.height - 36
            spacing: 14
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: root.sections[root.sectionIndex].title
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    color: Theme.primary
                    Layout.fillWidth: true
                }
                DankActionButton {
                    iconName: "settings"
                    tooltipText: "Настройки"
                    onClicked: { root.close(); PopoutService.openSettings(); }
                }
                DankActionButton {
                    iconName: "lock"
                    tooltipText: "Заблокировать"
                    onClicked: { root.close(); Quickshell.execDetached(["cosmic-shell", "lock"]); }
                }
                DankActionButton {
                    iconName: "power_settings_new"
                    tooltipText: "Питание"
                    onClicked: { root.close(); PopoutService.openPowerMenu(); }
                }
                DankActionButton {
                    iconName: "close"
                    tooltipText: "Закрыть"
                    onClicked: root.close()
                }
            }
            Loader {
                id: page
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                sourceComponent: [homePage, audioPage, networkPage, bluetoothPage,
                    displaysPage, performancePage, systemPage][root.sectionIndex]
            }
            StyledText {
                Layout.fillWidth: true
                text: sidebar.activeFocus ? "↑ ↓ — разделы     → / Tab — управление     Esc — закрыть" :
                    "Ctrl + ↑ ↓ — разделы     Ctrl + ← — меню     Esc — закрыть"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }

        Component {
            id: homePage
            OverviewTab {
                onCloseDash: root.close()
                onSwitchToMediaTab: {
                    root.close();
                    PopoutService.openDankDash(1);
                }
            }
        }
        Component {
            id: audioPage
            ColumnLayout {
                spacing: Theme.spacingM
                StyledText {
                    Layout.fillWidth: true
                    text: "Громкость"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                }
                AudioSliderRow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                }
                AudioOutputDetail {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: 0
                    hasVolumeSliderInCC: true
                }
            }
        }
        Component { id: networkPage; NetworkTab {} }
        Component {
            id: bluetoothPage
            Item {
                BluetoothDetail {
                    id: bluetooth
                    anchors.fill: parent
                    implicitHeight: 0
                    onShowCodecSelector: device => codecSelector.show(device)
                }
                BluetoothCodecSelector {
                    id: codecSelector
                    anchors.fill: parent
                    onCodecSelected: (address, codec) => bluetooth.updateDeviceCodecDisplay(address, codec)
                }
            }
        }
        Component { id: displaysPage; DisplayConfigTab {} }
        Component { id: performancePage; PerformanceView {} }
        Component { id: systemPage; SystemView {} }
    }
}
