// MapProvider: abstraction for map tile providers used by Features
#pragma once

#include <QObject>
#include <QByteArray>

namespace Features {

class MapProvider : public QObject {
    Q_OBJECT
public:
    explicit MapProvider(QObject* parent = nullptr) : QObject(parent) {}
    virtual ~MapProvider() = default;

    // Request tile bytes for z/x/y. Implementations may be synchronous or async.
    virtual QByteArray getTile(int z, int x, int y) = 0;
};

} // namespace Features
