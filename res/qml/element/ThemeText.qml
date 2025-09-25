// ThemeComponent.qml - 主题复用组件：主题色文本（流动背景镂空）
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root
    // 对外属性
    property string text: ""
    property int fontPixelSize: 22
    // 供外部注入的流动背景源（通常是一个 Canvas 或 Item）
    property Item flowSource: null
    // 新增：对齐方式，默认与常用 Label 一致
    property int horizontalAlignment: Text.AlignHCenter
    property int verticalAlignment: Text.AlignVCenter

    // 组件的隐式尺寸跟随文字内容
    implicitWidth: maskText.implicitWidth
    implicitHeight: maskText.implicitHeight

    // 文本本体，仅作为遮罩源
    Text {
        id: maskText
        anchors.fill: parent
        text: root.text
        font.pixelSize: root.fontPixelSize
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
        // 使用向量/高质量渲染，减少锯齿
        renderType: Text.QtRendering
        color: "white"  // 仅取 alpha
        visible: false   // 由 OpacityMask 输出显示
    }

    // 生成纯 Alpha 的遮罩纹理
    ShaderEffectSource {
        id: maskTex
        visible: false
        live: true
        sourceItem: maskText
        hideSource: true
        mipmap: true
        smooth: true
        format: ShaderEffectSource.Alpha
    }

    // 根据当前几何，裁取 flowSource 对应区域
    // 引用相关属性以便几何变化时重新计算
    property rect flowRect: (root.flowSource ? (function() {
        var p = root.mapToItem(root.flowSource, 0, 0);
        var _ = root.x + root.y + root.width + root.height
                + root.flowSource.x + root.flowSource.y + root.flowSource.width + root.flowSource.height;
        return Qt.rect(p.x, p.y, root.width, root.height);
    })() : Qt.rect(0, 0, 0, 0))

    ShaderEffectSource {
        id: flowTex
        visible: false
        live: true
        sourceItem: root.flowSource
        sourceRect: root.flowRect
        hideSource: false   // 背景本体保留显示
        mipmap: true
        smooth: true
    }

    // 按文字 alpha 镂空输出流动纹理
    OpacityMask {
        anchors.fill: parent
        visible: root.flowSource !== null
        source: flowTex
        maskSource: maskTex
        invert: false
        cached: false
    }

    // 回退：当 flowSource 尚未注入时，显示普通文本避免空白
    Label {
        anchors.fill: parent
        visible: root.flowSource === null
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
        text: root.text
        font.pixelSize: root.fontPixelSize
    }
}
