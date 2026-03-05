import QtQuick
import QtQuick.Controls
import QtQuick.Window

import "components"

ApplicationWindow {
    id: root

    visible: true
    visibility: Window.FullScreen
    flags: Qt.FramelessWindowHint
    color: "#000000"
    title: "LauncherTV"

    property int currentRowIndex: 0
    readonly property int totalRows: 1 + rowRepeater.count

    Timer {
        id: loadingTimeout
        interval: 8000
        onTriggered: appLauncher.loadingId = ""
    }

    Connections {
        target: appLauncher
        function onLoadingChanged() {
            if (appLauncher.loadingId !== "")
                loadingTimeout.restart();
            else
                loadingTimeout.stop();
        }
    }

    // ── Background layers ───────────────────────────────────────

    property bool bgShowA: true

    Image {
        id: bgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: root.bgShowA ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 1200 } }
    }
    Image {
        id: bgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: root.bgShowA ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 1200 } }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: appConfig.backgroundTint
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#400D1117" }
            GradientStop { position: 1.0; color: "#C0060911" }
        }
    }

    function setBackground(src) {
        if (bgShowA) bgB.source = src; else bgA.source = src;
        bgShowA = !bgShowA;
        if (appConfig.autoAccentColor) {
            appConfig.highlightColor = appConfig.colorFromImage(src);
        }
    }

    property var bgImages: []
    property int bgImageIdx: 0

    Timer {
        id: slideshowTimer
        running: root.bgImages.length > 1
        repeat: true
        interval: appConfig.slideshowInterval * 1000
        onTriggered: {
            root.bgImageIdx = (root.bgImageIdx + 1) % root.bgImages.length;
            root.setBackground(root.bgImages[root.bgImageIdx]);
        }
    }

    function reloadBackground() {
        if (appConfig.backgroundImage) {
            setBackground("file://" + appConfig.backgroundImage);
            slideshowTimer.stop();
        } else {
            bgImages = appConfig.backgroundImages();
            if (bgImages.length > 0) {
                bgImageIdx = 0;
                setBackground(bgImages[0]);
            }
        }
    }

    Connections {
        target: appConfig
        function onConfigChanged() { reloadBackground(); }
    }

    // ── Main content ────────────────────────────────────────────

    FocusScope {
        id: mainFocus
        anchors.fill: parent
        focus: true

        Flickable {
            id: mainFlickable
            anchors.fill: parent
            contentHeight: mainColumn.height + 40
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2500

            Column {
                id: mainColumn
                width: parent.width

                HeroWidget {
                    id: heroWidget
                    width: parent.width
                    height: 380 * appConfig.scale
                    isActive: root.currentRowIndex === 0 && !settingsPage.visible
                }

                Repeater {
                    id: rowRepeater
                    model: categoryModel

                    AppRow {
                        width: mainColumn.width
                        rowCategoryName: model.categoryName
                        rowAppsModel: model.appsModel
                        rowAppCount: model.appCount
                        isActiveRow: (index + 1) === root.currentRowIndex && !settingsPage.visible
                    }
                }
            }
        }

        NumberAnimation {
            id: scrollAnim
            target: mainFlickable
            property: "contentY"
            duration: 320
            easing.type: Easing.OutCubic
        }

        Keys.onPressed: function(event) {
            switch (event.key) {
            case Qt.Key_Up:
                if (root.currentRowIndex > 0) {
                    root.currentRowIndex--;
                    scrollToRow();
                }
                event.accepted = true;
                break;

            case Qt.Key_Down:
                if (root.currentRowIndex < root.totalRows - 1) {
                    root.currentRowIndex++;
                    scrollToRow();
                }
                event.accepted = true;
                break;

            case Qt.Key_Left: {
                let r = getActiveRow();
                if (r) r.moveLeft();
                event.accepted = true;
                break;
            }
            case Qt.Key_Right: {
                let r = getActiveRow();
                if (r) r.moveRight();
                event.accepted = true;
                break;
            }
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space: {
                let r = getActiveRow();
                if (r) r.activate();
                event.accepted = true;
                break;
            }
            case Qt.Key_Escape:
                event.accepted = true;
                break;
            }
        }
    }

    function getActiveRow() {
        if (currentRowIndex === 0) return heroWidget;
        return rowRepeater.itemAt(currentRowIndex - 1);
    }

    function scrollToRow() {
        let row = getActiveRow();
        if (!row) return;
        let targetY = row.y - 20;
        targetY = Math.max(0, Math.min(targetY, mainFlickable.contentHeight - mainFlickable.height));
        scrollAnim.stop();
        scrollAnim.from = mainFlickable.contentY;
        scrollAnim.to = targetY;
        scrollAnim.start();
    }

    // ── Floating settings button ────────────────────────────────

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 18
        anchors.rightMargin: 24
        width: 48; height: 48; radius: 24
        color: settingsBtn.containsMouse ? "#40FFFFFF" : "#22FFFFFF"
        z: 50
        visible: !settingsPage.visible

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: "⚙"
            font.pixelSize: 22
            color: "#CCCCCC"
        }

        MouseArea {
            id: settingsBtn
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: settingsPage.visible = true
        }
    }

    // ── Settings overlay ────────────────────────────────────────

    SettingsPage {
        id: settingsPage
        anchors.fill: parent
        visible: false
        z: 100

        onVisibleChanged: {
            if (visible) settingsPage.forceActiveFocus();
            else mainFocus.forceActiveFocus();
        }
    }

    Connections {
        target: appLauncher
        function onSettingsRequested() { settingsPage.visible = true; }
    }

    onActiveChanged: {
        if (!active) {
            appLauncher.loadingId = "";
        }
        if (active) {
            if (settingsPage.visible) settingsPage.forceActiveFocus();
            else mainFocus.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        mainFocus.forceActiveFocus();
        reloadBackground();
    }
}
