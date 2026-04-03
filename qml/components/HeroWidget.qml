import QtQuick
import QtQuick.Layouts

Item {
    id: hero

    property bool isActive: false
    property int currentCardIndex: 0

    readonly property real s: appConfig.scale

    property var forecastDays: []

    function syncForecast() {
        try {
            forecastDays = JSON.parse(weather.forecastJson || "[]");
        } catch (e) {
            forecastDays = [];
        }
        trendCanvas.requestPaint();
    }

    Connections {
        target: weather
        function onWeatherChanged() { hero.syncForecast(); }
    }

    Connections {
        target: appConfig
        function onConfigChanged() { trendCanvas.requestPaint(); }
    }

    Component.onCompleted: hero.syncForecast()

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
        id: heroRow
        anchors.fill: parent
        anchors.leftMargin: 144 * hero.s
        anchors.rightMargin: 48 * hero.s
        anchors.topMargin: 28 * hero.s
        anchors.bottomMargin: 20 * hero.s

        readonly property real gap: 28 * hero.s
        spacing: gap

        // ── Vertical clock + date ───────────────────────────────

        Item {
            id: clockCol
            width: 140 * hero.s
            height: parent.height

            Column {
                anchors.centerIn: parent
                spacing: -14 * hero.s

                Text {
                    id: dateLine
                    anchors.horizontalCenter: parent.horizontalCenter
                    font { pixelSize: 19 * hero.s; family: "Sans" }
                    color: "#E8E4DC"
                    bottomPadding: 12 * hero.s

                    Timer {
                        running: true; repeat: true; interval: 60000
                        triggeredOnStart: true
                        onTriggered: {
                            let d = new Date();
                            let days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
                            let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
                            dateLine.text = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
                        }
                    }
                }

                Text {
                    id: hoursBlock
                    anchors.horizontalCenter: parent.horizontalCenter
                    font { pixelSize: 96 * hero.s; bold: true; family: "Sans" }
                    color: "#F5F0E6"

                    Timer {
                        running: true; repeat: true; interval: 1000
                        triggeredOnStart: true
                        onTriggered: {
                            let d = new Date();
                            hoursBlock.text = String(d.getHours()).padStart(2, "0");
                        }
                    }
                }

                Text {
                    id: minsBlock
                    anchors.horizontalCenter: parent.horizontalCenter
                    font { pixelSize: 96 * hero.s; bold: true; family: "Sans" }
                    color: "#F5F0E6"

                    Timer {
                        running: true; repeat: true; interval: 1000
                        triggeredOnStart: true
                        onTriggered: {
                            let d = new Date();
                            minsBlock.text = String(d.getMinutes()).padStart(2, "0");
                        }
                    }
                }
            }
        }

        // ── Weather (transparent, split top/bottom) ─────────────

        Item {
            id: wxCard
            readonly property real wxPad: 16 * hero.s
            width: Math.min(heroRow.width * 0.36, heroRow.width - clockCol.width - quickLaunchCol.width - 2 * heroRow.gap)
            height: parent.height

            // ── Top: current weather ────────────────────────────
            Item {
                id: wxTop
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: wxCard.wxPad
                anchors.rightMargin: wxCard.wxPad
                height: parent.height * 0.42

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    spacing: 10 * hero.s

                    Text {
                        text: weather.icon
                        font.pixelSize: 72 * hero.s
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: weather.temperature
                            font { pixelSize: 51 * hero.s; bold: true; family: "Sans" }
                            color: "#FFFFFF"
                        }

                        Text {
                            text: weather.condition
                            font { pixelSize: 18 * hero.s; family: "Sans" }
                            color: "#B0B8C1"
                        }
                    }

                    Text {
                        text: weather.location || "—"
                        font { pixelSize: 33 * hero.s; bold: true; family: "Sans" }
                        color: "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        width: Math.min(implicitWidth, wxTop.width * 0.48)
                    }
                }
            }

            // ── Bottom: 5-day forecast ──────────────────────────
            Item {
                id: forecastWrap
                anchors.top: wxTop.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: wxCard.wxPad
                anchors.rightMargin: wxCard.wxPad

                Canvas {
                    id: trendCanvas
                    anchors.fill: parent
                    property real strokeW: Math.max(2.5, 3 * hero.s)

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        if (!ctx) return;
                        ctx.clearRect(0, 0, width, height);
                        var days = hero.forecastDays;
                        if (!days || days.length < 2) return;

                        var w = width;
                        var h = height;
                        var padX = w / (days.length * 2);
                        var padTop = 10 * hero.s;
                        var padBot = 10 * hero.s;
                        var drawH = Math.max(16, h - padTop - padBot);

                        var maxTs = [];
                        for (var i = 0; i < days.length; i++) maxTs.push(days[i].max);
                        var gmin = Math.min.apply(null, maxTs);
                        var gmax = Math.max.apply(null, maxTs);
                        var range = gmax - gmin;
                        var minRange = 10;
                        if (range < minRange) {
                            var mid = (gmin + gmax) / 2;
                            gmin = mid - minRange / 2;
                            gmax = mid + minRange / 2;
                        }

                        var n = days.length;
                        var xs = [], ys = [];
                        for (var i = 0; i < n; i++) {
                            var t = (n > 1) ? (i / (n - 1)) : 0.5;
                            xs.push(padX + t * (w - 2 * padX));
                            var norm = (days[i].max - gmin) / (gmax - gmin);
                            ys.push(padTop + (1 - norm) * drawH);
                        }

                        ctx.strokeStyle = appConfig.highlightColor;
                        ctx.lineWidth = trendCanvas.strokeW;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.globalAlpha = 0.35;
                        ctx.beginPath();
                        ctx.moveTo(xs[0], ys[0]);
                        for (var j = 0; j < n - 1; j++) {
                            var xc = (xs[j] + xs[j + 1]) / 2;
                            var yc = (ys[j] + ys[j + 1]) / 2;
                            ctx.quadraticCurveTo(xs[j], ys[j], xc, yc);
                        }
                        ctx.quadraticCurveTo(xs[n - 1], ys[n - 1], xs[n - 1], ys[n - 1]);
                        ctx.stroke();
                        ctx.globalAlpha = 1;
                    }
                }

                Row {
                    anchors.fill: parent
                    z: 1
                    spacing: 0

                    Repeater {
                        model: 5

                        Item {
                            readonly property var d: index < hero.forecastDays.length ? hero.forecastDays[index] : null
                            width: forecastWrap.width / 5
                            height: forecastWrap.height

                            Column {
                                anchors.centerIn: parent
                                spacing: 3 * hero.s

                                Text {
                                    width: parent.parent.width
                                    text: d ? d.icon : "—"
                                    font.pixelSize: 30 * hero.s
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    width: parent.parent.width
                                    text: d ? (d.min + "/" + d.max + "°C") : "—"
                                    font { pixelSize: 17 * hero.s; bold: true; family: "Sans" }
                                    horizontalAlignment: Text.AlignHCenter
                                    color: "#FFFFFF"
                                }

                                Text {
                                    width: parent.parent.width
                                    text: d ? (d.rain + "%") : "—"
                                    font.pixelSize: 15 * hero.s
                                    horizontalAlignment: Text.AlignHCenter
                                    color: "#9AA0A6"
                                }

                                Text {
                                    width: parent.parent.width
                                    text: d ? d.abbr : ""
                                    font { pixelSize: 18 * hero.s; bold: true; family: "Sans" }
                                    horizontalAlignment: Text.AlignHCenter
                                    color: "#FFFFFF"
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Quick launch ──────────────────────────────────────────

        Item {
            id: quickLaunchCol
            width: Math.max(80 * hero.s, heroRow.width - clockCol.width - wxCard.width - 2 * heroRow.gap)
            height: parent.height

            Column {
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12 * hero.s

                Text {
                    text: "QUICK LAUNCH"
                    font { pixelSize: 12 * hero.s; bold: true; family: "Sans"; letterSpacing: 1.5 }
                    color: "#6B7280"
                }

                ListView {
                    id: quickList
                    width: parent.width
                    height: 136 * hero.s
                    orientation: ListView.Horizontal
                    spacing: 12 * hero.s
                    interactive: true
                    boundsBehavior: Flickable.StopAtBounds
                    clip: false
                    cacheBuffer: 2000
                    model: mostUsedModel

                    delegate: AppCard {
                        width: 104 * hero.s
                        height: 128 * hero.s
                        appName: model.name
                        appIconSource: model.iconSource
                        isFocused: hero.isActive && (index === hero.currentCardIndex)
                        isLoading: model.desktopId === appLauncher.loadingId
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

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 72 * hero.s
        anchors.rightMargin: 48 * hero.s
        height: 1
        color: "#1F2937"
    }
}
