pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    // ==== API ====
    property int  inset: 18
    property int  cornerRadius: 12
    property bool squareCorners: false
    property color frameColor: "white"
    property bool shadowVisibleWhenMaximized: false

    // ²å²Û
    default property alias content: contentHolder.data

    // ·Ö²ãäÖÈ¾,Ê¹ÓÃ MSAA ¿¹¾â³Ý
    layer.enabled: true
    layer.smooth: true
    layer.samples: 4

    // ÒþÊ½³ß´ç
    implicitWidth: 400
    implicitHeight: 300

    // ·ÀÓùÊ½ inset£¬±ÜÃâ¼«Ð¡³ß´çÊ±ÄÚÈÝÎª¸º
    readonly property int _safeInset: Math.min(inset, Math.floor(Math.min(width, height)/2))
    readonly property bool wantShadow: (!root.squareCorners) || root.shadowVisibleWhenMaximized

    // ¾Å¹¬¸ñÒõÓ°
    BorderImage {
        id: nineShadow
        anchors.fill: parent
        source: "qrc:/res/image/shadow@q0.png"
        border { left: root._safeInset; top: root._safeInset; right: root._safeInset; bottom: root._safeInset }
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
        smooth: true
        cache: true
        asynchronous: false

        // ÓÃÍ¸Ã÷¶È¶¯»­±ÜÃâÉÁ¶Ï
        visible: opacity > 0.001
        opacity: root.wantShadow ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        z: 0
        onStatusChanged: if (status !== BorderImage.Ready)
            console.warn("[ShadowFrame] shadow status:", status, "size:", width, height)
    }

    // ÄÚÈÝ³ÐÔØ¿ò£¨Ô²½Ç+²Ã¼ô£©
    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: root._safeInset
        radius: root.squareCorners ? 0 : root.cornerRadius
        color: root.frameColor
        clip: true
        z: 1
        Behavior on radius { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Item { id: contentHolder; anchors.fill: parent }
    }
}
