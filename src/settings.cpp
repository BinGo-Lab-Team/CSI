#include "settings.h"

#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>
#include <QTextStream>
#include <QStringConverter>
#include <QFile>

Settings::Settings(QObject* parent)
    : QObject(parent)
{
    s_instance = this;
}

static bool endsWithIni(const QString& path) {
    return path.endsWith(QStringLiteral(".ini"), Qt::CaseInsensitive);
}

static bool isReadableIfExists(const QString& path) {
    QFileInfo fi(path);
    if (!fi.exists()) return true;                    // 不存在时允许后续自动创建
    if (!fi.isFile()) return false;
    return fi.isReadable();
}

static QString resolveConfigPath() {
    // 1) 命令行参数优先：--config-path <path> 或 --config-path=<path>
    const QStringList args = QCoreApplication::arguments();
    for (int i = 1; i < args.size(); ++i) {
        const QString& a = args.at(i);
        if (a.startsWith(QStringLiteral("--config-path="))) {
            const QString p = a.mid(static_cast<int>(QStringLiteral("--config-path=").size()));
            if (endsWithIni(p) && isReadableIfExists(p)) return p;
        }
        if (a == QStringLiteral("--config-path") && i + 1 < args.size()) {
            const QString p = args.at(i + 1);
            if (endsWithIni(p) && isReadableIfExists(p)) return p;
        }
    }

    // 2) 环境变量：CSI_CONFIG_PATH
    if (const QByteArray env = qgetenv("CSI_CONFIG_PATH"); !env.isEmpty()) {
        const QString p = QString::fromLocal8Bit(env);
        if (endsWithIni(p) && isReadableIfExists(p)) return p;
    }

    // 3) 程序目录下的 config.ini（兜底，必然以 .ini 结尾）
    const QString appDir = QCoreApplication::applicationDirPath();
    return QDir(appDir).filePath(QStringLiteral("config.ini"));
}

QString Settings::configPath() const {
    return resolveConfigPath();
}

void Settings::ensureFileExists() const {
    const QString path = configPath();
    QFileInfo fi(path);
    QDir dir = fi.dir();
    if (!dir.exists()) {
        dir.mkpath(QStringLiteral("."));
    }
    if (!fi.exists()) {
        QFile f(path);
        if (f.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream out(&f);
            out.setEncoding(QStringConverter::Utf8);
            out << "; config.ini (auto-created)\n";
            f.close();
        }
    }
}

QVariant Settings::read(const QString& key) {
    // 默认节名 General：在 INI 中对应根级键
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    return ini.value(key, QVariant());
}

QVariant Settings::read(const QString& section, const QString& key) {
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    if (section.isEmpty() || section.compare(QStringLiteral("General"), Qt::CaseInsensitive) == 0) {
        return ini.value(key, QVariant());
    }
    ini.beginGroup(section);
    const QVariant val = ini.value(key, QVariant());
    ini.endGroup();
    return val;
}

void Settings::write(const QString& key, const QVariant& value) {
    // 默认节名 General：写入根级键
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    ini.setValue(key, value);
    ini.sync();
}

void Settings::write(const QString& section, const QString& key, const QVariant& value) {
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    if (section.isEmpty() || section.compare(QStringLiteral("General"), Qt::CaseInsensitive) == 0) {
        ini.setValue(key, value);
        ini.sync();
        return;
    }
    ini.beginGroup(section);
    ini.setValue(key, value);
    ini.endGroup();
    ini.sync();
}
