#include "settings.h"
#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>
#include <QTextStream>
#include <QStringConverter>
#include <QFile>
#include <QDebug>

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
    if (!fi.exists()) return true;
    if (!fi.isFile()) return false;
    return fi.isReadable();
}

static QString resolveConfigPath() {
    // 1) 命令行参数优先：--config-path <path> 或 --config-path=<path>
    const QStringList args = QCoreApplication::arguments();
    for (qsizetype i = 1; i < args.size(); ++i) {
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

// Helpers for error logging
static inline QString sectionLabel(const QString& section) {
    // For logging, show "General" when section is empty (top-level), otherwise show the section name.
    return section.isEmpty() ? QStringLiteral("General") : section;
}

static inline const char* settingsStatusToString(QSettings::Status s) {
    switch (s) {
    case QSettings::NoError: return "NoError";
    case QSettings::AccessError: return "AccessError";
    case QSettings::FormatError: return "FormatError";
    }
    return "Unknown";
}

static inline void logStatusIfError(const QSettings& ini, const QString& action, const QString& section, const QString& key)
{
    const auto st = ini.status();
    if (st != QSettings::NoError) {
        qWarning().noquote() << QStringLiteral("Settings::%1 error: %2 (section: %3, key: %4, config: %5)")
                                .arg(action,
                                     QString::fromLatin1(settingsStatusToString(st)),
                                     sectionLabel(section),
                                     key,
                                     ini.fileName());
    }
}

static QVariant readImpl(QSettings& ini, const QString& section, const QString& key)
{
    // Only an empty section refers to top-level keys. A section named "General" is a real group.
    const bool isTopLevel = section.isEmpty();
    if (isTopLevel) {
        if (ini.contains(key)) {
            const QVariant val = ini.value(key);
            logStatusIfError(ini, QStringLiteral("read"), QString(), key);
            return val;
        }
        qWarning().noquote() << QStringLiteral("Settings::read: key does not exist: %1 (section: %2, config: %3)")
                                .arg(key, QStringLiteral("General"), ini.fileName());
        logStatusIfError(ini, QStringLiteral("read"), QString(), key);
        return QVariant(QStringLiteral("ErrorNotExists"));
    }
    ini.beginGroup(section);
    const bool exists = ini.contains(key);
    QVariant result;
    if (exists) result = ini.value(key);
    ini.endGroup();

    if (exists) {
        logStatusIfError(ini, QStringLiteral("read"), section, key);
        return result;
    }
    qWarning().noquote() << QStringLiteral("Settings::read: key does not exist: %1 (section: %2, config: %3)")
                            .arg(key, section, ini.fileName());
    logStatusIfError(ini, QStringLiteral("read"), section, key);
    return QVariant(QStringLiteral("ErrorNotExists"));
}

QVariant Settings::read(const QString& key) {
    QSettings ini(configPath(), QSettings::IniFormat);
    return readImpl(ini, QString(), key);
}

QVariant Settings::read(const QString& section, const QString& key) {
    QSettings ini(configPath(), QSettings::IniFormat);
    return readImpl(ini, section, key);
}

QVariant Settings::init(const QString& key, const QVariant& value)
{
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);

    if (ini.contains(key)) {
        const QVariant v = ini.value(key);
        logStatusIfError(ini, QStringLiteral("init"), QString(), key);
        return v;
    }
    ini.setValue(key, value);
    ini.sync();
    logStatusIfError(ini, QStringLiteral("init"), QString(), key);
    if (ini.status() == QSettings::NoError) {
        // 发射初始化成功信号（新键被创建）
        emit settingChanged(sectionLabel(QString()), key, value);
        qInfo().noquote() << QStringLiteral("Settings::init: created key %1 in section %2 (config: %3)")
                             .arg(key, QStringLiteral("General"), configPath());
    }
    return value;
}

QVariant Settings::init(const QString& section, const QString& key, const QVariant& value)
{
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);

    const bool isTopLevel = section.isEmpty();

    if (isTopLevel) {
        if (ini.contains(key)) {
            const QVariant v = ini.value(key);
            logStatusIfError(ini, QStringLiteral("init"), QString(), key);
            return v;
        }
        ini.setValue(key, value);
        ini.sync();
        logStatusIfError(ini, QStringLiteral("init"), QString(), key);
        if (ini.status() == QSettings::NoError) {
            emit settingChanged(sectionLabel(QString()), key, value);
            qInfo().noquote() << QStringLiteral("Settings::init: created key %1 in section %2 (config: %3)")
                                 .arg(key, QStringLiteral("General"), configPath());
        }
        return value;
    }

    ini.beginGroup(section);
    const bool exists = ini.contains(key);
    QVariant ret;
    if (exists) ret = ini.value(key);
    else ini.setValue(key, value);
    ini.endGroup();

    if (!exists) {
        ini.sync();
        logStatusIfError(ini, QStringLiteral("init"), section, key);
        if (ini.status() == QSettings::NoError) {
            emit settingChanged(sectionLabel(section), key, value);
            qInfo().noquote() << QStringLiteral("Settings::init: created key %1 in section %2 (config: %3)")
                                 .arg(key, section, configPath());
        }
        return value;
    }
    logStatusIfError(ini, QStringLiteral("init"), section, key);
    return ret;
}

void Settings::write(const QString& key, const QVariant& value) {
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    ini.setValue(key, value);
    ini.sync();
    logStatusIfError(ini, QStringLiteral("write"), QString(), key);
    if (ini.status() == QSettings::NoError) {
        emit settingChanged(sectionLabel(QString()), key, value);
    }
}

void Settings::write(const QString& section, const QString& key, const QVariant& value) {
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    if (section.isEmpty()) {
        ini.setValue(key, value);
        ini.sync();
        logStatusIfError(ini, QStringLiteral("write"), QString(), key);
        if (ini.status() == QSettings::NoError) {
            emit settingChanged(sectionLabel(QString()), key, value);
        }
        return;
    }
    ini.beginGroup(section);
    ini.setValue(key, value);
    ini.endGroup();
    ini.sync();
    logStatusIfError(ini, QStringLiteral("write"), section, key);
    if (ini.status() == QSettings::NoError) {
        emit settingChanged(sectionLabel(section), key, value);
    }
}

// ===== Bool-only helpers =====
static inline bool variantToStrictBool(const QVariant& v, bool& ok)
{
    ok = false;
    // Accept only true/false literal or a QVariant that is strictly bool
    if (v.metaType().id() == QMetaType::Bool) { ok = true; return v.toBool(); }
    if (v.typeId() == QMetaType::Bool) { ok = true; return v.toBool(); }
    // Accept specific strings "true"/"false" (case-insensitive) only
    if (v.canConvert<QString>()) {
        const QString s = v.toString().trimmed();
        if (s.compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0) { ok = true; return true; }
        if (s.compare(QStringLiteral("false"), Qt::CaseInsensitive) == 0) { ok = true; return false; }
    }
    return false;
}

bool Settings::read_bool(const QString& key)
{
    QSettings ini(configPath(), QSettings::IniFormat);
    const QVariant v = readImpl(ini, QString(), key);
    bool ok = false;
    const bool b = variantToStrictBool(v, ok);
    if (!ok) {
        qWarning().noquote() << QStringLiteral("Settings::read_bool: invalid boolean at key %1 (section: %2, config: %3)")
                                .arg(key, QStringLiteral("General"), ini.fileName());
        logStatusIfError(ini, QStringLiteral("read_bool"), QString(), key);
        return false;
    }
    logStatusIfError(ini, QStringLiteral("read_bool"), QString(), key);
    return b;
}

bool Settings::read_bool(const QString& section, const QString& key)
{
    QSettings ini(configPath(), QSettings::IniFormat);
    const QVariant v = readImpl(ini, section, key);
    bool ok = false;
    const bool b = variantToStrictBool(v, ok);
    if (!ok) {
        qWarning().noquote() << QStringLiteral("Settings::read_bool: invalid boolean at key %1 (section: %2, config: %3)")
                                .arg(key, sectionLabel(section), ini.fileName());
        logStatusIfError(ini, QStringLiteral("read_bool"), section, key);
        return false;
    }
    logStatusIfError(ini, QStringLiteral("read_bool"), section, key);
    return b;
}

void Settings::write_bool(const QString& key, bool value)
{
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    ini.setValue(key, value);
    ini.sync();
    if (ini.status() != QSettings::NoError) {
        qWarning().noquote() << QStringLiteral("Settings::write_bool: failed to write key %1 (section: %2, config: %3): %4")
                                .arg(key, QStringLiteral("General"), ini.fileName(), QString::fromLatin1(settingsStatusToString(ini.status())));
    } else {
        emit settingChanged(sectionLabel(QString()), key, QVariant::fromValue(value));
    }
}

void Settings::write_bool(const QString& section, const QString& key, bool value)
{
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    if (section.isEmpty()) {
        ini.setValue(key, value);
    } else {
        ini.beginGroup(section);
        ini.setValue(key, value);
        ini.endGroup();
    }
    ini.sync();
    if (ini.status() != QSettings::NoError) {
        qWarning().noquote() << QStringLiteral("Settings::write_bool: failed to write key %1 (section: %2, config: %3): %4")
                                .arg(key, sectionLabel(section), ini.fileName(), QString::fromLatin1(settingsStatusToString(ini.status())));
    } else {
        emit settingChanged(sectionLabel(section), key, QVariant::fromValue(value));
    }
}

bool Settings::init_bool(const QString& key, bool value)
{
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    if (ini.contains(key)) {
        const QVariant v = ini.value(key);
        bool ok = false;
        const bool b = variantToStrictBool(v, ok);
        if (!ok) {
            qWarning().noquote() << QStringLiteral("Settings::init_bool: existing non-boolean at key %1 (section: %2, config: %3)")
                                    .arg(key, QStringLiteral("General"), ini.fileName());
            return false;
        }
        return b;
    }
    ini.setValue(key, value);
    ini.sync();
    if (ini.status() != QSettings::NoError) {
        qWarning().noquote() << QStringLiteral("Settings::init_bool: failed to create key %1 (section: %2, config: %3): %4")
                                .arg(key, QStringLiteral("General"), ini.fileName(), QString::fromLatin1(settingsStatusToString(ini.status())));
        return false;
    }
    qInfo().noquote() << QStringLiteral("Settings::init_bool: created key %1 in section %2 (config: %3)")
                         .arg(key, QStringLiteral("General"), configPath());
    emit settingChanged(sectionLabel(QString()), key, QVariant::fromValue(value));
    return value;
}

bool Settings::init_bool(const QString& section, const QString& key, bool value)
{
    ensureFileExists();
    QSettings ini(configPath(), QSettings::IniFormat);
    const bool existsInTop = section.isEmpty();

    if (existsInTop) {
        if (ini.contains(key)) {
            const QVariant v = ini.value(key);
            bool ok = false;
            const bool b = variantToStrictBool(v, ok);
            if (!ok) {
                qWarning().noquote() << QStringLiteral("Settings::init_bool: existing non-boolean at key %1 (section: %2, config: %3)")
                                        .arg(key, QStringLiteral("General"), ini.fileName());
                return false;
            }
            return b;
        }
        ini.setValue(key, value);
        ini.sync();
        if (ini.status() != QSettings::NoError) {
            qWarning().noquote() << QStringLiteral("Settings::init_bool: failed to create key %1 (section: %2, config: %3): %4")
                                    .arg(key, QStringLiteral("General"), ini.fileName(), QString::fromLatin1(settingsStatusToString(ini.status())));
            return false;
        }
        qInfo().noquote() << QStringLiteral("Settings::init_bool: created key %1 in section %2 (config: %3)")
                             .arg(key, QStringLiteral("General"), configPath());
        emit settingChanged(sectionLabel(QString()), key, QVariant::fromValue(value));
        return value;
    }

    ini.beginGroup(section);
    const bool exists = ini.contains(key);
    QVariant v;
    if (exists) v = ini.value(key);
    else ini.setValue(key, value);
    ini.endGroup();

    if (exists) {
        bool ok = false;
        const bool b = variantToStrictBool(v, ok);
        if (!ok) {
            qWarning().noquote() << QStringLiteral("Settings::init_bool: existing non-boolean at key %1 (section: %2, config: %3)")
                                    .arg(key, sectionLabel(section), ini.fileName());
            return false;
        }
        return b;
    }

    ini.sync();
    if (ini.status() != QSettings::NoError) {
        qWarning().noquote() << QStringLiteral("Settings::init_bool: failed to create key %1 (section: %2, config: %3): %4")
                                .arg(key, sectionLabel(section), ini.fileName(), QString::fromLatin1(settingsStatusToString(ini.status())));
        return false;
    }
    qInfo().noquote() << QStringLiteral("Settings::init_bool: created key %1 in section %2 (config: %3)")
                         .arg(key, sectionLabel(section), configPath());
    emit settingChanged(sectionLabel(section), key, QVariant::fromValue(value));
    return value;
}
