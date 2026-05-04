// TileCache: simple on-disk tile cache
#pragma once

#include <QObject>
#include <QByteArray>
#include <QDir>

class TileCache : public QObject {
    Q_OBJECT
public:
    explicit TileCache(const QString& cacheRoot = QString(), QObject* parent = nullptr);

    QByteArray lookup(int z, int x, int y) const;
    bool store(int z, int x, int y, const QByteArray& data);

private:
    QDir _root;
};
