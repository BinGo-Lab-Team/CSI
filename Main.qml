// Main.qml - 前端入口
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

// ==== 程序窗口 ====
ApplicationWindow {
    id: win
    visible: true   // 窗口可见
    width: 960
    height: 640
    title: win.tr("csi.title", "CSI")
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    // 监听可见性变化
    Connections {
        target: win
        function onVisibilityChanged(newVis) {
            win._lastVis = newVis;
        }
    }

    // ===== 配置 =====
    readonly property bool maximized: visibility === Window.Maximized
    readonly property bool squareCorners: (visibility === Window.FullScreen) || (visibility === Window.Maximized)
    property int currentTab: 0
    property int cornerRadius: 12
    property int inset: 18

    // 用于还原时的最小尺寸下限，避免跳点
    property int minW: 400
    property int minH: 300

    // 还原时需要的上一次非全屏窗口几何（持续采样）
    property int lastNormalX: 100
    property int lastNormalY: 100
    property int lastNormalWidth: 960
    property int lastNormalHeight: 640
    property int _lastVis: Window.AutomaticVisibility

    // 只要处于 Windowed/AutomaticVisibility，就持续维护 lastNormal
    function _maybeRecordIfNormal() {
        if (win.visibility === Window.AutomaticVisibility || win.visibility === Window.Windowed) {
            lastNormalX = win.x;
            lastNormalY = win.y;
            lastNormalWidth = win.width;
            lastNormalHeight = win.height;
        }
    }

    // 绑定几何变化，自动记录
    onXChanged: _maybeRecordIfNormal()
    onYChanged: _maybeRecordIfNormal()
    onWidthChanged: _maybeRecordIfNormal()
    onHeightChanged: _maybeRecordIfNormal()

    // 还原到上一次正常几何
    function restoreFromLastNormal() {
        const nx = Math.round(lastNormalX);
        const ny = Math.round(lastNormalY);
        const nw = Math.max(minW, Math.round(lastNormalWidth));
        const nh = Math.max(minH, Math.round(lastNormalHeight));

        win.showNormal();
        Qt.callLater(() => {
            win.x = nx;
            win.y = ny;
            win.width = nw;
            win.height = nh;
        });
    }

    readonly property int durFast: 80
    readonly property int durMed: 120
    readonly property int durSlow: 160
    readonly property int debounceMs: 200
    property double _lastToggleTS: 0

    // 最大化 <-> 还原（含防抖），不再依赖切换瞬间记录
    function _debouncedToggleMaxRestore() {
        const t = Date.now();
        if (t - _lastToggleTS < debounceMs)
            return;
        _lastToggleTS = t;

        if (win.visibility === Window.Maximized || win.visibility === Window.FullScreen) {
            restoreFromLastNormal();
        } else {
            win.showMaximized();
        }
    }

    // 获取当前 DPR
    readonly property real dpr: Screen.devicePixelRatio
    readonly property int hit: Math.round(6 * dpr)
    readonly property int cornerHit: Math.round(10 * dpr)

    // 播放启动音乐
    property bool enableStartupSound: true
    MediaPlayer {
        id: startupPlayer
        source: "qrc:/res/audio/startup.ogg"
        audioOutput: AudioOutput {
            id: out
            volume: 1.0
            muted: false
        }
        Component.onCompleted: Qt.callLater(() => {
            if (win.enableStartupSound)
                play();
        })
        onErrorOccurred: (error, errorString) => {
            console.warn("[MediaPlayer] error:", error, errorString);
            win.enableStartupSound = false;
        }
    }

    // ==== 主题 ====
    Theme {
        id: theme
    }
    property color menuGradTop: theme.menuGradTop
    property color menuGradMid: theme.menuGradMid
    property color menuGradBot: theme.menuGradBot
    property color menuTextColor: theme.menuTextColor
    property color hoverMask: theme.hoverMask
    readonly property color invertBase: menuTextColor

    function tr(id, fallback) {
        var s = qsTrId(id);
        return (s === id || s === "") ? fallback : s;
    }

    function toggleFullscreen() {
        if (win.visibility === Window.FullScreen) {
            win.showNormal();
        } else {
            win.showFullScreen();
        }
    }


    // ==== 快捷键 ====
    Shortcut {
        sequences: [StandardKey.Close]
        onActivated: win.close()
    }
    Shortcut {
        sequences: ["Alt+F10"]
        onActivated: win._debouncedToggleMaxRestore()
    }
    Shortcut {
        sequences: ["F11"]
        onActivated: win.toggleFullscreen()
    }
    Shortcut {
        sequences: ["Escape"]
        onActivated: if (win.visibility === Window.FullScreen)
            win.showNormal()
    }
    Shortcut {
        sequences: ["Ctrl+1"]
        onActivated: win.currentTab = 0
    }
    Shortcut {
        sequences: ["Ctrl+2"]
        onActivated: win.currentTab = 1
    }

    // ==== 窗口 ====
    ShadowFrame {
        id: shell
        anchors.fill: parent
        dpr: Screen.devicePixelRatio
        inset: win.squareCorners ? 0 : win.inset
        cornerRadius: win.cornerRadius
        squareCorners: win.squareCorners
        frameColor: win.palette.window

        // ===== 标题栏 =====
        Rectangle {
            id: titleBar
            height: 56
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            radius: win.squareCorners ? 0 : win.cornerRadius
            color: "transparent"
            z: 3

            // 流动标题栏背景
            Canvas {
                id: flowFX
                anchors.fill: parent
                renderTarget: Canvas.FramebufferObject
                renderStrategy: Canvas.Immediate
                property bool running: true

                property real bandWidth: width
                property real pxPerSecond: 120
                property real dpr: Screen.devicePixelRatio

                property real _t0: 0
                function _nowSec() {
                    return Date.now() / 1000.0;
                }

                Timer {
                    id: raf
                    interval: 33
                    repeat: true
                    running: flowFX.running && flowFX.visible && (win.visibility !== Window.Minimized && win.visibility !== Window.Hidden)
                    onTriggered: flowFX.requestPaint()
                }

                Component.onCompleted: {
                    _t0 = _nowSec();
                    requestPaint();
                    raf.start();
                }

                onVisibleChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onDprChanged: requestPaint()
                Connections {
                    target: win
                    function onVisibilityChanged() {
                        flowFX.requestPaint();
                    }
                }

                function colors() {
                    return (theme.gradientColors && theme.gradientColors.length > 0) ? theme.gradientColors : [win.menuGradTop, win.menuGradMid, win.menuGradBot];
                }

                onPaint: {
                    const ctx = getContext("2d");
                    const dprNow = flowFX.dpr;
                    ctx.resetTransform();
                    ctx.scale(dprNow, dprNow);

                    const w = width / dprNow;
                    const h = height / dprNow;
                    ctx.clearRect(0, 0, w, h);

                    const cols = colors().slice();
                    if (cols.length && cols[0] !== cols[cols.length - 1])
                        cols.push(cols[0]);

                    const bw = Math.max(1, bandWidth);
                    const elapsed = _nowSec() - _t0;
                    const offsetPx = (elapsed * pxPerSecond) % bw;

                    let startX = -offsetPx - bw;
                    while (startX < w + bw) {
                        const xi = Math.round(startX);
                        const g = ctx.createLinearGradient(xi, 0, xi + bw, 0);
                        const n = cols.length;
                        for (let i = 0; i < n; ++i) {
                            const t = (n === 1) ? 0.5 : i / (n - 1);
                            g.addColorStop(t, cols[i]);
                        }
                        ctx.fillStyle = g;
                        ctx.fillRect(xi - 1, 0, bw + 2, h);
                        startX += bw;
                    }
                }
            }
            // 控制标题栏启停
            QtObject {
                id: flowAnim
                property alias running: flowFX.running
            }

            // —— 左侧标题 ——
            Label {
                id: titleText
                text: win.tr("csi.title", "CSI")
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: win.menuTextColor
                font.pixelSize: 26
                font.weight: Font.DemiBold
                z: 1
            }

            // —— 中部导航 ——
            Row {
                id: navCenter
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                z: 1

                ToolButton {
                    id: tabStart
                    text: win.tr("csi.tab.start", "启动")
                    checkable: true
                    checked: win.currentTab === 0
                    padding: 10
                    implicitHeight: 36
                    implicitWidth: Math.max(88, contentItem.implicitWidth + 20)
                    onClicked: win.currentTab = 0
                    scale: pressed ? 0.98 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: win.durFast
                            easing.type: Easing.OutCubic
                        }
                    }
                    background: Rectangle {
                        radius: 8
                        color: tabStart.checked ? win.invertBase : (tabStart.hovered ? win.hoverMask : "transparent")
                    }
                    contentItem: Label {
                        text: tabStart.text
                        font.pixelSize: 15
                        color: tabStart.checked ? win.menuGradTop : win.menuTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ToolButton {
                    id: tabSettings
                    text: win.tr("csi.tab.settings", "设置")
                    checkable: true
                    checked: win.currentTab === 1
                    padding: 10
                    implicitHeight: 36
                    implicitWidth: Math.max(88, contentItem.implicitWidth + 20)
                    onClicked: win.currentTab = 1
                    scale: pressed ? 0.98 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: win.durFast
                            easing.type: Easing.OutCubic
                        }
                    }
                    background: Rectangle {
                        radius: 8
                        color: tabSettings.checked ? win.invertBase : (tabSettings.hovered ? win.hoverMask : "transparent")
                    }
                    contentItem: Label {
                        text: tabSettings.text
                        font.pixelSize: 15
                        color: tabSettings.checked ? win.menuGradTop : win.menuTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // —— 右上角窗口控制 ——
            Row {
                id: rowControls
                spacing: 6
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                z: 0

                readonly property string iconMin: "qrc:/res/icon/window/min.svg"
                readonly property string iconMax: "qrc:/res/icon/window/max.svg"
                readonly property string iconRes: "qrc:/res/icon/window/restore.svg"
                readonly property string iconClose: "qrc:/res/icon/window/close.svg"

                ToolButton {
                    id: btnMin
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: win.showMinimized()
                    background: Rectangle {
                        radius: 6
                        color: btnMin.hovered ? win.hoverMask : "transparent"
                    }
                    contentItem: Image {
                        source: rowControls.iconMin
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                    }
                }
                ToolButton {
                    id: btnMax
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: win._debouncedToggleMaxRestore()
                    background: Rectangle {
                        radius: 6
                        color: btnMax.hovered ? win.hoverMask : "transparent"
                    }
                    contentItem: Image {
                        source: win.squareCorners ? rowControls.iconRes : rowControls.iconMax
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                    }
                }
                ToolButton {
                    id: btnClose
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: win.close()
                    background: Rectangle {
                        radius: 6
                        color: btnClose.hovered ? "#e5484d" : "transparent"
                    }
                    contentItem: Image {
                        source: rowControls.iconClose
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                    }
                }
            }

            // 全屏时鼠标拖动还原
            DragHandler {
                id: dragTitle
                target: null
                grabPermissions: PointerHandler.CanTakeOverFromAnything
                onActiveChanged: if (active) {
                    const p = dragTitle.centroid.scenePosition;

                    function relayoutAndDrag() {
                        // 以鼠标为锚点计算新位置，减少跳闪
                        var w = Math.max(win.minW, lastNormalWidth);
                        var h = Math.max(win.minH, lastNormalHeight);
                        var offX = Math.max(0, Math.min(w, p.x - win.x));
                        var offY = Math.max(0, Math.min(h, p.y - win.y));
                        var nx = Math.round(p.x - offX);
                        var ny = Math.round(p.y - Math.min(offY, titleBar.height));
                        ny = Math.max(0, ny);
                        win.x = nx;
                        win.y = ny;
                        win.width = w;
                        win.height = h;
                        // 还原后等待一帧再进入拖动
                        Qt.callLater(() => {
                            if (flowAnim)
                                flowAnim.running = true;
                            win.startSystemMove();
                        });
                    }

                    if (win.visibility === Window.FullScreen || win.maximized) {
                        // 处于后台时暂停标题栏动画，减少开销
                        if (flowAnim)
                            flowAnim.running = false;
                        win.showNormal();
                        Qt.callLater(relayoutAndDrag);
                    } else {
                        win.startSystemMove();
                    }
                }
            }
            TapHandler {
                gesturePolicy: TapHandler.DragThreshold
                onDoubleTapped: win._debouncedToggleMaxRestore()
            }
        }

        // ===== 内容区 =====
        StackLayout {
            id: stack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            currentIndex: win.currentTab

            Loader {
                id: startPage
                source: "qrc:/res/qml/pages/StartPage.qml"
                asynchronous: true
                active: stack.currentIndex === 0
            }
            Loader {
                id: settingsPage
                source: "qrc:/res/qml/pages/SettingsPage.qml"
                asynchronous: true
                active: stack.currentIndex === 1
            }
        }
    }

    // ===== 缩放边缘 =====
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: win.hit
        color: "transparent"
        visible: !win.squareCorners
        HoverHandler {
            cursorShape: Qt.SizeVerCursor
        }
        DragHandler {
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: if (active)
                win.startSystemResize(Qt.TopEdge)
        }
    }
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: win.hit
        color: "transparent"
        visible: !win.squareCorners
        HoverHandler {
            cursorShape: Qt.SizeVerCursor
        }
        DragHandler {
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: if (active)
                win.startSystemResize(Qt.BottomEdge)
        }
    }
    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: win.hit
        color: "transparent"
        visible: !win.squareCorners
        HoverHandler {
            cursorShape: Qt.SizeHorCursor
        }
        DragHandler {
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: if (active)
                win.startSystemResize(Qt.LeftEdge)
        }
    }
    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: win.hit
        color: "transparent"
        visible: !win.squareCorners
        HoverHandler {
            cursorShape: Qt.SizeHorCursor
        }
        DragHandler {
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: if (active)
                win.startSystemResize(Qt.RightEdge)
        }
    }

    // ===== 四个角 =====
    Rectangle {
        x: 0
        y: 0
        width: win.cornerHit
        height: win.cornerHit
        color: "transparent"
        visible: !win.squareCorners
        HoverHandler {
            cursorShape: Qt.SizeFDiagCursor
        }
        DragHandler {
            target: null
            onActiveChanged: if (active)
                win.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
        }
    }
    Rectangle {
        anchors.right: parent.right
        y: 0
        width: win.cornerHit
        height: win.cornerHit
        color: "transparent"
        visible: !win.squareCorners
        HoverHandler {
            cursorShape: Qt.SizeBDiagCursor
        }
        DragHandler {
            target: null
            onActiveChanged: if (active)
                win.startSystemResize(Qt.TopEdge | Qt.RightEdge)
        }
    }
    Rectangle {
        x: 0
        anchors.bottom: parent.bottom
        width: win.cornerHit
        height: win.cornerHit
        color: "transparent"
        visible: !win.squareCorners
        HoverHandler {
            cursorShape: Qt.SizeBDiagCursor
        }
        DragHandler {
            target: null
            onActiveChanged: if (active)
                win.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
        }
    }
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: win.cornerHit
        height: win.cornerHit
        color: "transparent"
        visible: !win.squareCorners
        HoverHandler {
            cursorShape: Qt.SizeFDiagCursor
        }
        DragHandler {
            target: null
            onActiveChanged: if (active)
                win.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
        }
    }
}
