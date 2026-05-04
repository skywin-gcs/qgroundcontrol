#include "TileCache.h"
#include <QStandardPaths>
#include <QFile>

TileCache::TileCache(const QString& cacheRoot, QObject* parent) : QObject(parent)
{
    QString rootPath = cacheRoot;
    if (rootPath.isEmpty()) {
        rootPath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
        if (rootPath.isEmpty())
            rootPath = QDir::homePath() + "/.qgc_tile_cache";
    }
    _root = QDir(rootPath);
    if (!_root.exists())
        _root.mkpath(".");
}

static QString tilePathFor(const QDir& root, int z, int x, int y)
{
    return root.filePath(QString("%1/%2/%3.png").arg(z).arg(x).arg(y));
}

QByteArray TileCache::lookup(int z, int x, int y) const
{
    QString path = tilePathFor(_root, z, x, y);
    QFile f(path);
    if (!f.exists())
        return QByteArray();
    if (!f.open(QIODevice::ReadOnly))
        return QByteArray();
    return f.readAll();
}

bool TileCache::store(int z, int x, int y, const QByteArray& data)
{
    QString dir = _root.filePath(QString("%1/%2").arg(z).arg(x));
    QDir d;
    if (!d.mkpath(dir))
        return false;
    QString path = tilePathFor(_root, z, x, y);
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly))
        return false;
    qint64 written = f.write(data);
    return written == data.size();
}
