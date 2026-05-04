#include <QtTest>
#include "../../../../src/Features/MissionAssistant.h"
#include "../../../../src/Features/TileCache.h"
#include "../../../../src/Features/FlightAnalytics.h"

class FeaturesUnitTest : public QObject
{
    Q_OBJECT

private slots:
    void missionValidation();
    void tileCacheStoreLookup();
    void flightAnalyticsMetricsAndAnomaly();
};

void FeaturesUnitTest::missionValidation()
{
    MissionAssistant ma;
    QVariantList mission;
    QVariantMap wp1; wp1["estimatedTimeSec"] = 2000; wp1["batteryUsagePercent"] = 50.0; wp1["altitude"] = 150.0;
    QVariantMap wp2; wp2["estimatedTimeSec"] = 2500; wp2["batteryUsagePercent"] = 45.0; wp2["altitude"] = 80.0;
    mission << wp1 << wp2;

    QVariantList warnings = ma.validateMission(mission);
    QVERIFY(!warnings.isEmpty());

    QVariantList suggestions = ma.suggestCorrections(mission);
    QVERIFY(!suggestions.isEmpty());
}

void FeaturesUnitTest::tileCacheStoreLookup()
{
    TileCache cache;
    QByteArray data("tiledata");
    bool ok = cache.store(1,2,3,data);
    QVERIFY(ok);
    QByteArray r = cache.lookup(1,2,3);
    QCOMPARE(r, data);
}

void FeaturesUnitTest::flightAnalyticsMetricsAndAnomaly()
{
    FlightAnalytics fa;
    fa.addSample(1, 90.0, -50, 10);
    fa.addSample(2, 78.0, -52, 12); // battery drop 12%
    QVariantMap metrics = fa.exportMetrics();
    QVERIFY(metrics.contains("samples"));
    QVariantList anomalies = fa.detectAnomalies();
    QVERIFY(!anomalies.isEmpty());
}

QTEST_MAIN(FeaturesUnitTest)
#include "FeaturesTest.moc"
