import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root
    required property var modal
    property var entry: null
    property string imageData: ""
    property string fullText: ""
    property string loadError: ""
    property bool loading: false
    property int requestGeneration: 0
    readonly property bool isImage: entry?.isImage ?? false
    readonly property string mimeType: entry?.mimeType || ""
    readonly property var dimensions: (entry?.preview || "").match(/(\d+)\s*[x×]\s*(\d+)/)
    radius: Theme.cornerRadius
    color: Theme.nestedSurface
    border.width: 1
    border.color: Theme.outlineMedium

    function formatSize(bytes) {
        if (bytes < 1024) return bytes + " Б";
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " КБ";
        return (bytes / 1048576).toFixed(1) + " МБ";
    }
    function resetPreview() {
        requestGeneration++;
        imageData = "";
        fullText = "";
        loadError = "";
        loading = !!entry;
        if (entry) loadDelay.restart();
        else loadDelay.stop();
    }
    onEntryChanged: resetPreview()
    Component.onCompleted: resetPreview()

    Timer {
        id: loadDelay
        interval: 90
        onTriggered: {
            const generation = root.requestGeneration;
            const id = root.entry.id;
            DMSService.sendRequest("clipboard.getEntry", {id: id}, response => {
                if (generation !== root.requestGeneration || root.entry?.id !== id)
                    return;
                root.loading = false;
                if (response.error) {
                    root.loadError = "Не удалось загрузить запись";
                    return;
                }
                const data = response.result?.data || "";
                if (root.isImage) root.imageData = data;
                else root.fullText = Qt.atob(data);
            });
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM
        RowLayout {
            Layout.fillWidth: true
            DankIcon {
                name: root.isImage ? "image" : "subject"
                color: Theme.primary
                size: 24
            }
            StyledText {
                Layout.fillWidth: true
                text: root.entry ? (root.isImage ? "Изображение" : "Текст") : "Просмотр записи"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.bold: true
            }
            DankActionButton {
                iconName: "content_copy"
                tooltipText: "Скопировать"
                enabled: !!root.entry
                onClicked: root.modal.copyEntry(root.entry)
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            Image {
                id: previewImage
                anchors.fill: parent
                visible: root.isImage && root.imageData.length > 0
                source: root.imageData ? "data:" + root.mimeType + ";base64," + root.imageData : ""
                sourceSize: Qt.size(1400, 1400)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                smooth: true
            }
            DankFlickable {
                id: previewScroll
                anchors.fill: parent
                visible: !!root.entry && !root.isImage && !root.loading
                contentWidth: width
                contentHeight: previewText.height
                TextEdit {
                    id: previewText
                    width: parent.width
                    height: Math.max(implicitHeight, previewScroll.height)
                    text: root.fullText
                    textFormat: TextEdit.PlainText
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.surface
                }
            }
            StyledText {
                anchors.centerIn: parent
                width: parent.width - 16
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: !root.entry ? "Выберите запись слева" : root.loadError ||
                    (root.loading ? "Загрузка…" : "")
                visible: !root.entry || root.loading || !!root.loadError
                color: Theme.surfaceVariantText
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: root.isImage && !!root.dimensions
            text: root.dimensions ? root.dimensions[1] + " × " + root.dimensions[2] : ""
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
        }
        StyledText {
            Layout.fillWidth: true
            visible: !!root.entry
            text: root.entry ? root.formatSize(root.entry.size || 0) + "  ·  " + root.mimeType : ""
            wrapMode: Text.Wrap
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
        }
        StyledText {
            Layout.fillWidth: true
            visible: !!root.entry?.timestamp
            text: root.entry?.timestamp ? Qt.formatDateTime(new Date(root.entry.timestamp), "dd.MM.yyyy HH:mm") : ""
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
        }
        StyledText {
            Layout.fillWidth: true
            text: "↑ ↓ — выбор     Enter — скопировать"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }
    }
}
