import QtQuick

Item {
    id: row

    property string rowCategoryName: ""
    property var rowAppsModel: null
    property int rowAppCount: 0
    property bool isActiveRow: false
    property int currentCardIndex: 0

    readonly property real s: appConfig.scale

    height: 240 * s

    function moveLeft() {
        if (currentCardIndex > 0) {
            currentCardIndex--;
            cardList.positionViewAtIndex(currentCardIndex, ListView.Contain);
        }
    }

    function moveRight() {
        if (currentCardIndex < rowAppCount - 1) {
            currentCardIndex++;
            cardList.positionViewAtIndex(currentCardIndex, ListView.Contain);
        }
    }

    function activate() {
        if (rowAppsModel === null || currentCardIndex < 0) return;
        let cmd = rowAppsModel.execCmdAt(currentCardIndex);
        let did = rowAppsModel.desktopIdAt(currentCardIndex);
        if (cmd) appLauncher.launch(cmd, did);
    }

    Text {
        id: categoryLabel
        anchors.left: parent.left
        anchors.leftMargin: 56 * row.s
        anchors.top: parent.top
        anchors.topMargin: 4 * row.s

        text: row.rowCategoryName
        color: row.isActiveRow ? "#E8EAED" : "#6B7280"
        font { pixelSize: 18 * row.s; bold: true; family: "Sans"; capitalization: Font.AllUppercase; letterSpacing: 1.2 }

        Behavior on color { ColorAnimation { duration: 200 } }
    }

    ListView {
        id: cardList
        anchors.top: categoryLabel.bottom
        anchors.topMargin: 10 * row.s
        anchors.left: parent.left
        anchors.leftMargin: 52 * row.s
        anchors.right: parent.right
        anchors.rightMargin: 52 * row.s
        height: 200 * row.s

        orientation: ListView.Horizontal
        spacing: 18 * row.s
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        clip: false
        cacheBuffer: 3000

        model: row.rowAppsModel

        delegate: AppCard {
            width: 164 * row.s
            height: 184 * row.s
            appName: model.name
            appIconSource: model.iconSource
            isFocused: row.isActiveRow && (index === row.currentCardIndex)
            onClicked: {
                row.currentCardIndex = index;
                row.activate();
            }
        }

        highlightFollowsCurrentItem: false

        Behavior on contentX {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
    }
}
