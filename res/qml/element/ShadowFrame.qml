// ShadowFrame.qml - 核心自绘窗口组件
pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    // ==== 对外 API ====
    property int  inset: 18
    property int  cornerRadius: 12
    property bool squareCorners: false                  // 全屏/最大化时请置 true
    property color frameColor: "white"
    property bool shadowVisibleWhenMaximized: false
    // 新增：动画开关（由外部 Main.qml 透传）
    property bool enableAnim: true

    // 会被圆角裁切的内容槽
    default property alias content: frame.data
    // 不裁切的顶层叠加槽（放 Popup/蒙版/Toast）
    property alias overlay: overlayLayer.data

    // ==== HiDPI ====
    property real dpr: 1
    property real texDpr: Math.max(dpr, Math.ceil(dpr))

    // 根层分层：仅在"非全屏/非最大化"且需要阴影/下采样时开启
    // 全屏/最大化（squareCorners=true）时强制关闭，避免切换瞬间透明
    layer.enabled: (!root.squareCorners) && ((root.texDpr > root.dpr) || root.wantShadow)
    layer.samples: 4
    layer.smooth: root.texDpr > root.dpr
    layer.textureSize: Qt.size(
        Math.max(1, Math.round(width  * root.texDpr)),
        Math.max(1, Math.round(height * root.texDpr))
    )

    // 隐式尺寸
    implicitWidth: 400
    implicitHeight: 300

    // 计算属性
    readonly property int  _safeInset: Math.min(inset, Math.floor(Math.min(width, height)/2))
    readonly property bool wantShadow: (!root.squareCorners) || root.shadowVisibleWhenMaximized

    // ===== 外部阴影（九宫格 PNG）=====
    BorderImage {
        id: nineShadow
        anchors.fill: parent
        source: "qrc:/res/image/shadow@q0.png"
        border {
            left:   root._safeInset
            top:    root._safeInset
            right:  root._safeInset
            bottom: root._safeInset
        }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
        smooth: true
        cache: true
        asynchronous: false

        // 最大化/全屏时立即隐藏阴影，避免任何淡出过渡
        visible: !root.squareCorners && root.wantShadow
        opacity: root.wantShadow ? 1 : 0
        Behavior on opacity { 
            enabled: root.enableAnim && !root.squareCorners  // 关闭动画或全屏时禁用渐变
            NumberAnimation { 
                duration: 120
                easing.type: Easing.OutCubic 
            } 
        }

        z: 0
    }

    // ===== 内容承载框（圆角裁切区域）=====
    Rectangle {
        id: frame
        anchors.fill: parent
        // 全屏/最大化且不展示阴影时，立即去掉内容边距
        anchors.margins: root.squareCorners && !root.shadowVisibleWhenMaximized ? 0 : root._safeInset
        Behavior on anchors.margins {
            enabled: root.enableAnim && !root.squareCorners  // 关闭动画或全屏时禁用过渡
            NumberAnimation { 
                duration: 120
                easing.type: Easing.OutCubic 
            }
        }
        color: root.frameColor                  // 必须是不透明色
        z: 1

        // 仅窗口化时需要圆角遮罩
        readonly property bool maskEnabled: !root.squareCorners

        // 子层分层：需要裁切或需要下采样时开启
        layer.enabled: frame.maskEnabled || (root.texDpr > root.dpr)
        layer.samples: 4
        layer.smooth: root.texDpr > root.dpr
        layer.textureSize: Qt.size(
            Math.max(1, Math.round(width  * root.texDpr)),
            Math.max(1, Math.round(height * root.texDpr))
        )

        // 只有 maskEnabled 才挂效果；否则明确为 null
        layer.effect: frame.maskEnabled ? maskEffectComponent : null

        // 遮罩裁切（未来需考虑替换 OpacityMask）
        Component {
            id: maskEffectComponent
            OpacityMask {
                maskSource: ShaderEffectSource {
                    id: maskTex
                    live: true
                    hideSource: true
                    sourceItem: Rectangle {
                        id: maskRect
                        width: frame.width
                        height: frame.height
                        radius: root.squareCorners ? 0 : root.cornerRadius
                        color: "black"
                    }
                    textureSize: Qt.size(
                        Math.max(1, Math.round(maskRect.width  * root.texDpr)),
                        Math.max(1, Math.round(maskRect.height * root.texDpr))
                    )
                }
            }
        }
    }

    // ===== 顶层叠加层（不受裁切影响）=====
    Item {
        id: overlayLayer
        anchors.fill: parent
        z: 9999
    }
}
