// StartPage.qml - 开始页（测试）
import QtQuick
import QtQuick.Controls
import csi

Item {
    width: 200; height: 120

    Button {
        id: btn
        text: qsTr("TEST Button")
        anchors.centerIn: parent
        // 使用 Tooltip 必须开启
        hoverEnabled: true

        Tooltip { text: qsTr("这是一个带淡入淡出的灰色 tooltip") }
    }
}
