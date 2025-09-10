// Theme.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material

QtObject {
    id: theme

    // 获取当前主题，由调用者决定（默认 Light）
    property int systemTheme: Material.theme
    property bool isDark: systemTheme === Material.Dark

    // 两套静态方案
    readonly property var lightScheme: ({
        menuGradTop: "#1769ff",
        menuGradMid: "#3b8cff",
        menuGradBot: "#6fb1ff",
        menuTextColor: "white",
        hoverMask: Qt.rgba(0,0,0,0.12),
        gradientColors: ["#0D47A1", "#7B1FA2", "#F44336", "#AFB42B"]
    })

    readonly property var darkScheme: ({
        menuGradTop: "#0D47A1",
        menuGradMid: "#4A148C",
        menuGradBot: "#B71C1C",
        menuTextColor: "#E0E0E0",
        hoverMask: Qt.rgba(1,1,1,0.12),
        gradientColors: ["#90CAF9", "#CE93D8", "#EF9A9A", "#DCE775"]
    })

    // 当前激活方案
    readonly property var scheme: isDark ? darkScheme : lightScheme

    // 便于直接用
    property color menuGradTop: scheme.menuGradTop
    property color menuGradMid: scheme.menuGradMid
    property color menuGradBot: scheme.menuGradBot
    property color menuTextColor: scheme.menuTextColor
    property color hoverMask: scheme.hoverMask
    property var gradientColors: scheme.gradientColors
}
