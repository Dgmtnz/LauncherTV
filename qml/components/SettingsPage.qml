import QtQuick
import QtQuick.Dialogs

FocusScope {
    id: page

    property int currentIdx: 0
    readonly property int itemCount: 10
    property bool editing: false

    readonly property var presetColors: [
        "#5EB8FF", "#4DFFF3", "#69FF94", "#B388FF",
        "#FF8A65", "#FF80AB", "#FFD54F", "#FFFFFF"
    ]
    property int colorIdx: 0

    onVisibleChanged: {
        if (visible) {
            currentIdx = 0;
            editing = false;
            colorIdx = Math.max(0, presetColors.indexOf(appConfig.highlightColor));
        }
    }

    // ── Backdrop ────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.82

        MouseArea {
            anchors.fill: parent
            onClicked: page.visible = false
        }
    }

    // ── Panel ───────────────────────────────────────────────────

    Rectangle {
        id: panel
        width: parent.width * 0.52
        height: parent.height * 0.88
        anchors.centerIn: parent
        color: "#141820"
        radius: 18
        border.width: 1
        border.color: "#232A38"

        MouseArea { anchors.fill: parent }

        // Title
        Text {
            id: titleText
            anchors.top: parent.top
            anchors.topMargin: 28
            anchors.horizontalCenter: parent.horizontalCenter
            text: "⚙  Settings"
            font { pixelSize: 24; bold: true; family: "Sans" }
            color: "#E8EAED"
        }

        // Close button
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 18
            anchors.rightMargin: 22
            width: 36; height: 36; radius: 18
            color: closeBtn.containsMouse ? "#30FFFFFF" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                font { pixelSize: 18; family: "Sans" }
                color: "#6B7280"
            }

            MouseArea {
                id: closeBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.visible = false
            }
        }

        // Scrollable settings area
        Flickable {
            id: settingsFlick
            anchors.top: titleText.bottom
            anchors.topMargin: 24
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: hintText.top
            anchors.bottomMargin: 8
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            contentHeight: settingsCol.height + 20
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds

            Behavior on contentY {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Column {
                id: settingsCol
                width: settingsFlick.width
                spacing: 4

                // ── APPEARANCE ──────────────────────────────────
                SectionHeader { text: "APPEARANCE" }

                // 0: Scale
                SettingItem {
                    id: item0
                    isFocused: page.currentIdx === 0
                    label: "UI Scale"
                    itemIndex: 0

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        spacing: 10

                        Item {
                            width: 20; height: 30
                            Text { anchors.centerIn: parent; text: "◀"; font.pixelSize: 14; color: item0.isFocused ? appConfig.highlightColor : "#4B5563" }
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: { page.currentIdx = 0; page.adjustValue(-1); } }
                        }

                        Rectangle {
                            width: 120; height: 5; radius: 2; color: "#3A4050"
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                width: parent.width * Math.max(0, (appConfig.scale - 0.5) / 1.5)
                                height: parent.height; radius: 2; color: appConfig.highlightColor
                            }
                        }

                        Text {
                            text: appConfig.scale.toFixed(2); font.pixelSize: 14; color: "#E8EAED"
                            width: 34; anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            width: 20; height: 30
                            Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 14; color: item0.isFocused ? appConfig.highlightColor : "#4B5563" }
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: { page.currentIdx = 0; page.adjustValue(1); } }
                        }
                    }
                }

                // 1: Accent Color
                SettingItem {
                    id: item1
                    isFocused: page.currentIdx === 1
                    label: "Accent Color"
                    itemIndex: 1
                    height: 90

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        spacing: 8

                        Row {
                            anchors.right: parent.right
                            spacing: 6

                            Repeater {
                                model: page.presetColors.length
                                Rectangle {
                                    width: 20; height: 20; radius: 10
                                    color: page.presetColors[index]
                                    border.width: (!appConfig.autoAccentColor && index === page.colorIdx) ? 3 : 1
                                    border.color: (!appConfig.autoAccentColor && index === page.colorIdx) ? "#FFFFFF" : "#3A4050"
                                    scale: (!appConfig.autoAccentColor && index === page.colorIdx) ? 1.25 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 150 } }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -3
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            page.currentIdx = 1;
                                            appConfig.autoAccentColor = false;
                                            page.colorIdx = index;
                                            appConfig.highlightColor = page.presetColors[index];
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            spacing: 8

                            Rectangle {
                                width: 26; height: 26; radius: 4
                                color: appConfig.highlightColor
                                border.width: 1; border.color: "#3A4050"
                            }

                            Rectangle {
                                width: 110; height: 26; radius: 6
                                color: "#232A38"
                                border.width: (page.editing && page.currentIdx === 1) ? 1 : 0
                                border.color: appConfig.highlightColor

                                TextInput {
                                    id: hexInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    font { pixelSize: 13; family: "Monospace" }
                                    color: "#E8EAED"
                                    clip: true
                                    text: appConfig.highlightColor
                                    focus: page.editing && page.currentIdx === 1
                                    selectByMouse: true
                                    maximumLength: 7

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.IBeamCursor
                                        onClicked: {
                                            page.currentIdx = 1;
                                            page.editing = true;
                                            hexInput.forceActiveFocus();
                                        }
                                    }

                                    Keys.onReturnPressed: {
                                        let hex = text.trim();
                                        if (/^#[0-9a-fA-F]{6}$/.test(hex)) {
                                            appConfig.autoAccentColor = false;
                                            appConfig.highlightColor = hex;
                                            page.colorIdx = page.presetColors.indexOf(hex);
                                        }
                                        page.editing = false;
                                        page.forceActiveFocus();
                                    }
                                    Keys.onEscapePressed: {
                                        text = appConfig.highlightColor;
                                        page.editing = false;
                                        page.forceActiveFocus();
                                    }
                                }

                                Connections {
                                    target: appConfig
                                    function onConfigChanged() {
                                        if (!hexInput.activeFocus)
                                            hexInput.text = appConfig.highlightColor;
                                    }
                                }
                            }

                            Rectangle {
                                width: autoLabel.width + 20; height: 26; radius: 6
                                color: appConfig.autoAccentColor
                                    ? Qt.rgba(Qt.color(appConfig.highlightColor).r,
                                              Qt.color(appConfig.highlightColor).g,
                                              Qt.color(appConfig.highlightColor).b, 0.25)
                                    : (autoBtn.containsMouse ? "#2A3440" : "#1E2636")
                                border.width: 1
                                border.color: appConfig.autoAccentColor ? appConfig.highlightColor : "#3A4050"

                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                Text {
                                    id: autoLabel
                                    anchors.centerIn: parent
                                    text: appConfig.autoAccentColor ? "Auto ✓" : "Auto"
                                    font { pixelSize: 12; family: "Sans" }
                                    color: appConfig.autoAccentColor ? appConfig.highlightColor : "#9AA0A6"
                                }

                                MouseArea {
                                    id: autoBtn
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        page.currentIdx = 1;
                                        if (!appConfig.autoAccentColor) {
                                            appConfig.autoAccentColor = true;
                                            let c = appConfig.averageBackgroundColor();
                                            appConfig.highlightColor = c;
                                            page.colorIdx = -1;
                                        } else {
                                            appConfig.autoAccentColor = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 2: Background Tint
                SettingItem {
                    id: item2
                    isFocused: page.currentIdx === 2
                    label: "Background Tint"
                    itemIndex: 2

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        spacing: 10

                        Item {
                            width: 20; height: 30
                            Text { anchors.centerIn: parent; text: "◀"; font.pixelSize: 14; color: item2.isFocused ? appConfig.highlightColor : "#4B5563" }
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: { page.currentIdx = 2; page.adjustValue(-1); } }
                        }

                        Rectangle {
                            width: 120; height: 5; radius: 2; color: "#3A4050"
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                width: parent.width * appConfig.backgroundTint
                                height: parent.height; radius: 2; color: appConfig.highlightColor
                            }
                        }

                        Text {
                            text: Math.round(appConfig.backgroundTint * 100) + "%"
                            font.pixelSize: 14; color: "#E8EAED"; width: 38
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            width: 20; height: 30
                            Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 14; color: item2.isFocused ? appConfig.highlightColor : "#4B5563" }
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: { page.currentIdx = 2; page.adjustValue(1); } }
                        }
                    }
                }

                // ── WALLPAPER ───────────────────────────────────
                SectionHeader { text: "WALLPAPER" }

                // 3: Background Image
                SettingItem {
                    id: item3
                    isFocused: page.currentIdx === 3
                    label: "Background Image"
                    itemIndex: 3

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        spacing: 8

                        Text {
                            width: settingsCol.width * 0.38
                            horizontalAlignment: Text.AlignRight
                            text: appConfig.backgroundImage || "Not set  ⏎ Browse"
                            font { pixelSize: 13; family: "Sans" }
                            color: appConfig.backgroundImage ? "#9AA0A6" : "#4B5563"
                            elide: Text.ElideMiddle
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    page.currentIdx = 3;
                                    imageDialog.open();
                                }
                            }
                        }

                        Rectangle {
                            visible: appConfig.backgroundImage !== ""
                            width: 26; height: 26; radius: 13
                            color: clearImgBtn.containsMouse ? "#40FFFFFF" : "#25FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font { pixelSize: 11; family: "Sans" }
                                color: "#9AA0A6"
                            }

                            MouseArea {
                                id: clearImgBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    page.currentIdx = 3;
                                    appConfig.backgroundImage = "";
                                }
                            }
                        }
                    }
                }

                // 4: Image Folder
                SettingItem {
                    id: item4
                    isFocused: page.currentIdx === 4
                    label: "Image Folder"
                    itemIndex: 4

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        spacing: 8

                        Text {
                            width: settingsCol.width * 0.38
                            horizontalAlignment: Text.AlignRight
                            text: appConfig.backgroundFolder || "Not set  ⏎ Browse"
                            font { pixelSize: 13; family: "Sans" }
                            color: appConfig.backgroundFolder ? "#9AA0A6" : "#4B5563"
                            elide: Text.ElideMiddle
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    page.currentIdx = 4;
                                    folderDialog.open();
                                }
                            }
                        }

                        Rectangle {
                            visible: appConfig.backgroundFolder !== ""
                            width: 26; height: 26; radius: 13
                            color: clearFolderBtn.containsMouse ? "#40FFFFFF" : "#25FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font { pixelSize: 11; family: "Sans" }
                                color: "#9AA0A6"
                            }

                            MouseArea {
                                id: clearFolderBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    page.currentIdx = 4;
                                    appConfig.backgroundFolder = "";
                                }
                            }
                        }
                    }
                }

                // 5: Slideshow Interval
                SettingItem {
                    id: item5
                    isFocused: page.currentIdx === 5
                    label: "Slideshow Interval"
                    itemIndex: 5

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        spacing: 10

                        Item {
                            width: 20; height: 30
                            Text { anchors.centerIn: parent; text: "◀"; font.pixelSize: 14; color: item5.isFocused ? appConfig.highlightColor : "#4B5563" }
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: { page.currentIdx = 5; page.adjustValue(-1); } }
                        }

                        Rectangle {
                            width: 120; height: 5; radius: 2; color: "#3A4050"
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                width: parent.width * ((appConfig.slideshowInterval - 10) / 290)
                                height: parent.height; radius: 2; color: appConfig.highlightColor
                            }
                        }

                        Text {
                            text: appConfig.slideshowInterval + "s"
                            font.pixelSize: 14; color: "#E8EAED"; width: 38
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            width: 20; height: 30
                            Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 14; color: item5.isFocused ? appConfig.highlightColor : "#4B5563" }
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: { page.currentIdx = 5; page.adjustValue(1); } }
                        }
                    }
                }

                // ── SYSTEM ──────────────────────────────────────
                SectionHeader { text: "SYSTEM" }

                // 6: Weather Location
                SettingItem {
                    id: item6
                    isFocused: page.currentIdx === 6
                    label: "Weather Location"
                    itemIndex: 6

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        width: parent.width * 0.4
                        height: parent.height

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            visible: !page.editing || page.currentIdx !== 6
                            text: appConfig.weatherLocation || "Auto-detect  ⏎ Edit"
                            font { pixelSize: 13; family: "Sans" }
                            color: appConfig.weatherLocation ? "#9AA0A6" : "#4B5563"
                        }

                        Rectangle {
                            visible: page.editing && page.currentIdx === 6
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            width: parent.width
                            height: 30
                            radius: 6
                            color: "#232A38"
                            border.width: 1
                            border.color: appConfig.highlightColor

                            TextInput {
                                id: locationInput
                                anchors.fill: parent
                                anchors.margins: 6
                                font { pixelSize: 14; family: "Sans" }
                                color: "#FFFFFF"
                                clip: true
                                focus: page.editing && page.currentIdx === 6

                                Keys.onReturnPressed: {
                                    appConfig.weatherLocation = text;
                                    weather.setLocation(text);
                                    page.editing = false;
                                    page.forceActiveFocus();
                                }
                                Keys.onEscapePressed: {
                                    page.editing = false;
                                    page.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // 7: Autostart
                SettingItem {
                    id: item7
                    isFocused: page.currentIdx === 7
                    label: "Auto-start with LXQt"
                    itemIndex: 7

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        width: 48; height: 26; radius: 13
                        color: appConfig.isAutostart ? appConfig.highlightColor : "#3A4050"
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 22; height: 22; radius: 11; color: "#FFFFFF"
                            x: appConfig.isAutostart ? 24 : 2; y: 2
                            Behavior on x { NumberAnimation { duration: 200 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                page.currentIdx = 7;
                                appConfig.setAutostart(!appConfig.isAutostart);
                            }
                        }
                    }
                }

                // 8: Grab Home Key
                SettingItem {
                    id: item8
                    isFocused: page.currentIdx === 8
                    label: "Override Menu key"
                    itemIndex: 8

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: appConfig.grabHomeKey ? "Dedicated Home key" : "Normal context menu"
                            font { pixelSize: 12; family: "Sans" }
                            color: "#6B7280"
                        }

                        Rectangle {
                            width: 48; height: 26; radius: 13
                            color: appConfig.grabHomeKey ? appConfig.highlightColor : "#3A4050"
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 22; height: 22; radius: 11; color: "#FFFFFF"
                                x: appConfig.grabHomeKey ? 24 : 2; y: 2
                                Behavior on x { NumberAnimation { duration: 200 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    page.currentIdx = 8;
                                    appConfig.grabHomeKey = !appConfig.grabHomeKey;
                                }
                            }
                        }
                    }
                }

                // ── ABOUT ───────────────────────────────────────
                SectionHeader { text: "ABOUT" }

                // 9: About info
                Rectangle {
                    id: item9
                    width: parent.width
                    height: 90
                    radius: 10
                    color: page.currentIdx === 9 ? "#1E2636" : "transparent"
                    border.width: page.currentIdx === 9 ? 1 : 0
                    border.color: appConfig.highlightColor

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "LauncherTV  v1.0"
                            font { pixelSize: 16; bold: true; family: "Sans" }
                            color: "#E8EAED"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "Diego Martinez Fernandez"
                            font { pixelSize: 14; family: "Sans" }
                            color: "#9AA0A6"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "@Dgmtnz  ·  github.com/Dgmtnz"
                            font { pixelSize: 13; family: "Sans" }
                            color: "#6B7280"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }

        // Hint bar
        Text {
            id: hintText
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            text: "↑↓ Navigate   ←→ Adjust   ⏎ Select   Esc Back"
            font { pixelSize: 12; family: "Sans" }
            color: "#4B5563"
        }
    }

    // ── Dialogs ─────────────────────────────────────────────────

    FileDialog {
        id: imageDialog
        title: "Select Background Image"
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp *.bmp)"]
        onAccepted: {
            let p = selectedFile.toString();
            if (p.startsWith("file://")) p = p.substring(7);
            appConfig.backgroundImage = p;
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Select Image Folder"
        onAccepted: {
            let p = selectedFolder.toString();
            if (p.startsWith("file://")) p = p.substring(7);
            appConfig.backgroundFolder = p;
        }
    }

    // ── Key handling ────────────────────────────────────────────

    Keys.onPressed: function(event) {
        if (page.editing) return;

        switch (event.key) {
        case Qt.Key_Escape:
            page.visible = false;
            event.accepted = true;
            break;

        case Qt.Key_Up:
            if (currentIdx > 0) { currentIdx--; ensureVisible(); }
            event.accepted = true;
            break;

        case Qt.Key_Down:
            if (currentIdx < itemCount - 1) { currentIdx++; ensureVisible(); }
            event.accepted = true;
            break;

        case Qt.Key_Left:
            adjustValue(-1);
            event.accepted = true;
            break;

        case Qt.Key_Right:
            adjustValue(1);
            event.accepted = true;
            break;

        case Qt.Key_Return:
        case Qt.Key_Enter:
            activateItem();
            event.accepted = true;
            break;
        }
    }

    function adjustValue(dir) {
        switch (currentIdx) {
        case 0: appConfig.scale = appConfig.scale + dir * 0.05; break;
        case 1:
            appConfig.autoAccentColor = false;
            colorIdx = (colorIdx + dir + presetColors.length) % presetColors.length;
            appConfig.highlightColor = presetColors[colorIdx];
            break;
        case 2: appConfig.backgroundTint = appConfig.backgroundTint + dir * 0.05; break;
        case 3: if (dir < 0) appConfig.backgroundImage = ""; break;
        case 4: if (dir < 0) appConfig.backgroundFolder = ""; break;
        case 5: appConfig.slideshowInterval = appConfig.slideshowInterval + dir * 5; break;
        case 7: appConfig.setAutostart(!appConfig.isAutostart); break;
        case 8: appConfig.grabHomeKey = !appConfig.grabHomeKey; break;
        }
    }

    function activateItem() {
        switch (currentIdx) {
        case 1:
            page.editing = true;
            hexInput.text = appConfig.highlightColor;
            hexInput.forceActiveFocus();
            hexInput.selectAll();
            break;
        case 3: imageDialog.open(); break;
        case 4: folderDialog.open(); break;
        case 6:
            page.editing = true;
            locationInput.text = appConfig.weatherLocation;
            locationInput.forceActiveFocus();
            break;
        case 7: appConfig.setAutostart(!appConfig.isAutostart); break;
        case 8: appConfig.grabHomeKey = !appConfig.grabHomeKey; break;
        }
    }

    function ensureVisible() {
        let items = [item0, item1, item2, item3, item4, item5, item6, item7, item8, item9];
        if (currentIdx < 0 || currentIdx >= items.length) return;
        let item = items[currentIdx];
        let y = item.y;
        let h = item.height;
        if (y < settingsFlick.contentY + 10)
            settingsFlick.contentY = Math.max(0, y - 10);
        else if (y + h > settingsFlick.contentY + settingsFlick.height - 10)
            settingsFlick.contentY = y + h - settingsFlick.height + 10;
    }

    // ── Inline helper components ────────────────────────────────

    component SectionHeader: Text {
        width: parent ? parent.width : 100
        topPadding: 14
        bottomPadding: 6
        font { pixelSize: 11; bold: true; family: "Sans"; letterSpacing: 1.8 }
        color: "#4B5563"
    }

    component SettingItem: Rectangle {
        property bool isFocused: false
        property string label: ""
        property int itemIndex: -1
        default property alias controlContent: controlArea.children

        width: parent ? parent.width : 100
        height: 52
        radius: 10
        color: isFocused ? "#1E2636" : "transparent"
        border.width: isFocused ? 1 : 0
        border.color: appConfig.highlightColor

        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                page.currentIdx = parent.itemIndex;
                page.activateItem();
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            font { pixelSize: 15; family: "Sans" }
            color: parent.isFocused ? "#E8EAED" : "#9AA0A6"
        }

        Item {
            id: controlArea
            anchors.fill: parent
        }
    }
}
