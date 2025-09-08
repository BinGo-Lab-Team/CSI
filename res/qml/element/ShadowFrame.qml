pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    // ==== API ==== 
    property int inset: 18
    property int cornerRadius: 12
    property bool squareCorners: false
    property color frameColor: "white"
    // �������ʱ�Ƿ�����ʾ��Ӱ��Ĭ��Ϊ��ԭ�߼�����һ�£����/ȫ������ʾ��
    property bool shadowVisibleWhenMaximized: false

    // ��Ϊ���ʹ�ã�������ֱ��д�� ShadowFrame {} �ڼ���
    default property alias content: contentHolder.data

    // �����ֲ���Ⱦ��ȷ��͸�������µİ�͸��������ȷ�ϳ�
    layer.enabled: true
    layer.smooth: true

    // �Ź�����Ӱ��ͼ
    BorderImage {
        id: nineShadow
        anchors.fill: parent
        source: "qrc:/res/image/shadow@q0.png"
        // Border �������زĵ��ڱ߽�һ�£����ؼ���������ᱻ����ò���
        border { left: root.inset; top: root.inset; right: root.inset; bottom: root.inset }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
        smooth: true
        cache: true
        asynchronous: false
        visible: !root.squareCorners || root.shadowVisibleWhenMaximized
        z: 0
        onStatusChanged: if (status !== BorderImage.Ready) console.warn("[ShadowFrame] shadow status:", status)
    }

    // ���ݳ��ؿ򣨴�Բ����ü���
    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: root.inset
        radius: root.squareCorners ? 0 : root.cornerRadius
        color: root.frameColor
        clip: true
        z: 1
        Behavior on radius { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Item { id: contentHolder; anchors.fill: parent }
    }
}
