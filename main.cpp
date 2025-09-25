// main.cpp - 程序入口
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QFile>
#include <QMutex>
#include <QQuickStyle>
#include <QFontDatabase>
#include <QQuickWindow>
#include <QDir>
#include <QThread>
// ==== 自定义头文件 ====
#include "backend.h"
#include "settings.h"

// ==== 日志处理函数组 ====
static std::atomic_bool g_enableLogging{ true };

static void setLoggingEnabled(bool enabled) {
    g_enableLogging.store(enabled, std::memory_order_relaxed);
}

static void fileMessageHandler(QtMsgType type, const QMessageLogContext& ctx, const QString& msg) {
    if (!g_enableLogging.load(std::memory_order_relaxed)) {
        return; // 直接丢弃日志
    }

    static QFile file("logs/app.log");
    static QMutex mtx;
    static bool inited = [] {
        QDir().mkpath("logs");
        if (!file.open(QIODevice::Append | QIODevice::Text)) {
            fprintf(stderr, "Failed to open log file: %s\n", qPrintable(file.errorString()));
        }
        return true;
        }();
    Q_UNUSED(inited);

    const char* level =
        type == QtDebugMsg ? "DBG" : type == QtInfoMsg ? "INF" :
        type == QtWarningMsg ? "WRN" :  type == QtCriticalMsg ? "ERR" : "FTL";


    QMutexLocker lock(&mtx);
    QTextStream out(&file);
    out << QDateTime::currentDateTime().toString(Qt::ISODateWithMs)
        << " [" << quintptr(QThread::currentThreadId()) << "] "
        << level << " " << msg;
    if (ctx.category && *ctx.category)
        out << " (" << ctx.category << ")";
    out << '\n';
    out.flush();
}

// ==== 主函数 ====
int main(int argc, char* argv[]) {

	// 初始化
    setLoggingEnabled(true);                            // 是否启用日志输出
	qInstallMessageHandler(fileMessageHandler);         // 接管日志系统
	QQuickStyle::setStyle("Material");					// 设置默认样式
	QApplication app(argc, argv);                       // 创建应用程序对象

	// 加载字体
	int id = QFontDatabase::addApplicationFont(":/res/font/ChironGoRoundTC-Medium.ttf");
	if (id != -1) {
		QString family = QFontDatabase::applicationFontFamilies(id).at(0);
		QFont font(family);
		font.setPixelSize(14);  // 默认字号
		app.setFont(font);      // 设置为全局字体
    } 
	else {
        qWarning() << "字体加载失败！";
    }
	
	app.setWindowIcon(QIcon(":/res/icon/main/construction.svg"));	        // 设置程序图标
	QQmlApplicationEngine engine;											// 构造 engine 对象
	if (!Settings::instance()) Settings* settings = new Settings(&engine);	// 构造 .ini 配置文件操作函数
	engine.loadFromModule("csi", "Main");									// 加载 Main.qml 前端入口

	// 打印 QML 加载时的警告
	QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError>& ws) { for (auto& w : ws) qWarning().noquote() << w.toString(); });
	if (engine.rootObjects().isEmpty()) return -1;		// 若初始化失败，退出程序

	// 进入事件循环
	return app.exec();
}