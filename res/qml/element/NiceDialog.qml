pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // 关默认背景
    padding: 0
    background: null

    // ===== 对外 API =====
    property alias title: titleLabel.text
    property alias text: bodyLabel.text
    property url   iconSource: ""
    property string primaryText: qsTr("OK")
    property string secondaryText: ""
    property string tertiaryText: ""
    signal tertiaryClicked()
    property bool destructive: false
    signal accepted()
    signal rejected()

    // 遮罩颜色（可调）。默认：普通灰；危险态：红。
    property color overlayColorNormal: Qt.rgba(0, 0, 0, 0.35)
    property color overlayColorDestructive: Qt.rgba(0.86, 0.12, 0.12, 0.30)

    // 尺寸 & 居中
    readonly property int margin: 24
    readonly property int availW: (Overlay.overlay ? Overlay.overlay.width  : (parent ? parent.width  : 600))
    readonly property int availH: (Overlay.overlay ? Overlay.overlay.height : (parent ? parent.height : 400))
    property int maxWidth: 420
    width: Math.min(maxWidth, root.availW - 2*root.margin)
    x: Math.max(root.margin, Math.round((root.availW - width)  / 2))
    y: Math.max(root.margin, Math.round((root.availH - height) / 2))

    // ── 遮罩：按 destructive 切换红/灰，并带平滑过渡 ──
    Overlay.modal: Rectangle {
        color: root.destructive ? root.overlayColorDestructive : root.overlayColorNormal
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    // 单层内容卡片
    contentItem: Item {
        id: rootContent
        property int gutter: 20
        implicitWidth:  contentCol.implicitWidth  + rootContent.gutter*2
        implicitHeight: contentCol.implicitHeight + rootContent.gutter*2
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: root.palette.window
            border.color: Qt.alpha(Qt.darker(color, 1.2), 0.25)
            layer.enabled: true
            layer.samples: 4
            layer.smooth: true
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: rootContent.gutter
            spacing: 14

            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                // 图标容器：在布局里用 implicitWidth/Height
                Item {
                    implicitWidth:  (icon.status === Image.Ready) ? 40 : 0
                    implicitHeight: 40
                    visible: icon.status === Image.Ready

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Qt.rgba(root.palette.accent.r,
                                       root.palette.accent.g,
                                       root.palette.accent.b, 0.12)
                    }
                    Image {
                        id: icon
                        anchors.centerIn: parent
                        source: root.iconSource
                        width: 22; height: 22
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        id: titleLabel
                        text: qsTr("Title")
                        font.bold: true
                        font.pixelSize: 18
                        wrapMode: Label.Wrap
                        Layout.fillWidth: true
                    }
                    Label {
                        id: bodyLabel
                        text: qsTr("Message")
                        opacity: 0.85
                        wrapMode: Label.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            // 按钮区
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Item { Layout.fillWidth: true }

                Button {
                    visible: root.secondaryText.length > 0
                    text: root.secondaryText
                    onClicked: { root.rejected(); root.close() }
                }

                Button {
                    visible: root.tertiaryText.length > 0
                    text: root.tertiaryText
                    onClicked: { root.tertiaryClicked(); root.close() }
                }

                Button {
                    id: primaryBtn
                    text: root.primaryText
                    font.bold: true
                    onClicked: { root.accepted(); root.close() }
                    palette.buttonText: root.destructive ? "white" : undefined
                    palette.button:     root.destructive ? "#d9363e" : undefined
                }
            }
        }
    }

    // 动画
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
        ScaleAnimator { target: root.contentItem; from: 0.96; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120; easing.type: Easing.InQuad }
        ScaleAnimator { target: root.contentItem; from: 1.0; to: 0.98; duration: 120; easing.type: Easing.InQuad }
    }
}
