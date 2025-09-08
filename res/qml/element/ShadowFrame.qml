pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    // ==== API ==== 
    property int inset: 18
    property int cornerRadius: 12
    property bool squareCorners: false
    property color frameColor: "white"
    // 控制最大化时是否仍显示阴影（默认为与原逻辑保持一致：最大化/全屏不显示）
    property bool shadowVisibleWhenMaximized: false

    // 作为插槽使用：把内容直接写在 ShadowFrame {} 内即可
    default property alias content: contentHolder.data

    // 开启分层渲染，确保透明窗口下的半透明像素正确合成
    layer.enabled: true
    layer.smooth: true

    // 九宫格阴影底图
    BorderImage {
        id: nineShadow
        anchors.fill: parent
        source: "qrc:/res/image/shadow@q0.png"
        // Border 必须与素材的内边界一致（像素级），否则会被拉伸得不对
        border { left: root.inset; top: root.inset; right: root.inset; bottom: root.inset }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
        smooth: true
        cache: true
        asynchronous: false
        visible: !root.squareCorners || root.shadowVisibleWhenMaximized
        z: 0
        onStatusChanged: if (status !== BorderImage.Ready) console.warn("[ShadowFrame] shadow status:", status)
    }

    // 内容承载框（带圆角与裁剪）
    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: root.inset
        radius: root.squareCorners ? 0 : root.cornerRadius
        color: root.frameColor
        clip: true
        z: 1
        Behavior on radius { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Item { id: contentHolder; anchors.fill: parent }
    }
}
