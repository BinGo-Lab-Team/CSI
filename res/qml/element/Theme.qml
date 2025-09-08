pragma ComponentBehavior: Bound
import QtQuick

QtObject {
    id: theme

    // 仍保留基础三色，供其他回退使用
    property color menuGradTop: "#1769ff"
    property color menuGradMid: "#3b8cff"
    property color menuGradBot: "#6fb1ff"
    property color menuTextColor: "white"
    property color hoverMask: Qt.rgba(0,0,0,0.12)
    readonly property color invertBase: menuTextColor

    // 流动条用色：高对比、不过分花
    // 你可随时增删、换顺序
    property var gradientColors: [
        "#00e1ff", 
        "#24c6dc",  
        "#28c76f",  
        "#11998e"   
    ]
}
