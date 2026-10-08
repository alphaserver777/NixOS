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
