// ThemeComponent.qml - ���⸴�����������ɫ�ı������������οգ�
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root
    // ��������
    property string text: ""
    property int fontPixelSize: 22
    // ���ⲿע�����������Դ��ͨ����һ�� Canvas �� Item��
    property Item flowSource: null
    // ���������뷽ʽ��Ĭ���볣�� Label һ��
    property int horizontalAlignment: Text.AlignHCenter
    property int verticalAlignment: Text.AlignVCenter

    // �������ʽ�ߴ������������
    implicitWidth: maskText.implicitWidth
    implicitHeight: maskText.implicitHeight

    // �ı����壬����Ϊ����Դ
    Text {
        id: maskText
        anchors.fill: parent
        text: root.text
        font.pixelSize: root.fontPixelSize
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
        // ʹ������/��������Ⱦ�����پ��
        renderType: Text.QtRendering
        color: "white"  // ��ȡ alpha
        visible: false   // �� OpacityMask �����ʾ
    }

    // ���ɴ� Alpha ����������
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

    // ���ݵ�ǰ���Σ���ȡ flowSource ��Ӧ����
    // ������������Ա㼸�α仯ʱ���¼���
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
        hideSource: false   // �������屣����ʾ
        mipmap: true
        smooth: true
    }

    // ������ alpha �ο������������
    OpacityMask {
        anchors.fill: parent
        visible: root.flowSource !== null
        source: flowTex
        maskSource: maskTex
        invert: false
        cached: false
    }

    // ���ˣ��� flowSource ��δע��ʱ����ʾ��ͨ�ı�����հ�
    Label {
        anchors.fill: parent
        visible: root.flowSource === null
        horizontalAlignment: root.horizontalAlignment
        verticalAlignment: root.verticalAlignment
        text: root.text
        font.pixelSize: root.fontPixelSize
    }
}
