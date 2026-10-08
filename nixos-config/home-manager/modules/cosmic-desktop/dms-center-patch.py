"""Добавить панель к установленным исходникам DMS без пересборки программы."""
import pathlib
import sys

root = pathlib.Path(sys.argv[1])


def replace(path, before, after):
    target = root / path
    source = target.read_text()
    if source.count(before) != 1:
        raise RuntimeError(f"Изменилась структура DMS: {path}")
    target.write_text(source.replace(before, after))


replace("DMSShell.qml", "    WallpaperBackground {}", "    CosmicCenter {}\n\n    WallpaperBackground {}")
replace("Services/PopoutService.qml", "    property var controlCenterPopout: null", "    property var cosmicCenter: null\n    property var controlCenterPopout: null")
replace("Modules/DankBar/DankBarWindow.qml", "    function triggerControlCenter() {", """    function triggerControlCenter() {
        if (PopoutService.cosmicCenter) {
            PopoutService.cosmicCenter.toggle();
            return;
        }
""")
replace("Modules/DankBar/DankBarContent.qml",
        "isActive: controlCenterLoader.item ? controlCenterLoader.item.shouldBeVisible : false",
        "isActive: PopoutService.cosmicCenter ? PopoutService.cosmicCenter.shouldBeVisible : false")
replace("Modules/DankBar/DankBarContent.qml", """            onClicked: {
                controlCenterLoader.active = true;""", """            onClicked: {
                if (PopoutService.cosmicCenter) {
                    PopoutService.cosmicCenter.toggle();
                    return;
                }
                controlCenterLoader.active = true;""")

replace("Modals/Clipboard/ClipboardHistoryModal.qml",
        "modalWidth: ClipboardConstants.modalWidth",
        "modalWidth: Math.min(1120, screenWidth - 40)")
replace("Modals/Clipboard/ClipboardHistoryModal.qml",
        "modalHeight: ClipboardConstants.modalHeight",
        "modalHeight: Math.min(720, screenHeight - 80)")
replace("Modals/Clipboard/ClipboardContent.qml",
        "        id: listContainer\n",
        """        id: listContainer
        readonly property real detailWidth: parent.width >= 850 ? Math.min(510, parent.width * 0.46) : 0
""")
replace("Modals/Clipboard/ClipboardContent.qml",
        "        anchors.rightMargin: Theme.spacingM\n        anchors.bottomMargin: modal.showKeyboardHints",
        "        anchors.rightMargin: Theme.spacingM + (detailWidth > 0 ? detailWidth + Theme.spacingM : 0)\n        anchors.bottomMargin: modal.showKeyboardHints")
replace("Modals/Clipboard/ClipboardContent.qml",
        "    Loader {\n        id: keyboardHintsLoader",
        """    ClipboardDetail {
        anchors.top: listContainer.top
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingM
        anchors.bottom: listContainer.bottom
        width: listContainer.detailWidth
        visible: width > 0
        modal: clipboardContent.modal
        entry: {
            if (!visible) return null;
            const entries = modal.activeTab === "saved" ? modal.pinnedEntries : modal.unpinnedEntries;
            return entries[modal.selectedIndex] ?? null;
        }
    }

    Loader {
        id: keyboardHintsLoader""")
replace("Modals/Clipboard/ClipboardEntry.qml", "        onClicked: copyRequested()", """        onEntered: {
            ClipboardService.selectedIndex = root.itemIndex;
            ClipboardService.keyboardNavigationActive = true;
        }
        onClicked: {
            ClipboardService.selectedIndex = root.itemIndex;
            ClipboardService.keyboardNavigationActive = true;
        }
        onDoubleClicked: copyRequested()""")

# Кнопка на панели открывает то же широкое окно, что и Win + V.
bar_content = (root / "Modules/DankBar/DankBarContent.qml").read_text()
start = "            function openClipboardPopout(initialTab) {"
end = "\n            onClipboardClicked:"
if bar_content.count(start) != 1 or bar_content.count(end) != 1:
    raise RuntimeError("Изменилась кнопка истории копирования DMS")
replace("Modules/DankBar/DankBarContent.qml",
        bar_content[bar_content.index(start):bar_content.index(end)], """            function openClipboardPopout(initialTab) {
                const modal = PopoutService.clipboardHistoryModal;
                if (!modal) return;
                if (modal.shouldBeVisible && modal.activeTab === initialTab) {
                    modal.hide();
                } else {
                    modal.show();
                    modal.activeTab = initialTab || "recents";
                }
            }
""")
