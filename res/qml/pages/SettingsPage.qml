// SettingsPage.qml - 设置页（测试）
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import csi

Item {
    id: root
    anchors.fill: parent

    // —— 外部可选注入：顶层不裁切的 overlay 容器传进来 ——
    property Item overlayRoot: null
    // —— 外部可选强制：全屏时强制全覆盖 ——
    property bool forceFullCover: false

    // 安全读取 Window
    Item { id: _probe; anchors.fill: parent; visible: false }
    property var _win: _probe.Window.window
    readonly property bool _autoCoverFull:
        _win && (_win.visibility === Window.Maximized || _win.visibility === Window.FullScreen)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        Label {
            text: qsTr("这是设置页!")
            font.pixelSize: 22
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignHCenter

            // === Info：1 个选项 ===
            Button {
                text: qsTr("Show Info")
                icon.source: "qrc:/res/icon/message/info.svg"
                onClicked: root.showInfo()
            }

            // === Warning：2 个选项 ===
            Button {
                text: qsTr("Show Warning")
                icon.source: "qrc:/res/icon/message/warning.svg"
                onClicked: root.showWarning()
            }

            // === Error：3 个选项 ===
            Button {
                text: qsTr("Show Error")
                icon.source: "qrc:/res/icon/message/error.svg"
                onClicked: root.showError()
            }
        }
    }

    // NiceDialog 实例
    NiceDialog {
        id: dlg
        // 轻微上移
        centerYOffset: -20
        // 全屏/最大化时全覆盖；外部可强制
        overlayForceFullCover: root.forceFullCover || root._autoCoverFull

        // 控制台日志
        property string kind: ""
        onAccepted: {
            if      (kind === "info")    console.log("[Info] OK clicked")
            else if (kind === "warning") console.log("[Warning] Proceed (primary) clicked")
            else if (kind === "error")   console.log("[Error] Primary clicked")
        }
        onRejected: {
            if      (kind === "warning") console.log("[Warning] Cancel (secondary) clicked")
            else if (kind === "error")   console.log("[Error] Secondary clicked")
        }
        onTertiaryClicked: if (kind === "error") console.log("[Error] Tertiary clicked")
    }

    // 仅当外部提供 overlayRoot 时，才把 Popup 的 parent 绑定过去
    Binding {
        target: dlg
        property: "parent"
        value: root.overlayRoot
        when: root.overlayRoot !== null
    }

    // === 触发函数 ===
    function showInfo() {
        dlg.kind = "info"
        dlg.title = qsTr("信息")
        dlg.text  = qsTr("这是一个信息提示。")
        dlg.iconSource = "qrc:/res/icon/message/info.svg"
        dlg.destructive = false
        dlg.primaryText   = qsTr("OK")
        dlg.secondaryText = ""
        dlg.tertiaryText  = ""
        dlg.open()
    }

    function showWarning() {
        dlg.kind = "warning"
        dlg.title = qsTr("警告")
        dlg.text  = qsTr("此操作可能影响设置，是否继续？")
        dlg.iconSource = "qrc:/res/icon/message/warning.svg"
        dlg.destructive = false
        dlg.primaryText   = qsTr("继续")
        dlg.secondaryText = qsTr("取消")
        dlg.tertiaryText  = ""
        dlg.open()
    }

    function showError() {
        dlg.kind = "error"
        dlg.title = qsTr("错误")
        dlg.text  = qsTr("发生错误。你要如何处理？")
        dlg.iconSource = "qrc:/res/icon/message/error.svg"
        dlg.destructive = true
        dlg.primaryText   = qsTr("重试")
        dlg.secondaryText = qsTr("忽略")
        dlg.tertiaryText  = qsTr("报告")
        dlg.open()
    }
}
