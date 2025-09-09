import QtQuick
import QtQuick.Controls

Item {
    id: root
    // 唯一对外接口
    property string text: ""

    // 内部常量
    readonly property int _delay:   600
    readonly property int _timeout: 6000
    readonly property int _offset:  4
    readonly property int _fontPx:  12

    // 缓存父项为动态类型，避免静态类型检查抱怨 QQuickItem 上没有 hovered
    property var _host: parent

    // 兜底的 HoverHandler（即使 _host 不是 Control 也能工作）
    HoverHandler { id: hh; target: root._host; acceptedDevices: PointerDevice.Mouse }

    ToolTip {
        id: tip
        // 可见性：父项的 hovered 为主；HoverHandler 为辅
        visible: (root._host && root._host.hovered === true) || hh.hovered
        delay:   root._delay
        timeout: root._timeout

        // 位置：在父项下方水平居中
        x: root._host ? (root._host.width  - tip.implicitWidth) / 2 : 0
        y: root._host ? (root._host.height + root._offset) : 0

        // 低调灰底小字
        contentItem: Text {
            text: root.text
            font.pixelSize: root._fontPx
            color: "#dddddd"
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: "#333333"
            radius: 4
            opacity: 0.92
        }

        // 淡入淡出
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }
    }
}
