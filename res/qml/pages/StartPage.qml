// StartPage.qml - 开始页（测试）
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import csi

Item {
    id: root
    width: 200; height: 120

    // 供外部（Main.qml）传入的流动背景源（flowFX）
    // 注意：需要在 Main.qml 的 Loader onLoaded 中赋值：startPage.item.flowSource = flowFX
    property Item flowSource

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        // 使用可复用的主题色文本组件（来自 csi 模块）
        ThemeText {
            id: knockoutText
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("此处为启动页，此为测试文本")
            fontPixelSize: 22
            flowSource: root.flowSource
        }

        // 使用主题流动色描边按钮
        ThemeBorderButton {
            id: btn
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("TEST Button")
            flowSource: root.flowSource
            // 保留 Tooltip
            Tooltip { text: qsTr("这是一个带淡入淡出的灰色 tooltip") }
        }
    }
}
