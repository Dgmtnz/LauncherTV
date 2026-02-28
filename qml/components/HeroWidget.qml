import QtQuick

Item {
    id: hero

    property bool isActive: false
    property int currentCardIndex: 0

    readonly property real s: appConfig.scale

    function moveLeft() {
        if (currentCardIndex > 0) {
            currentCardIndex--;
            quickList.positionViewAtIndex(currentCardIndex, ListView.Contain);
        }
    }

    function moveRight() {
        if (currentCardIndex < quickList.count - 1) {
            currentCardIndex++;
            quickList.positionViewAtIndex(currentCardIndex, ListView.Contain);
        }
    }

    function activate() {
        let cmd = mostUsedModel.execCmdAt(currentCardIndex);
        let did = mostUsedModel.desktopIdAt(currentCardIndex);
        let wmc = mostUsedModel.wmClassAt(currentCardIndex);
        if (cmd) appLauncher.launch(cmd, did, wmc);
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 56 * hero.s
        anchors.rightMargin: 56 * hero.s
        anchors.topMargin: 36 * hero.s
        anchors.bottomMargin: 24 * hero.s
        spacing: 40 * hero.s

        // ── Clock ───────────────────────────────────────────────

        Item {
            width: parent.width * 0.26
            height: parent.height

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6 * hero.s

                Text {
                    id: timeText
                    font { pixelSize: 72 * hero.s; bold: true; family: "Sans" }
                    color: "#FFFFFF"

                    Timer {
                        running: true; repeat: true; interval: 1000
                        triggeredOnStart: true
                        onTriggered: {
                            let d = new Date();
                            timeText.text = String(d.getHours()).padStart(2, '0')
                                + ":" + String(d.getMinutes()).padStart(2, '0');
                        }
                    }
                }

                Text {
                    id: dateText
                    font { pixelSize: 18 * hero.s; family: "Sans" }
                    color: "#9AA0A6"

                    Timer {
                        running: true; repeat: true; interval: 60000
                        triggeredOnStart: true
                        onTriggered: {
                            let d = new Date();
                            let days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
                            let months = ["January","February","March","April","May","June",
                                          "July","August","September","October","November","December"];
                            dateText.text = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear();
                        }
                    }
                }
            }
        }

        // ── Weather ─────────────────────────────────────────────

        Item {
            width: parent.width * 0.20
            height: parent.height

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6 * hero.s

                Text {
                    text: weather.icon
                    font.pixelSize: 42 * hero.s
                }

                Text {
                    text: weather.temperature
                    font { pixelSize: 32 * hero.s; bold: true; family: "Sans" }
                    color: "#FFFFFF"
                }

                Text {
                    text: weather.condition
                    font { pixelSize: 15 * hero.s; family: "Sans" }
                    color: "#B0B8C1"
                }

                Text {
                    text: "Feels like " + weather.feelsLike
                    font { pixelSize: 13 * hero.s; family: "Sans" }
                    color: "#6B7280"
                }

                Text {
                    text: weather.location
                    font { pixelSize: 13 * hero.s; family: "Sans" }
                    color: "#6B7280"
                }
            }
        }

        // ── Separator ───────────────────────────────────────────

        Rectangle {
            width: 1
            height: parent.height * 0.55
            anchors.verticalCenter: parent.verticalCenter
            color: "#2A3040"
        }

        // ── Quick Launch ────────────────────────────────────────

        Item {
            width: parent.width * 0.50
            height: parent.height

            Column {
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14 * hero.s

                Text {
                    text: "QUICK LAUNCH"
                    font { pixelSize: 13 * hero.s; bold: true; family: "Sans"; letterSpacing: 1.5 }
                    color: "#6B7280"
                }

                ListView {
                    id: quickList
                    width: parent.width
                    height: 148 * hero.s
                    orientation: ListView.Horizontal
                    spacing: 14 * hero.s
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds
                    clip: false
                    cacheBuffer: 2000
                    model: mostUsedModel

                    delegate: AppCard {
                        width: 108 * hero.s
                        height: 134 * hero.s
                        appName: model.name
                        appIconSource: model.iconSource
                        isFocused: hero.isActive && (index === hero.currentCardIndex)
                        onClicked: {
                            hero.currentCardIndex = index;
                            hero.activate();
                        }
                    }

                    Behavior on contentX {
                        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    // ── Bottom separator ────────────────────────────────────────

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 56 * hero.s
        anchors.rightMargin: 56 * hero.s
        height: 1
        color: "#1F2937"
    }
}
