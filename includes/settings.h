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

    // 读取（默认节名 General）
    Q_INVOKABLE QVariant read(const QString& key);
    Q_INVOKABLE QVariant read(const QString& section, const QString& key);

    // 写入（默认节名 General）
    Q_INVOKABLE void write(const QString& key, const QVariant& value);
    Q_INVOKABLE void write(const QString& section, const QString& key, const QVariant& value);

private:
    // 获取配置文件绝对路径（程序目录/config.ini）
    QString configPath() const;
    // 若文件不存在则创建空文件
    void ensureFileExists() const;

private:
    static inline Settings* s_instance = nullptr;
};
