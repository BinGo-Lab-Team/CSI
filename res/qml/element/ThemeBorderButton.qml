// ThemeBorderButton.qml - 主题复用组件：流动主题色描边按钮
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Button {
    id: root
    // 外部传入的流动背景源（如 Main.qml 中的 flowFX）
    property Item flowSource: null
    // 外观参数
    property int borderWidth: 2
    property int radius: 8

    // 自定义背景：透明底 + 主题流动色描边
    background: Item {
        id: bg
        anchors.fill: parent

        // 交互反馈层（在最上层，不影响描边）
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.down ? Qt.rgba(1,1,1,0.2) : (root.hovered ? Qt.rgba(1,1,1,0.1) : "transparent")
            z: 10 // 确保在最上层
        }

        // 使用Canvas绘制精确的边框遮罩
        Canvas {
            id: borderCanvas
            anchors.fill: parent
            visible: false // 仅作为遮罩源
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                
                // 绘制外边框（白色）
                ctx.fillStyle = "white";
                ctx.beginPath();
                ctx.roundedRect(0, 0, width, height, root.radius, root.radius);
                ctx.fill();
                
                // 挖空内部（黑色，使用destination-out混合模式）
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                var innerR = Math.max(0, root.radius - root.borderWidth);
                ctx.roundedRect(root.borderWidth, root.borderWidth, 
                               width - root.borderWidth * 2, 
                               height - root.borderWidth * 2, 
                               innerR, innerR);
                ctx.fill();
            }
            
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }

        // 监听属性变化重绘
        Connections {
            target: root
            function onBorderWidthChanged() { borderCanvas.requestPaint(); }
            function onRadiusChanged() { borderCanvas.requestPaint(); }
        }

        // 生成纯 Alpha 的边框遮罩纹理
        ShaderEffectSource {
            id: maskTex
            visible: false
            live: true
            sourceItem: borderCanvas
            hideSource: true
            mipmap: true
            smooth: true
            format: ShaderEffectSource.Alpha
        }

        // 根据当前几何，裁取 flowSource 对应区域
        property rect flowRect: (root.flowSource ? (function() {
            var p = bg.mapToItem(root.flowSource, 0, 0);
            var _ = bg.x + bg.y + bg.width + bg.height
                    + root.flowSource.x + root.flowSource.y + root.flowSource.width + root.flowSource.height;
            return Qt.rect(p.x, p.y, bg.width, bg.height);
        })() : Qt.rect(0, 0, 0, 0))

        ShaderEffectSource {
            id: flowTex
            visible: false
            live: true
            sourceItem: root.flowSource
            sourceRect: bg.flowRect
            hideSource: false
            mipmap: true
            smooth: true
        }

        // 按边框 alpha 镂空输出流动纹理 - 只在边框区域显示
        OpacityMask {
            anchors.fill: parent
            visible: root.flowSource !== null
            source: flowTex
            maskSource: maskTex
            invert: false
            cached: false
            z: 1
        }

        // 回退：当 flowSource 尚未注入时，显示普通边框
        Rectangle {
            anchors.fill: parent
            visible: root.flowSource === null
            radius: root.radius
            color: "transparent"
            border.width: root.borderWidth
            border.color: "#3b8cff"
            z: 1
        }
    }
}
