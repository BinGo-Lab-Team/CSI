// NiceDialog.qml - 自绘弹窗组件
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Popup {
    id: root
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    transformOrigin: Item.Center

    // 屏幕 DPR
    property real dpr: Screen.devicePixelRatio

    // ===== API =====
    property alias  title: titleLabel.text
    property alias  text:  bodyLabel.text
    property url    iconSource: ""
    property string primaryText:   qsTr("OK")
    property string secondaryText: ""
    property string tertiaryText:  ""
    property bool   destructive: false
    signal accepted()
    signal rejected()
    signal tertiaryClicked()

    // ===== 遮罩外观 & 覆盖逻辑 =====
    property int  overlayInset: 18
    property int  overlayCornerRadius: 12
    property bool overlaySquareCorners: false
    property color overlayColorNormal:      Qt.rgba(0, 0, 0, 0.35)
    property color overlayColorDestructive: Qt.rgba(0.86, 0.12, 0.12, 0.30)

    // 全屏/最大化 时遮罩整窗覆盖
    property bool overlayForceFullCover: false
    Item { id: __probe; visible: false }
    property var _win: __probe.Window.window
    readonly property bool _autoCoverFull:
        _win && (_win.visibility === Window.Maximized || _win.visibility === Window.FullScreen)
    readonly property bool _coverFull: overlayForceFullCover || _autoCoverFull

    // ===== 像素对齐 =====
    property int centerInsetLeft:   overlayInset
    property int centerInsetTop:    overlayInset
    property int centerInsetRight:  overlayInset
    property int centerInsetBottom: overlayInset
    property int centerYOffset: -20

    readonly property int availW: (Overlay.overlay ? Overlay.overlay.width  : (parent ? parent.width  : 600))
    readonly property int availH: (Overlay.overlay ? Overlay.overlay.height : (parent ? parent.height : 400))
    readonly property int _leftInset:   _coverFull ? 0 : centerInsetLeft
    readonly property int _topInset:    _coverFull ? 0 : centerInsetTop
    readonly property int _rightInset:  _coverFull ? 0 : centerInsetRight
    readonly property int _bottomInset: _coverFull ? 0 : centerInsetBottom

    property Item overlayDimItem: null

    property int maxWidth: 420
    readonly property int _idealW: Math.min(maxWidth, (availW - _leftInset - _rightInset) - 48)
    width: Math.max(1, Math.round(_idealW))
    x: _leftInset + Math.max(24, Math.round(((availW - _leftInset - _rightInset) - width) / 2))
    y: _topInset + Math.max(24, Math.round(((availH - _topInset - _bottomInset) - height) / 2)) + centerYOffset

    // ===== 遮罩 =====
    Overlay.modal: Item {
        anchors.fill: parent
        Rectangle {
            id: overlayDim
            anchors.fill: parent
            anchors.margins: root._coverFull ? 0 : root.overlayInset
            radius: (root._coverFull || root.overlaySquareCorners) ? 0 : root.overlayCornerRadius
            color: root.destructive ? root.overlayColorDestructive : root.overlayColorNormal
            opacity: 0.0
            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Component.onCompleted:   root.overlayDimItem = overlayDim
            Component.onDestruction: if (root.overlayDimItem === overlayDim) root.overlayDimItem = null
        }
    }

    // ===== 仅在动画期间开启缓存层 =====
    // 动画时：layer.enabled = true（高帧率）
    // 静止时：layer.enabled = false（高清晰）
    property bool _cacheWhileAnimating: false
    Timer {
        id: _dropCache
        interval: 220    // 比 enter 动画略长一点
        repeat: false
        onTriggered: {
            rootContent.layer.enabled = false
            root._cacheWhileAnimating = false
        }
    }

    // ===== 内容卡片 =====
    padding: 0
    background: null
    contentItem: Item {
        id: rootContent
        property int gutter: 20
        implicitWidth:  Math.round(contentCol.implicitWidth  + rootContent.gutter*2)
        implicitHeight: Math.round(contentCol.implicitHeight + rootContent.gutter*2)
        clip: true

        // 纹理尺寸匹配 DPR；平时关闭缓存，动画时临时开启
        layer.enabled: root._cacheWhileAnimating
        layer.smooth:  true
        layer.textureSize: Qt.size(
            Math.max(1, Math.round(width  * root.dpr)),
            Math.max(1, Math.round(height * root.dpr))
        )

        onVisibleChanged: if (visible) Qt.callLater(() => primaryBtn.forceActiveFocus())

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: root.palette.window
            border.color: Qt.alpha(Qt.darker(color, 1.2), 0.25)
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: rootContent.gutter
            spacing: 14

            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                Item {
                    implicitWidth:  44
                    implicitHeight: 44
                    visible: icon.status === Image.Ready

                    Image {
                        id: icon
                        anchors.centerIn: parent
                        source: root.iconSource
                        width: 30; height: 30
                        sourceSize.width:  Math.round(width  * root.dpr)
                        sourceSize.height: Math.round(height * root.dpr)
                        mipmap: true
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
                        opacity: 0.9
                        wrapMode: Label.Wrap
                        elide: Label.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Item { Layout.fillWidth: true }

                Button {
                    visible: root.secondaryText.length > 0
                    text: root.secondaryText
                    onClicked: {
                        // 退出动画需要缓存
                        root._cacheWhileAnimating = true
                        root.rejected()
                        root.close()
                    }
                }
                Button {
                    visible: root.tertiaryText.length > 0
                    text: root.tertiaryText
                    onClicked: {
                        root._cacheWhileAnimating = true
                        root.tertiaryClicked()
                        root.close()
                    }
                }
                Button {
                    id: primaryBtn
                    text: root.primaryText
                    font.bold: true
                    onClicked: {
                        root._cacheWhileAnimating = true
                        root.accepted()
                        root.close()
                    }
                    palette.buttonText: root.destructive ? "white" : undefined
                    palette.button:     root.destructive ? "#d9363e" : undefined
                }
            }
        }

        Keys.onReturnPressed: (event) => { if (root.visible) { primaryBtn.clicked(); event.accepted = true } }
        Keys.onEnterPressed:  (event) => { if (root.visible) { primaryBtn.clicked(); event.accepted = true } }
    }

    // ===== 高帧率动画 =====
    enter: Transition {
        ScriptAction { script: { root._cacheWhileAnimating = true; _dropCache.restart() } }
        OpacityAnimator { target: root.overlayDimItem; from: 0;   to: 1;   duration: 150; easing.type: Easing.OutCubic }
        OpacityAnimator { target: root.contentItem;   from: 0;   to: 1;   duration: 150; easing.type: Easing.OutCubic }
        ScaleAnimator   { target: root.contentItem;   from: 0.97; to: 1.0; duration: 150; easing.type: Easing.OutCubic
                          onFinished: root.contentItem.scale = 1.0 }
    }
    exit: Transition {
        OpacityAnimator { target: root.overlayDimItem; from: 1;   to: 0;   duration: 130; easing.type: Easing.InQuad }
        OpacityAnimator { target: root.contentItem;    from: 1;   to: 0;   duration: 130; easing.type: Easing.InQuad }
        ScaleAnimator   { target: root.contentItem;    from: 1.0; to: 0.98; duration: 130; easing.type: Easing.InQuad }
    }

    // 若进入全屏，确保遮罩立即铺满；若已可见，刷新一次缓存层
    Connections {
        target: root._win
        function onVisibilityChanged() {
            if (root.visible) {
                // 如果刚刚进入全屏，保险地重建一下缓存纹理，然后交给 _dropCache 关掉
                root._cacheWhileAnimating = true
                _dropCache.restart()
            }
        }
    }
}
