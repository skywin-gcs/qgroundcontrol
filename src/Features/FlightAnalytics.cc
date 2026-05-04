#include "FlightAnalytics.h"

FlightAnalytics::FlightAnalytics(QObject* parent) : QObject(parent) {}

void FlightAnalytics::addSample(qint64 timestampMs, double batteryPercent, double signalRssi, double altitudeM)
{
    Sample s{timestampMs, batteryPercent, signalRssi, altitudeM};
    _samples.append(s);
}

QVariantMap FlightAnalytics::exportMetrics() const
{
    QVariantMap out;
    if (_samples.isEmpty())
        return out;

    double minBatt = 100.0, maxBatt = 0.0, sumBatt = 0.0;
    for (const Sample& s : _samples) {
        minBatt = qMin(minBatt, s.batt);
        maxBatt = qMax(maxBatt, s.batt);
        sumBatt += s.batt;
    }
    out["samples"] = static_cast<int>(_samples.size());
    out["battery_min"] = minBatt;
    out["battery_max"] = maxBatt;
    out["battery_avg"] = sumBatt / _samples.size();
    return out;
}

QVariantList FlightAnalytics::detectAnomalies() const
{
    QVariantList anomalies;
    if (_samples.size() < 2)
        return anomalies;

    // Simple anomaly: sudden battery drop > 10% between consecutive samples
    for (int i = 1; i < _samples.size(); ++i) {
        double diff = _samples[i-1].batt - _samples[i].batt;
        if (diff > 10.0) {
            QVariantMap a;
            a["type"] = "battery_drop";
            a["index"] = i;
            a["drop_percent"] = diff;
            anomalies << a;
        }
    }

    return anomalies;
}
