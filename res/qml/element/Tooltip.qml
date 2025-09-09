import QtQuick
import QtQuick.Controls

Item {
    id: root
    // Ψһ����ӿ�
    property string text: ""

    // �ڲ�����
    readonly property int _delay:   600
    readonly property int _timeout: 6000
    readonly property int _offset:  4
    readonly property int _fontPx:  12

    // ���游��Ϊ��̬���ͣ����⾲̬���ͼ�鱧Թ QQuickItem ��û�� hovered
    property var _host: parent

    // ���׵� HoverHandler����ʹ _host ���� Control Ҳ�ܹ�����
    HoverHandler { id: hh; target: root._host; acceptedDevices: PointerDevice.Mouse }

    ToolTip {
        id: tip
        // �ɼ��ԣ������ hovered Ϊ����HoverHandler Ϊ��
        visible: (root._host && root._host.hovered === true) || hh.hovered
        delay:   root._delay
        timeout: root._timeout

        // λ�ã��ڸ����·�ˮƽ����
        x: root._host ? (root._host.width  - tip.implicitWidth) / 2 : 0
        y: root._host ? (root._host.height + root._offset) : 0

        // �͵��ҵ�С��
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

        // ���뵭��
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }
    }
}
