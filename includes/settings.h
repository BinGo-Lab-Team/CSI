#pragma once
#include <QObject>
#include <QSettings>
#include <QVariant>
#include <QDir>
#include <QCoreApplication>
#include <qqml.h>

// ==== INI API ====
class Settings : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit Settings(QObject* parent = nullptr);
    ~Settings() override = default;

    // QML 单例工厂
    static Settings* create(QQmlEngine*, QJSEngine*) { return new Settings; }

    // 进程内实例
    static Settings* instance() { return s_instance; }

    // ==== R/W API ====
    // 注意！section/key/value 里，绝对不能含有 ";" or "#" 否则会字符后面的内容会被当作注释！
    
    // 读取：存在则返回现有值；不存在则返回 "ErrorNotExists"
    Q_INVOKABLE QVariant read(const QString& key);
    Q_INVOKABLE QVariant read(const QString& section, const QString& key);

    // 写入：写入给定值到指定的键；不存在则创建并写入
    Q_INVOKABLE void write(const QString& key, const QVariant& value);
    Q_INVOKABLE void write(const QString& section, const QString& key, const QVariant& value);

    // 初始化：存在则返回现有值；不存在则写入给定值并返回 "InfoCreated"
    Q_INVOKABLE QVariant init(const QString& key, const QVariant& value);
    Q_INVOKABLE QVariant init(const QString& section, const QString& key, const QVariant& value);

    // BOOL接口：仅处理 true/false，出现错误返回 false，其余同上
    Q_INVOKABLE bool read_bool(const QString& key);
    Q_INVOKABLE bool read_bool(const QString& section, const QString& key);

    Q_INVOKABLE void write_bool(const QString& key, bool value);
    Q_INVOKABLE void write_bool(const QString& section, const QString& key, bool value);

    Q_INVOKABLE bool init_bool(const QString& key, bool value);
    Q_INVOKABLE bool init_bool(const QString& section, const QString& key, bool value);

signals:
    // 成功写入或成功初始化（创建新键）后发射。section 为空字符串表示顶层键。
    void settingChanged(const QString& section, const QString& key, const QVariant& value);

private:
    // 获取配置文件绝对路径（程序目录/config.ini）
    QString configPath() const;
    // 若文件不存在则创建空文件
    void ensureFileExists() const;

private:
    static inline Settings* s_instance = nullptr;
};
