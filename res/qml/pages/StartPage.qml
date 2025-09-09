import QtQuick
import QtQuick.Controls
import csi

Item {
    width: 200; height: 120

   Button {
    id: btn
    text: qsTr("Button Info")
    anchors.centerIn: parent
    hoverEnabled: true   // 建议开着；有些皮实环境里没它就不触发 hovered

    Tooltip { text: qsTr("这是一个带淡入淡出的灰色 tooltip") }
}

}
