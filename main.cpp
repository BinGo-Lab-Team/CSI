// main.cpp - 程序入口
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QLoggingCategory>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QMutex>
#include <QIcon>
#include <QDirIterator>
#include <QMessageBox>
#include <QQuickStyle>
#include <QFontDatabase>
#include <QFont>
#include <QQuickWindow>
// ==== 自定义头文件 ====
#include "backend.h"

// ==== 日志处理函数 ====
static void fileMessageHandler(QtMsgType type, const QMessageLogContext& ctx, const QString& msg) {
	static QFile file("logs/app.log");
	static QMutex mtx;
	static bool inited = [] {
		QDir().mkpath("logs");
		file.open(QIODevice::Append | QIODevice::Text);
		return true;
		}();

	Q_UNUSED(inited);
	QString level =
		type == QtDebugMsg ? "DBG" : type == QtInfoMsg ? "INF" :
		type == QtWarningMsg ? "WRN" : type == QtCriticalMsg ? "CRT" : "FTL";

	QMutexLocker lock(&mtx);
	QTextStream out(&file);
	out << QDateTime::currentDateTime().toString(Qt::ISODateWithMs)
		<< " [" << (quintptr)QThread::currentThreadId() << "] "
		<< level << " " << msg << '\n';
	out.flush();
}

// ==== 主函数 ====
int main(int argc, char* argv[]) {

	// 初始化
	qInstallMessageHandler(fileMessageHandler);         // 接管日志系统
	QQuickStyle::setStyle("Material");					// 设置默认样式
	QApplication app(argc, argv);                       // 创建应用程序对象

	// 加载字体
	int id = QFontDatabase::addApplicationFont(":/res/font/AiDianFengYaHei.ttf");
	if (id != -1) {
		QString family = QFontDatabase::applicationFontFamilies(id).at(0);
		QFont font(family);
		font.setPixelSize(14);  // 默认字号
		app.setFont(font);      // 设置为全局字体
	}                           // 若加载成功，更改全局默认字体

	app.setWindowIcon(QIcon(":/res/icon/main/construction.svg"));	// 设置窗口图标
	QQmlApplicationEngine engine;									// 创建 QML 引擎对象
	engine.loadFromModule("csi", "Main");							// 加载 qml 入口文件

	// 打印错误
	QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError>& ws) { for (auto& w : ws) qWarning().noquote() << w.toString(); });
	if (engine.rootObjects().isEmpty()) return -1;      // 若初始化失败，退出程序

	// 进入事件循环
	return app.exec();
}
