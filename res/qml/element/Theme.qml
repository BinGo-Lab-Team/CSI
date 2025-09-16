// Theme.qml - 主题颜色配置
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material

QtObject {
    id: theme

    // 直接绑定到父窗口的 Material.theme，确保动态更新
    property QtObject parentWindow: null
    property int systemTheme: parentWindow ? parentWindow.Material.theme : Material.Light
    property bool isDark: systemTheme === Material.Dark

    // Light 配色
    readonly property var lightScheme: ({
        // Menu
        menuGradTop: "#E5E5E5",
        menuGradMid: "#3b8cff",
        menuGradBot: "#6fb1ff",
        menuTextColor: "#006687",
        // Mask
        hoverMask: Qt.rgba(0,0,0,0.12),
        // Gradient - 注意！颜色数量必须和 Dark 相等
        gradientColors: ["#90CAF9", "#CE93D8", "#EF9A9A", "#DCE775"],
        // Text
        defaultText: "#00436D",
        // Background
        backgroundColor: "#E5E5E5"
    })

    // Drak 配色
    readonly property var darkScheme: ({
        // Menu 
        menuGradTop: "#0D47A1",
        menuGradMid: "#4A148C",
        menuGradBot: "#B71C1C",
        menuTextColor: "#E0E0E0",
        // Mask
        hoverMask: Qt.rgba(1,1,1,0.12),
        // Gradient - 注意！颜色数量必须和 Light 相等
        gradientColors: ["#0D47A1", "#7B1FA2", "#F44336", "#AFB42B"],
        // Text
        defaultText: "#69c3ff",
        // Background
        backgroundColor: "#313131"
    })

    // 当前激活方案
    readonly property var scheme: isDark ? darkScheme : lightScheme

    // ==== API ====
    property color menuGradTop: scheme.menuGradTop      // 顶端颜色
    Behavior on menuGradTop {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    
    property color menuGradMid: scheme.menuGradMid      // 中间颜色
    Behavior on menuGradMid {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    
    property color menuGradBot: scheme.menuGradBot      // 底部颜色
    Behavior on menuGradBot {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    
    property color menuTextColor: scheme.menuTextColor  // 标题栏文本颜色
    Behavior on menuTextColor {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    
    property color hoverMask: scheme.hoverMask          // 遮罩颜色
    Behavior on hoverMask {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    
    property var gradientColors: scheme.gradientColors  // 流动条配色
    // 注意：gradientColors是数组，无法直接用ColorAnimation，需要特殊处理
    
    property color defaultText: scheme.defaultText      // 默认文本颜色
    Behavior on defaultText {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    
    property color backgroundColor: scheme.backgroundColor // 背景颜色
    Behavior on backgroundColor {
        ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
}
