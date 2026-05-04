// FlightAnalytics: collects simple flight metrics and basic anomaly detection
#pragma once

#include <QObject>
#include <QVector>
#include <QVariantMap>

class FlightAnalytics : public QObject {
    Q_OBJECT
public:
    explicit FlightAnalytics(QObject* parent = nullptr);

    void addSample(qint64 timestampMs, double batteryPercent, double signalRssi, double altitudeM);
    QVariantMap exportMetrics() const;
    QVariantList detectAnomalies() const;

private:
    struct Sample { qint64 t; double batt; double rssi; double alt; };
    QVector<Sample> _samples;
};
