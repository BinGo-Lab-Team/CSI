// ThemeBorderButton.qml - ���⸴���������������ɫ��߰�ť
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Button {
    id: root
    // �ⲿ�������������Դ���� Main.qml �е� flowFX��
    property Item flowSource: null
    // ��۲���
    property int borderWidth: 2
    property int radius: 8

    // �Զ��屳����͸���� + ��������ɫ���
    background: Item {
        id: bg
        anchors.fill: parent

        // ���������㣨�����ϲ㣬��Ӱ����ߣ�
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.down ? Qt.rgba(1,1,1,0.2) : (root.hovered ? Qt.rgba(1,1,1,0.1) : "transparent")
            z: 10 // ȷ�������ϲ�
        }

        // ʹ��Canvas���ƾ�ȷ�ı߿�����
        Canvas {
            id: borderCanvas
            anchors.fill: parent
            visible: false // ����Ϊ����Դ
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                
                // ������߿򣨰�ɫ��
                ctx.fillStyle = "white";
                ctx.beginPath();
                ctx.roundedRect(0, 0, width, height, root.radius, root.radius);
                ctx.fill();
                
                // �ڿ��ڲ�����ɫ��ʹ��destination-out���ģʽ��
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

        // �������Ա仯�ػ�
        Connections {
            target: root
            function onBorderWidthChanged() { borderCanvas.requestPaint(); }
            function onRadiusChanged() { borderCanvas.requestPaint(); }
        }

        // ���ɴ� Alpha �ı߿���������
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

        // ���ݵ�ǰ���Σ���ȡ flowSource ��Ӧ����
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

        // ���߿� alpha �ο������������ - ֻ�ڱ߿�������ʾ
        OpacityMask {
            anchors.fill: parent
            visible: root.flowSource !== null
            source: flowTex
            maskSource: maskTex
            invert: false
            cached: false
            z: 1
        }

        // ���ˣ��� flowSource ��δע��ʱ����ʾ��ͨ�߿�
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
