import QtQuick
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    // Read-only operational awareness panel for FlyView.
    // This module intentionally does not mutate any vehicle/system state.
    property var videoManager: QGroundControl.videoManager
    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    // Layout tuning
    property real _margin: ScreenTools.defaultFontPixelWidth
    property real _pad: ScreenTools.defaultFontPixelWidth * 0.7
    property real _radius: ScreenTools.defaultFontPixelWidth * 0.5
    // Middle-ground typography: larger than previous compact values but still
    // smaller than major heading widgets in the main control panel.
    property real _titleFont: ScreenTools.defaultFontPixelHeight * (compact ? 0.72 : 0.82)
    property real _valueFont: ScreenTools.defaultFontPixelHeight * (compact ? 0.58 : 0.66)
    property bool compact: false

    // Public read-only values
    readonly property bool vehicleConnected: !!activeVehicle
    readonly property bool commsHealthy: activeVehicle ? !activeVehicle.communicationLost : false
    readonly property bool videoPresent: videoManager ? videoManager.hasVideo : false
    readonly property bool videoDecoding: videoManager ? videoManager.decoding : false
    readonly property bool recordingActive: videoManager ? videoManager.recording : false
    readonly property bool yoloAvailable: videoManager && videoManager.yoloDetector
    readonly property bool yoloEnabled: yoloAvailable ? videoManager.yoloDetector.enabled : false
    readonly property int detectionCount: videoManager && videoManager.detections ? videoManager.detections.length : 0

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    function _statusText(okText, badText, state) {
        return state ? okText : badText
    }

    function _statusColor(state) {
        return state ? "#2ecc71" : "#e74c3c"
    }

    function _warningColor(level) {
        if (level === "critical") return "#ef5350"
        if (level === "warning")  return "#ffb300"
        return "#90a4ae"
    }

    function _warningVisible(id) {
        if (id === "vehicle")   return !root.vehicleConnected
        if (id === "comms")     return root.vehicleConnected && !root.commsHealthy
        if (id === "video")     return root.videoPresent && !root.videoDecoding
        if (id === "recording") return root.videoDecoding && !root.recordingActive
        if (id === "yolo")      return root.yoloAvailable && !root.yoloEnabled
        return false
    }

    function _warningLevel(id) {
        if (id === "vehicle")   return "critical"
        if (id === "comms")     return "critical"
        if (id === "video")     return "warning"
        if (id === "recording") return "info"
        if (id === "yolo")      return "info"
        return "info"
    }

    function _warningText(id) {
        if (id === "vehicle")   return qsTr("No active vehicle connected")
        if (id === "comms")     return qsTr("Communication link lost")
        if (id === "video")     return qsTr("Video source configured but decode is idle")
        if (id === "recording") return qsTr("Video live but recording is off")
        if (id === "yolo")      return qsTr("Detector available but currently disabled")
        return ""
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        color: "#AA111111"
        border.color: "#333333"
        border.width: 1
        radius: root._radius

        implicitWidth: Math.max(column.implicitWidth + root._margin * 2, 280)
        implicitHeight: column.implicitHeight + root._margin * 2

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: root._margin
            spacing: root.compact ? root._pad * 0.72 : root._pad * 1.08

            QGCLabel {
                text: qsTr("Operator Status")
                font.bold: true
                font.pixelSize: root._titleFont
                color: "#00d2d3"
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#2c3e50"
                opacity: 0.8
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: root.compact ? root._pad * 0.62 : root._pad * 0.9
                columnSpacing: root.compact ? root._pad * 1.05 : root._pad * 1.3

                QGCLabel {
                    text: qsTr("Vehicle")
                    font.pixelSize: root._valueFont
                    color: "#b0bec5"
                }
                QGCLabel {
                    text: root._statusText(qsTr("Connected"), qsTr("Disconnected"), root.vehicleConnected)
                    font.pixelSize: root._valueFont
                    color: root._statusColor(root.vehicleConnected)
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }

                QGCLabel {
                    text: qsTr("Comms")
                    font.pixelSize: root._valueFont
                    color: "#b0bec5"
                }
                QGCLabel {
                    text: root._statusText(qsTr("Healthy"), qsTr("Lost"), root.commsHealthy)
                    font.pixelSize: root._valueFont
                    color: root._statusColor(root.commsHealthy)
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }

                QGCLabel {
                    text: qsTr("Video Source")
                    font.pixelSize: root._valueFont
                    color: "#b0bec5"
                }
                QGCLabel {
                    text: root._statusText(qsTr("Configured"), qsTr("Unavailable"), root.videoPresent)
                    font.pixelSize: root._valueFont
                    color: root._statusColor(root.videoPresent)
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }

                QGCLabel {
                    text: qsTr("Video Decode")
                    font.pixelSize: root._valueFont
                    color: "#b0bec5"
                }
                QGCLabel {
                    text: root._statusText(qsTr("Active"), qsTr("Idle"), root.videoDecoding)
                    font.pixelSize: root._valueFont
                    color: root._statusColor(root.videoDecoding)
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }

                QGCLabel {
                    text: qsTr("Recording")
                    font.pixelSize: root._valueFont
                    color: "#b0bec5"
                }
                QGCLabel {
                    text: root._statusText(qsTr("ON"), qsTr("OFF"), root.recordingActive)
                    font.pixelSize: root._valueFont
                    color: root.recordingActive ? "#ff5252" : "#90a4ae"
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }

                QGCLabel {
                    text: qsTr("YOLO")
                    font.pixelSize: root._valueFont
                    color: "#b0bec5"
                }
                QGCLabel {
                    text: root.yoloAvailable
                          ? root._statusText(qsTr("Enabled"), qsTr("Disabled"), root.yoloEnabled)
                          : qsTr("Not Available")
                    font.pixelSize: root._valueFont
                    color: root.yoloAvailable
                           ? root._statusColor(root.yoloEnabled)
                           : "#90a4ae"
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }

                QGCLabel {
                    text: qsTr("Detections")
                    font.pixelSize: root._valueFont
                    color: "#b0bec5"
                }
                QGCLabel {
                    text: root.yoloEnabled ? String(root.detectionCount) : qsTr("—")
                    font.pixelSize: root._valueFont
                    color: root.yoloEnabled
                           ? (root.detectionCount > 0 ? "#00ff41" : "#90a4ae")
                           : "#90a4ae"
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#2c3e50"
                opacity: 0.8
            }

            // Iteration 03: read-only soft warning badges
            Flow {
                Layout.fillWidth: true
                spacing: root.compact ? root._pad * 0.4 : root._pad * 0.55

                Rectangle {
                    visible: root._warningVisible("vehicle")
                    radius: 10
                    color: "#33222222"
                    border.width: 1
                    border.color: root._warningColor(root._warningLevel("vehicle"))
                    height: badgeVehicleText.implicitHeight + 6
                    width: badgeVehicleText.implicitWidth + 12

                    QGCLabel {
                        id: badgeVehicleText
                        anchors.centerIn: parent
                        font.pixelSize: root._valueFont * 0.9
                        font.bold: true
                        color: root._warningColor(root._warningLevel("vehicle"))
                        text: "● " + root._warningText("vehicle")
                    }
                }

                Rectangle {
                    visible: root._warningVisible("comms")
                    radius: 10
                    color: "#33222222"
                    border.width: 1
                    border.color: root._warningColor(root._warningLevel("comms"))
                    height: badgeCommsText.implicitHeight + 6
                    width: badgeCommsText.implicitWidth + 12

                    QGCLabel {
                        id: badgeCommsText
                        anchors.centerIn: parent
                        font.pixelSize: root._valueFont * 0.9
                        font.bold: true
                        color: root._warningColor(root._warningLevel("comms"))
                        text: "● " + root._warningText("comms")
                    }
                }

                Rectangle {
                    visible: root._warningVisible("video")
                    radius: 10
                    color: "#33222222"
                    border.width: 1
                    border.color: root._warningColor(root._warningLevel("video"))
                    height: badgeVideoText.implicitHeight + 6
                    width: badgeVideoText.implicitWidth + 12

                    QGCLabel {
                        id: badgeVideoText
                        anchors.centerIn: parent
                        font.pixelSize: root._valueFont * 0.9
                        font.bold: true
                        color: root._warningColor(root._warningLevel("video"))
                        text: "● " + root._warningText("video")
                    }
                }

                Rectangle {
                    visible: root._warningVisible("recording")
                    radius: 10
                    color: "#33222222"
                    border.width: 1
                    border.color: root._warningColor(root._warningLevel("recording"))
                    height: badgeRecordingText.implicitHeight + 6
                    width: badgeRecordingText.implicitWidth + 12

                    QGCLabel {
                        id: badgeRecordingText
                        anchors.centerIn: parent
                        font.pixelSize: root._valueFont * 0.9
                        font.bold: true
                        color: root._warningColor(root._warningLevel("recording"))
                        text: "● " + root._warningText("recording")
                    }
                }

                Rectangle {
                    visible: root._warningVisible("yolo")
                    radius: 10
                    color: "#33222222"
                    border.width: 1
                    border.color: root._warningColor(root._warningLevel("yolo"))
                    height: badgeYoloText.implicitHeight + 6
                    width: badgeYoloText.implicitWidth + 12

                    QGCLabel {
                        id: badgeYoloText
                        anchors.centerIn: parent
                        font.pixelSize: root._valueFont * 0.9
                        font.bold: true
                        color: root._warningColor(root._warningLevel("yolo"))
                        text: "● " + root._warningText("yolo")
                    }
                }
            }

            QGCLabel {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.pixelSize: root._valueFont * (root.compact ? 0.92 : 0.96)
                color: "#90a4ae"
                text: root.videoDecoding
                      ? qsTr("Status is read-only. Use existing controls for arm, mode changes, recording, and detector toggles.")
                      : qsTr("Awaiting active video decode. Recording controls become valid once video is live.")
            }
        }
    }
}
