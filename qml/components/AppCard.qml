import QtQuick

Item {
    id: card

    property string appName: ""
    property string appIconSource: ""
    property bool isFocused: false

    signal clicked()

    width: 164
    height: 184

    z: isFocused ? 10 : 1

    transform: Scale {
        origin.x: card.width / 2
        origin.y: card.height / 2
        xScale: card.isFocused ? 1.08 : 1.0
        yScale: card.isFocused ? 1.08 : 1.0

        Behavior on xScale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on yScale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.fill: cardBg
        anchors.margins: -3
        radius: cardBg.radius + 3
        color: "transparent"
        border.width: card.isFocused ? 2.5 : 0
        border.color: appConfig.highlightColor
        opacity: card.isFocused ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {
        anchors.fill: cardBg
        anchors.margins: -8
        radius: cardBg.radius + 8
        color: "transparent"
        visible: card.isFocused

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: appConfig.highlightColor
            opacity: 0.08
        }
    }

    Rectangle {
        id: cardBg
        anchors.fill: parent
        radius: 12
        color: card.isFocused ? "#1C2433" : "#151A23"

        Behavior on color { ColorAnimation { duration: 200 } }

        Column {
            anchors.centerIn: parent
            spacing: card.height * 0.05

            Item {
                property real sz: Math.min(card.width, card.height) * 0.38
                width: sz; height: sz
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    anchors.fill: parent
                    source: card.appIconSource
                    sourceSize: Qt.size(64, 64)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    cache: true
                }
            }

            Text {
                width: card.width - 16
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: card.appName
                color: card.isFocused ? "#FFFFFF" : "#B0B8C1"
                font { pixelSize: Math.max(10, card.height * 0.072); family: "Sans" }
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                lineHeight: 1.1

                Behavior on color { ColorAnimation { duration: 180 } }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }
}
