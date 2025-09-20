// Main.qml - 前端入口
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Controls.Material

// ==== 程序窗口 ====
ApplicationWindow {
    id: win
    visible: true
    width: 960
    height: 640
    title: win.tr("csi.title", "CSI")
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    opacity: 1.0

    // 构造主题颜色属性
    Theme { 
        id: theme
        parentWindow: win
    }

    // 读取主题配置
    QtObject { 
        Component.onCompleted:{
            switch (Settings.init("Theme", "system")) {
                case "system":
                    win.Material.theme = Material.System; break;
                case "dark":
                    win.Material.theme = Material.Dark; break;
                case "light":
                    win.Material.theme = Material.Light; break;
                default:
                    win.Material.theme = Material.System; break;
            }    
        }
    }
    // 监听设置变化：General/Theme
    Connections {
        target: Settings
        function onSettingChanged(section, key, value) {
            if (section === "General" && key === "Theme") {
                console.log("主题设置改变");
                switch (value.toString()) {
                    case "system": win.Material.theme = Material.System; break;
                    case "dark":   win.Material.theme = Material.Dark; break;
                    case "light":  win.Material.theme = Material.Light; break;
                    default:       win.Material.theme = Material.System; break;
                }
            }
        }
    }

    // 监听可见性变化
    Connections {
        target: win
        function onVisibilityChanged(newVis) {
            if (newVis === Window.Minimized) {
                // 进入最小化：记录之前的可见状态（外部最小化也能捕获）
                if (win._preMinVis === -1)
                    win._preMinVis = win._lastVis;
                if (!geomAnim.running)
                    win.opacity = 1.0;
            } else if (newVis === Window.Windowed || newVis === Window.AutomaticVisibility) {
                // 从最小化恢复到可见
                if (win._lastVis === Window.Minimized) {
                    win._freezeRecord = true; // 避免过渡阶段覆盖 lastNormalGeom
                    if (win._preMinVis === Window.Maximized) {
                        // 目标是回到最大化：先保持冻结，等待真正进入 Maximized 后再解冻
                        // 目标是回到最大化：不再硬切换，改为自定义几何动画，结束后再设置 Maximized
                        win._pendingUnfreeze = true;
                        Qt.callLater(() => {
                            win.showMaximized();
                            const g = Qt.rect(0, 0, Screen.desktopAvailableWidth, Screen.desktopAvailableHeight);
                            win._animTarget = "max";
                            runGeom(g.x, g.y, g.width, g.height);
                        });
                    } else {
                        // 普通窗口：恢复到保存的几何，并尽快解冻
                        win.x = win.lastNormalGeom.x;
                        win.y = win.lastNormalGeom.y;
                        win.width = win.lastNormalGeom.width;
                        win.height = win.lastNormalGeom.height;
                        Qt.callLater(() => { _freezeRecord = false; });
                    }
                    win._preMinVis = -1;
                }
            } else if (newVis === Window.Maximized) {
                // 已经进入最大化：若存在待解冻请求，现在解冻，避免 Windowed 过渡期写入 lastNormalGeom
                if (win._pendingUnfreeze) {
                    win._pendingUnfreeze = false;
                    Qt.callLater(() => { _freezeRecord = false; });
                }
            }
            win._lastVis = newVis;
        }
    }

    // ===== 配置 =====
    property bool isMaximized: visibility === Window.Maximized
    // 在最大化动画期间（_animTarget === "max"）提前移除圆角与阴影，避免边缘二次过渡
    readonly property bool squareCorners: win.isMaximized || (win._animTarget === "max")
    property int currentTab: 0
    property int cornerRadius: 12
    property int inset: 18  // 阴影厚度。对于 shadow@q0.png 的基准值为 24

    // 用于还原时的最小尺寸下限，避免跳点
    property int minW: 400
    property int minH: 300

    // 还原时需要的上一次非全屏窗口几何（持续采样）
    property rect lastNormalGeom: Qt.rect(x, y, width, height)
    property int _lastVis: Window.AutomaticVisibility

    // 进行系统尺寸调整时的计数与状态
    property int _resizeCounter: 0
    readonly property bool isResizing: _resizeCounter > 0
    // 进入/退出最小化等阶段性操作时，短暂冻结 lastNormalGeom 的自动采样
    property bool _freezeRecord: false
    // 记录进入最小化前的可见状态，用于还原时恢复到对应状态
    property int _preMinVis: -1
    // 延迟解冻标记：用于“从最小化恢复到最大化”的两段过渡，等进入 Maximized 后再解冻
    property bool _pendingUnfreeze: false

    // 动画总开关（启动时读取/初始化）
    property bool enableAnim: Settings.init_bool("EnableAnimation", true)

    // 启动动画参数
    readonly property int startupOffsetY: 20            // 稍微增加初始上偏移
    readonly property real startupInitialAngle: -3      // 初始负角度（度）
    readonly property real startupInitialScale: 0.9     // 初始缩放比例
    readonly property int startupFadeDuration: 200      // 淡入时长
    readonly property int startupFirstStageDuration: 350    // 第一阶段动画时长（旋转和缩放）
    readonly property int startupSecondStageDuration: 450   // 第二阶段动画时长（额外的回弹）
    readonly property real startupBackOvershoot: 2.5        // 增加回弹幅度

    // 关闭动画参数
    readonly property int closeFadeDuration: 180    // 淡出时长
    readonly property int closeScaleDuration: 200   // 缩放时长
    readonly property real closeTargetScale: 0.88   // 目标缩放比例
    readonly property int closeAnimDelay: 0         // 动画延迟

    // 最小化动画参数
    readonly property int minUpOffset: 16        // 向上偏移像素
    readonly property int minDownOffset: 140     // 向下偏移最大像素
    readonly property int minUpDuration: 160     // 上升动画时长
    readonly property int minDownDuration: 200   // 下降动画时长
    readonly property int minFadeDuration: 350   // 淡出动画时长

    // 只要处于 Windowed/AutomaticVisibility，就持续维护 lastNormal
    function _maybeRecordIfNormal() {
        if ((win.visibility === Window.AutomaticVisibility || win.visibility === Window.Windowed)
                && !geomAnim.running && !startupFX.running && !_freezeRecord) {
            lastNormalGeom = Qt.rect(win.x, win.y, win.width, win.height);
        }
    }

    // 绑定几何变化，自动记录
    onXChanged: _maybeRecordIfNormal()
    onYChanged: _maybeRecordIfNormal()
    onWidthChanged: _maybeRecordIfNormal()
    onHeightChanged: _maybeRecordIfNormal()

    readonly property int durFast: 80
    readonly property int durMed: 260       // 动画时长
    readonly property int debounceMs: 300   // 防抖时间应大于动画时长
    property double _lastToggleTS: 0

    // 动画目标值
    property int _toX: win.x
    property int _toY: win.y
    property int _toW: win.width
    property int _toH: win.height
    // 动画目标状态："" | "max" | "normal" | "min" | "close"
    property string _animTarget: ""

    // 几何和透明度动画
    ParallelAnimation {
        id: geomAnim
        NumberAnimation { target: win; property: "x";      duration: win.enableAnim ? win.durMed : 0; easing.type: Easing.OutCubic; to: win._toX }
        NumberAnimation { target: win; property: "y";      duration: win.enableAnim ? win.durMed : 0; easing.type: Easing.OutCubic; to: win._toY }
        NumberAnimation { target: win; property: "width";  duration: win.enableAnim ? win.durMed : 0; easing.type: Easing.OutCubic; to: win._toW }
        NumberAnimation { target: win; property: "height"; duration: win.enableAnim ? win.durMed : 0; easing.type: Easing.OutCubic; to: win._toH }
        NumberAnimation { target: win; property: "opacity"; duration: win.enableAnim ? win.durMed : 0; easing.type: Easing.OutCubic; to: win._animTarget === "min" || win._animTarget === "close" ? 0 : 1 }
        onStopped: {
            if (win._animTarget === "max") {
                win.visibility = Window.Maximized;
            } else if (win._animTarget === "min") {
                win.showMinimized();
                Qt.callLater(() => {
                    win.opacity = 1.0;
                });
            } else if (win._animTarget === "close") {
                win.close();
            } else if (win._animTarget === "normal") {
                // 结束自定义还原动画后再切换到 Windowed，避免 WM 抢占几何
                // 切到 Windowed 后，立刻把我们记录的 normal 几何回写一遍，覆盖 WM 可能回灌的缓存值
                win.visibility = Window.Windowed;
                Qt.callLater(() => {
                    win.x = win.lastNormalGeom.x;
                    win.y = win.lastNormalGeom.y;
                    win.width = win.lastNormalGeom.width;
                    win.height = win.lastNormalGeom.height;
                    if (win._freezeRecord)
                        win._freezeRecord = false;
                });
            }
            win._animTarget = "";
        }
    }

    function runGeom(x, y, w, h) {
        _toX = x;
        _toY = y;
        _toW = w;
        _toH = h;
        geomAnim.restart();
    }

    // 停止并复位启动动画，避免与最大化过渡叠加引起抖动
    function _resetStartupFX() {
        if (startupFX.running) {
            startupFX.stop();
        }
        // 复位变换到静止态
        startupTrans.y = 0;
        startupRot.angle = 0;
        startupScale.xScale = 1.0;
        startupScale.yScale = 1.0;
        shell.opacity = 1.0;
    }

    function maximizeSmooth() {
        if (win.isMaximized) return;
        _resetStartupFX();
        lastNormalGeom = Qt.rect(win.x, win.y, win.width, win.height);
        const g = Qt.rect(0, 0, Screen.desktopAvailableWidth, Screen.desktopAvailableHeight);
        win._animTarget = "max";
        runGeom(g.x, g.y, g.width, g.height);
    }

    // 仅用于"最大化 -> 还原"的平滑过渡
    function restoreSmooth() {
        if (!win.isMaximized) return;
        _resetStartupFX();
        // 冻结自动记录，避免临时设置到屏幕大几何时覆盖 lastNormalGeom
        // 在动画开始前冻结记录，避免过渡阶段覆盖 lastNormalGeom
        _freezeRecord = true;
        win.showNormal(); // 必须先切回 Normal，才能自由控制几何
        
        // 从当前最大化位置开始动画，避免闪烁
        const g = Qt.rect(0, 0, Screen.desktopAvailableWidth, Screen.desktopAvailableHeight);
        win.x = g.x; win.y = g.y; win.width = g.width; win.height = g.height;
        Qt.callLater(function() {
        // 不调用 showNormal()，避免 WM 回灌其缓存的 normal 几何
        // 直接做几何动画，动画结束后在 onStopped 中切换到 Windowed 并回写 lastNormalGeom
        win._animTarget = "normal";
        runGeom(lastNormalGeom.x, lastNormalGeom.y, lastNormalGeom.width, lastNormalGeom.height);
            // 动画已开始，解除冻结，避免中间写入
            Qt.callLater(function(){ _freezeRecord = false; });
        });
    }

    // 最小化动画
    function minimizeSmooth() {
        if (win.visibility === Window.Minimized || minFX.running) return;
        
        // 记录最小化前的可见状态
        win._preMinVis = win.visibility;

        // 仅在普通窗口时更新 lastNormalGeom 用于恢复
        if (win.visibility === Window.Windowed || win.visibility === Window.AutomaticVisibility) {
            lastNormalGeom = Qt.rect(win.x, win.y, win.width, win.height);
        }
        
        win._animTarget = "min";
        
        // 停止其他可能的动画
        if (geomAnim.running) geomAnim.stop();
        if (closeFX.running) closeFX.stop();
        
        minFX.start();
    }

    // 关闭动画
    function closeSmooth() {
        if (closeFX.running) return;
        _resetStartupFX();
        win._animTarget = "close";  // 标记状态
        if (geomAnim.running) geomAnim.stop();
        closeFX.start();
    }

    // 最大化 <-> 还原
    function _debouncedToggleMaxRestore() {
        const t = Date.now();
        if (t - _lastToggleTS < debounceMs)
            return;
        _lastToggleTS = t;

        win.isMaximized ? restoreSmooth() : maximizeSmooth();
    }

    // 获取当前 DPR
    readonly property real dpr: Screen.devicePixelRatio
    readonly property int hit: Math.round(6 * dpr)
    readonly property int cornerHit: Math.round(10 * dpr)

    // 播放启动音乐
    QtObject { 
        id: startupSoundPath
        // 内置音乐路径
        property string path
        readonly property string startupSound_A: "qrc:/res/audio/startupA.ogg"
        readonly property string startupSound_B: "qrc:/res/audio/startupB.ogg"
        readonly property string startupSound_C: "qrc:/res/audio/startupC.ogg"
        readonly property string startupSound_D: "qrc:/res/audio/startupD.ogg"
        path: Settings.init("StartupSoundPath", startupSound_D)
    }
    MediaPlayer {
        id: startupPlayer
        source: startupSoundPath.path
        audioOutput: AudioOutput {
            id: out
            volume: 1.0
            muted: false
        }
        Component.onCompleted: Qt.callLater(() => {
            // 判断是否播放启动音乐
            if (Settings.init_bool("EnableStartupSound", true))
                play();
        })
        onErrorOccurred: (error, errorString) => {
            console.warn("[MediaPlayer] error:", error, errorString);
        }
    }

    // 启动动画组（调整时序）
    ParallelAnimation {
        id: startupFX
        running: false

        // 不透明度动画立即开始
        SequentialAnimation {
            NumberAnimation { 
                target: shell
                property: "opacity"
                from: 0
                to: 1.0
                duration: win.enableAnim ? win.startupFadeDuration : 0
                easing.type: Easing.OutCubic
            }
        }

        // 缩放动画（与旋转同步）
        SequentialAnimation {
            NumberAnimation {
                target: startupScale
                property: "xScale"
                from: win.startupInitialScale
                to: 1.0
                duration: win.enableAnim ? win.startupFirstStageDuration : 0
                easing.type: Easing.OutBack
                easing.overshoot: win.startupBackOvershoot * 0.3  // 第一阶段回弹较小
            }
            NumberAnimation {
                target: startupScale
                property: "xScale"
                from: 1.0
                to: 1.0
                duration: win.enableAnim ? win.startupSecondStageDuration : 0
                easing.type: Easing.OutBack
                easing.overshoot: win.startupBackOvershoot
            }
        }

        // 位移动画保持较长时间
        SequentialAnimation {
            NumberAnimation {
                target: startupTrans
                property: "y"
                from: -win.startupOffsetY
                to: 0
                duration: win.enableAnim ? (win.startupFirstStageDuration + win.startupSecondStageDuration) : 0
                easing.type: Easing.OutBack
                easing.overshoot: win.startupBackOvershoot
            }
        }

        // 旋转动画（第一阶段就完成）
        SequentialAnimation {
            NumberAnimation {
                target: startupRot
                property: "angle"
                from: win.startupInitialAngle
                to: 0
                duration: win.enableAnim ? win.startupFirstStageDuration : 0
                easing.type: Easing.OutBack
                easing.overshoot: win.startupBackOvershoot * 0.3  // 第一阶段回弹较小
            }
        }

        onFinished: {
            // 清理变换
            startupTrans.y = 0
            startupRot.angle = 0
            startupScale.xScale = 1.0
            startupScale.yScale = 1.0
            shell.opacity = 1.0
        }
    }

    Component.onCompleted: {
        if (win.enableAnim) {
            startupFX.start()
        } else {
            // 动画关闭时，直接设置到最终状态
            startupTrans.y = 0
            startupRot.angle = 0
            startupScale.xScale = 1.0
            startupScale.yScale = 1.0
            shell.opacity = 1.0
        }
    }

    function tr(id, fallback) {
        var s = qsTrId(id);
        return (s === id || s === "") ? fallback : s;
    }

    // ==== 快捷键 ====
    Shortcut {
        sequences: [StandardKey.Close]
        onActivated: win.closeSmooth()
    }
    Shortcut {
        sequences: ["Alt+F10"]
        onActivated: win._debouncedToggleMaxRestore()
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
        id: shell                                   // 组件ID
        anchors.fill: parent                        // 填满父项
        dpr: Screen.devicePixelRatio                // 传入设备像素比
        inset: win.squareCorners ? 0 : win.inset    // 阴影厚度
        cornerRadius: win.squareCorners ? 0 : win.cornerRadius // 在最大化或过渡中立即置零，避免过渡动画
        squareCorners: win.squareCorners            // 是否启用圆角
        frameColor: theme.backgroundColor           // 内容框底色
        opacity: 0                                  // 初始不透明度
        enableAnim: win.enableAnim                  // 传递动画开关到 ShadowFrame

        // ==== 动画执行 ====
        transform: [
            Rotation {
                id: startupRot
                angle: win.startupInitialAngle
                origin.x: shell.width / 2
                origin.y: shell.height / 2
                axis { x: 0; y: 0; z: 1 }
            },
            Scale {
                id: startupScale
                origin.x: shell.width / 2
                origin.y: shell.height / 2
                xScale: win.startupInitialScale
                yScale: xScale
            },
            Translate {
                id: startupTrans
                y: -win.startupOffsetY
            },
            Scale {
                id: closeScale
                origin.x: shell.width / 2
                origin.y: shell.height / 2
                xScale: 1.0
                yScale: xScale
            },
            Translate {
                id: minTrans
                y: 0
            }
        ]

        // ==== 关闭动画 ====
        ParallelAnimation {
            id: closeFX
            running: false

            // 缩放动画
            NumberAnimation {
                target: closeScale
                property: "xScale"
                from: 1.0
                to: win.closeTargetScale
                duration: win.enableAnim ? win.closeScaleDuration : 0
                easing.type: Easing.OutQuad
            }

            // 不透明度动画
            SequentialAnimation {
                // 稍微提前开始淡出
                PauseAnimation { duration: win.enableAnim ? win.closeAnimDelay : 0 }
                NumberAnimation {
                    target: shell
                    property: "opacity"
                    from: 1.0
                    to: 0
                    duration: win.enableAnim ? win.closeFadeDuration : 0
                    easing.type: Easing.OutCubic
                }
            }

            onFinished: win.close()
        }

        // ==== 最小化动画 ====
        ParallelAnimation {
            id: minFX
            running: false

            // 位移动画（先上后下）
            SequentialAnimation {
                NumberAnimation {
                    target: minTrans
                    property: "y"
                    from: 0
                    to: -win.minUpOffset
                    duration: win.enableAnim ? win.minUpDuration : 0
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: minTrans
                    property: "y"
                    to: win.minDownOffset
                    duration: win.enableAnim ? win.minDownDuration : 0
                    easing.type: Easing.InCubic  // 使用 InCubic 让下落更快
                }
            }

            // 透明度动画（开始下落时淡出）
            SequentialAnimation {
                PauseAnimation { duration: win.enableAnim ? win.minUpDuration : 0 }
                NumberAnimation {
                    target: shell
                    property: "opacity"
                    from: 1.0
                    to: 0
                    duration: win.enableAnim ? win.minFadeDuration : 0
                    easing.type: Easing.OutCubic
                }
            }

            onFinished: {
                // 恢复到系统最小化，并复位变换
                win.showMinimized();
                minTrans.y = 0
                shell.opacity = 1.0
            }
        }

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

                property real bandWidth: width
                property real pxPerSecond: 120
                property real dpr: Screen.devicePixelRatio

                // 累计进度（秒），代替绝对时间，支持在拉伸时暂停
                property real progressSec: 0
                property real _lastTick: 0

                function _nowSec() { return Date.now() / 1000.0; }

                Timer {
                    id: raf
                    interval: 33
                    repeat: true
                    running: win.visibility !== Window.Hidden  // 只在窗口处于后台时暂停
                    onTriggered: {
                        const now = flowFX._nowSec();
                        let dt = now - flowFX._lastTick;
                        flowFX._lastTick = now;
                        // 在拉伸过程中不推进进度；恢复时避免一次性跳动，限制最大步长
                        if (!win.isResizing) {
                            dt = Math.max(0, Math.min(dt, 0.08)); // 限制到 ~80ms
                            flowFX.progressSec += dt;
                        }
                        flowFX.requestPaint();
                    }
                }

                Component.onCompleted: {
                    _lastTick = _nowSec();
                    requestPaint();
                    raf.start();
                }

                onVisibleChanged: {
                    // 重置节拍，避免可见性变化带来的大步长
                    flowFX._lastTick = flowFX._nowSec();
                    requestPaint();
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onDprChanged: requestPaint()
                Connections {
                    target: win
                    function onVisibilityChanged() {
                        flowFX._lastTick = flowFX._nowSec();
                        flowFX.requestPaint();
                    }
                }

                function colors() {
                    return (theme.gradientColors && theme.gradientColors.length > 0) ? theme.gradientColors : [theme.menuGradTop, theme.menuGradMid, theme.menuGradBot];
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
                    if (cols.length > 0 && cols[0] !== cols[cols.length - 1])
                        cols.push(cols[0]);

                    const bw = Math.max(1, bandWidth);
                    const elapsed = progressSec; // 使用累计进度，避免暂停期间跳变
                    const offsetPx = (elapsed * pxPerSecond) % bw;

                    let startX = -offsetPx - bw;
                    while (startX < w + bw) {
                        const xi = Math.round(startX);
                        const g = ctx.createLinearGradient(xi, 0, xi + bw, 0);
                        const n = cols.length;
                        for (let i = 0; i < n; ++i) {
                            const t = (n <= 1) ? 0.5 : i / (n - 1);
                            g.addColorStop(t, cols[i]);
                        }
                        ctx.fillStyle = g;
                        ctx.fillRect(xi - 1, 0, bw + 2, h);
                        startX += bw;
                    }
                }
            }

            // —— 左侧标题 —__
            Label {
                id: titleText
                text: win.tr("csi.title", "CSI")
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: theme.menuTextColor
                font.pixelSize: 26
                font.weight: Font.DemiBold
                z: 1
            }

            // —— 中部导航 —__
            Item {
                id: navWrap
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                z: 1
                readonly property int spacing: 10
                width: tabStart.width + spacing + tabSettings.width
                height: Math.max(tabStart.height, tabSettings.height)

                // 滑动高亮块（不参与布局，置于按钮下方）
                Rectangle {
                    id: tabHighlight
                    radius: 8
                    height: 36
                    y: (navWrap.height - height) / 2
                    color: theme.menuTextColor
                    z: 0
                    width: (win.currentTab === 0 ? tabStart.width : tabSettings.width)
                    x: (win.currentTab === 0 ? tabStart.x : tabSettings.x)
                    Behavior on x { enabled: win.enableAnim; NumberAnimation { duration: win.enableAnim ? win.durMed : 0; easing.type: Easing.OutCubic } }
                    Behavior on width { enabled: win.enableAnim; NumberAnimation { duration: win.enableAnim ? win.durMed : 0; easing.type: Easing.OutCubic } }
                }

                ToolButton {
                    id: tabStart
                    x: 0
                    y: (navWrap.height - height) / 2
                    text: win.tr("csi.tab.start", "启动")
                    checkable: false
                    padding: 10
                    height: 36
                    implicitHeight: 36
                    implicitWidth: Math.max(88, contentItem.implicitWidth + 20)
                    onClicked: win.currentTab = 0
                    scale: pressed ? 0.98 : 1.0
                    z: 1
                    Behavior on scale {
                        enabled: win.enableAnim
                        NumberAnimation { duration: win.enableAnim ? win.durFast : 0; easing.type: Easing.OutCubic }
                    }
                    background: Rectangle {
                        radius: 8
                        color: (tabStart.hovered && win.currentTab !== 0) ? theme.hoverMask : "transparent"
                    }
                    // 基础文字 + 高亮裁剪叠加
                    contentItem: Item {
                        id: startContent
                        anchors.fill: parent
                        // 计算与高亮块在本地坐标的交集
                        property real hiLeft: {
                            var pL = startContent.mapFromItem(navWrap, tabHighlight.x, 0).x
                            return Math.max(0, Math.min(pL, startContent.width))
                        }
                        property real hiRight: {
                            var pR = startContent.mapFromItem(navWrap, tabHighlight.x + tabHighlight.width, 0).x
                            return Math.max(0, Math.min(pR, startContent.width))
                        }
                        property real hiWidth: Math.max(0, hiRight - hiLeft)

                        // 底层常规文字
                        Label {
                            anchors.fill: parent
                            text: tabStart.text
                            font.pixelSize: 15
                            color: theme.menuTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        // 仅在交集区域显示的高亮文字
                        Item {
                            id: startClip
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            x: startContent.hiLeft
                            width: startContent.hiWidth
                            clip: true
                            visible: width > 0
                            // 使用与底层相同排版，但整体左移到与父对齐，由 clip 截断
                            Label {
                                x: -startClip.x
                                width: startContent.width
                                height: startContent.height
                                text: tabStart.text
                                font.pixelSize: 15
                                color: theme.menuGradTop
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                ToolButton {
                    id: tabSettings
                    x: tabStart.width + navWrap.spacing
                    y: (navWrap.height - height) / 2
                    text: win.tr("csi.tab.settings", "设置")
                    checkable: false
                    padding: 10
                    height: 36
                    implicitHeight: 36
                    implicitWidth: Math.max(88, contentItem.implicitWidth + 20)
                    onClicked: win.currentTab = 1
                    scale: pressed ? 0.98 : 1.0
                    z: 1
                    Behavior on scale {
                        enabled: win.enableAnim
                        NumberAnimation { duration: win.enableAnim ? win.durFast : 0; easing.type: Easing.OutCubic }
                    }
                    background: Rectangle {
                        radius: 8
                        color: (tabSettings.hovered && win.currentTab !== 1) ? theme.hoverMask : "transparent"
                    }
                    // 基础文字 + 高亮裁剪叠加
                    contentItem: Item {
                        id: settingsContent
                        anchors.fill: parent
                        // 计算与高亮块在本地坐标的交集
                        property real hiLeft: {
                            var pL = settingsContent.mapFromItem(navWrap, tabHighlight.x, 0).x
                            return Math.max(0, Math.min(pL, settingsContent.width))
                        }
                        property real hiRight: {
                            var pR = settingsContent.mapFromItem(navWrap, tabHighlight.x + tabHighlight.width, 0).x
                            return Math.max(0, Math.min(pR, settingsContent.width))
                        }
                        property real hiWidth: Math.max(0, hiRight - hiLeft)

                        // 底层常规文字
                        Label {
                            anchors.fill: parent
                            text: tabSettings.text
                            font.pixelSize: 15
                            color: theme.menuTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        // 仅在交集区域显示的高亮文字
                        Item {
                            id: settingsClip
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            x: settingsContent.hiLeft
                            width: settingsContent.hiWidth
                            clip: true
                            visible: width > 0
                            Label {
                                x: -settingsClip.x
                                width: settingsContent.width
                                height: settingsContent.height
                                text: tabSettings.text
                                font.pixelSize: 15
                                color: theme.menuGradTop
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }

            // —— 右上角窗口控制 —__
            Row {
                id: rowControls
                spacing: 6
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                z: 0

                // SVG图标文件路径
                readonly property string iconMin: "qrc:/res/icon/window/min.svg"
                readonly property string iconMax: "qrc:/res/icon/window/max.svg"
                readonly property string iconRes: "qrc:/res/icon/window/restore.svg"
                readonly property string iconClose: "qrc:/res/icon/window/close.svg"

                ToolButton {
                    id: btnMin
                    implicitWidth: 36
                    implicitHeight: 28
                    display: AbstractButton.IconOnly
                    icon.source: rowControls.iconMin
                    icon.color: theme.defaultText
                    icon.width: 14
                    icon.height: 14
                    onClicked: win.minimizeSmooth()
                    background: Rectangle {
                        radius: 6
                        color: btnMin.hovered ? theme.hoverMask : "transparent"
                    }
                }
                ToolButton {
                    id: btnMax
                    implicitWidth: 36
                    implicitHeight: 28
                    display: AbstractButton.IconOnly
                    icon.source: win.squareCorners ? rowControls.iconRes : rowControls.iconMax
                    icon.color: theme.defaultText
                    icon.width: 14
                    icon.height: 14
                    onClicked: win._debouncedToggleMaxRestore()
                    background: Rectangle {
                        radius: 6
                        color: btnMax.hovered ? theme.hoverMask : "transparent"
                    }
                }
                ToolButton {
                    id: btnClose
                    implicitWidth: 36
                    implicitHeight: 28
                    display: AbstractButton.IconOnly
                    icon.source: rowControls.iconClose
                    icon.color: theme.defaultText
                    icon.width: 14
                    icon.height: 14
                    onClicked: win.closeSmooth()
                    background: Rectangle {
                        radius: 6
                        color: btnClose.hovered ? "#e5484d" : "transparent"
                    }
                }
            }

            // 最大化时鼠标拖动还原
            DragHandler {
                id: dragTitle
                target: null
                grabPermissions: PointerHandler.CanTakeOverFromAnything
                onActiveChanged: if (active) {
                    const p = dragTitle.centroid.scenePosition;
                    if (win.isMaximized) {
                        // 最大化：取消动画，立即还原到普通窗口几何并开始拖动
                        if (geomAnim.running) geomAnim.stop();
                        // 在切换到 Normal 之前冻结 lastNormalGeom 的记录，避免被临时几何污染
                        win._freezeRecord = true;
                        win.showNormal();
                        Qt.callLater(() => {
                            var w = Math.max(win.minW, win.lastNormalGeom.width);
                            var h = Math.max(win.minH, win.lastNormalGeom.height);
                            var offX = Math.max(0, Math.min(w, p.x));
                            var offY = Math.max(0, Math.min(h, p.y));
                            win.width = w;
                            win.height = h;
                            win.x = Math.round(p.x - offX);
                            win.y = Math.round(p.y - Math.min(offY, titleBar.height));
                            // 立即解冻，恢复正常记录
                            Qt.callLater(() => { win._freezeRecord = false; });
                            Qt.callLater(win.startSystemMove);
                        });
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
            onActiveChanged: {
                win._resizeCounter += active ? 1 : -1;
                if (active)
                    win.startSystemResize(Qt.TopEdge)
            }
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
            onActiveChanged: {
                win._resizeCounter += active ? 1 : -1;
                if (active)
                    win.startSystemResize(Qt.BottomEdge)
            }
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
            onActiveChanged: {
                win._resizeCounter += active ? 1 : -1;
                if (active)
                    win.startSystemResize(Qt.LeftEdge)
            }
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
            onActiveChanged: {
                win._resizeCounter += active ? 1 : -1;
                if (active)
                    win.startSystemResize(Qt.RightEdge)
            }
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
            onActiveChanged: {
                win._resizeCounter += active ? 1 : -1;
                if (active)
                    win.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
            }
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
            onActiveChanged: {
                win._resizeCounter += active ? 1 : -1;
                if (active)
                    win.startSystemResize(Qt.TopEdge | Qt.RightEdge)
            }
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
            onActiveChanged: {
                win._resizeCounter += active ? 1 : -1;
                if (active)
                    win.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
            }
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
            onActiveChanged: {
                win._resizeCounter += active ? 1 : -1;
                if (active)
                    win.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
            }
        }
    }
}
