#include "MissionAssistant.h"
#include <QVariant>
#include <QJsonObject>
#include <QJsonArray>

MissionAssistant::MissionAssistant(QObject* parent) : QObject(parent) {}

QVariantList MissionAssistant::validateMission(const QVariantList& mission) const
{
    QVariantList warnings;

    double totalEstimatedTime = 0.0;
    double totalBatteryUsage = 0.0;

    for (const QVariant& v : mission) {
        if (!v.canConvert<QVariantMap>())
            continue;
        QVariantMap m = v.toMap();
        if (m.contains("estimatedTimeSec"))
            totalEstimatedTime += m.value("estimatedTimeSec").toDouble();
        if (m.contains("batteryUsagePercent"))
            totalBatteryUsage += m.value("batteryUsagePercent").toDouble();
    }

    // Simple checks
    if (totalEstimatedTime > 3600) {
        QVariantMap w;
        w["type"] = "time";
        w["message"] = "Estimated mission time exceeds 1 hour.";
        warnings << w;
    }

    if (totalBatteryUsage > 90.0) {
        QVariantMap w;
        w["type"] = "battery";
        w["message"] = "Estimated battery usage > 90% — risk of low battery.";
        warnings << w;
    }

    return warnings;
}

QVariantList MissionAssistant::suggestCorrections(const QVariantList& mission) const
{
    QVariantList suggestions;

    // Very naive suggestion: if any waypoint has altitude > 120m, propose lowering.
    for (int i = 0; i < mission.size(); ++i) {
        QVariant v = mission.at(i);
        if (!v.canConvert<QVariantMap>())
            continue;
        QVariantMap m = v.toMap();
        if (m.contains("altitude") && m.value("altitude").toDouble() > 120.0) {
            QVariantMap s;
            s["index"] = i;
            s["field"] = "altitude";
            s["suggestedValue"] = 120.0;
            s["reason"] = "Above recommended max altitude (120m)";
            suggestions << s;
        }
    }

    return suggestions;
}
