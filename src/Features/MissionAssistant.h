// MissionAssistant: provides mission validation and suggestions
#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class MissionAssistant : public QObject {
    Q_OBJECT
public:
    explicit MissionAssistant(QObject* parent = nullptr);

    // Validate a mission represented as a list of waypoint maps.
    // Each waypoint may contain keys like "distanceMeters", "estimatedTimeSec", "batteryUsagePercent".
    QVariantList validateMission(const QVariantList& mission) const;

    // Produce simple auto-corrections (e.g., reduce waypoint altitude or speed) as suggestions.
    QVariantList suggestCorrections(const QVariantList& mission) const;
};
