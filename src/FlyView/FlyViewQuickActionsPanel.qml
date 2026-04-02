import QtQuick
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    // Safe, opt-in quick actions panel.
    // This component only calls already-existing commands exposed by QGC APIs.
    // It does not introduce new command paths or backend side effects.

    property var videoManager: QGroundControl.videoManager
    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    // Panel behavior
    property bool compact: false
    property bool showHeader: true
    property bool showFlightActions: true
    property bool showVideoActions: true
    property bool showDetectorActions: true
    property bool showTelemetryActions: true

    // Layout tuning
    property real _margin: ScreenTools.defaultFontPixelWidth * (compact ? 0.65 : 0.85)
    property real _pad: ScreenTools.defaultFontPixelWidth * (compact ? 0.45 : 0.65)
    property real _radius: ScreenTools.defaultFontPixelWidth * 0.5
    property real _titleFont: ScreenTools.defaultFontPixelHeight * (compact ? 0.68 : 0.80)
    property real _buttonFont: ScreenTools.defaultFontPixelHeight * (compact ? 0.52 : 0.60)

    // Derived state
    readonly property bool _vehicleAvailable: !!activeVehicle
    readonly property bool _vehicleArmed: _vehicleAvailable ? activeVehicle.armed : false
    readonly property bool _videoDecoding: videoManager ? videoManager.decoding : false
    readonly property bool _recording: videoManager ? videoManager.recording : false
    readonly property bool _isUvc: videoManager ? videoManager.isUvc : false
    readonly property bool _hasYolo: videoManager && videoManager.yoloDetector
    readonly property bool _yoloEnabled: _hasYolo ? videoManager.yoloDetector.enabled : false

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    Rectangle {
        id: panel
        anchors.fill: parent
        color: "#AA141414"
        border.color: "#2f2f2f"
        border.width: 1
        radius: root._radius

        implicitWidth: Math.max(contentColumn.implicitWidth + root._margin * 2, 280)
        implicitHeight: contentColumn.implicitHeight + root._margin * 2

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: root._margin
            spacing: root._pad

            QGCLabel {
                visible: root.showHeader
                text: qsTr("Quick Actions")
                color: "#90caf9"
                font.bold: true
                font.pixelSize: root._titleFont
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root.showHeader
                Layout.fillWidth: true
                height: 1
                color: "#2c3e50"
                opacity: 0.8
            }

            // ──────────────────────────────────────────────────────────────
            // Flight Actions
            // ──────────────────────────────────────────────────────────────
            ColumnLayout {
                visible: root.showFlightActions
                Layout.fillWidth: true
                spacing: root._pad * 0.6

                QGCLabel {
                    text: qsTr("Flight")
                    color: "#b0bec5"
                    font.bold: true
                    font.pixelSize: root._buttonFont * 0.95
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root._pad

                    QGCButton {
                        text: root._vehicleArmed ? qsTr("Disarm") : qsTr("Arm")
                        Layout.fillWidth: true
                        enabled: root._vehicleAvailable
                        font.pixelSize: root._buttonFont

                        onClicked: {
                            if (!root._vehicleAvailable) {
                                return
                            }
                            if (root._vehicleArmed) {
                                root.activeVehicle.disarm()
                            } else {
                                root.activeVehicle.arm()
                            }
                        }
                    }

                    QGCButton {
                        text: qsTr("RTL")
                        Layout.fillWidth: true
                        enabled: false
                        font.pixelSize: root._buttonFont
                        onClicked: {
                            // Intentionally disabled in quick actions panel:
                            // RTL invocation should be routed through existing guided-action
                            // controllers, not direct vehicle method calls.
                        }
                    }
                }
            }

            // ──────────────────────────────────────────────────────────────
            // Video Actions
            // ──────────────────────────────────────────────────────────────
            ColumnLayout {
                visible: root.showVideoActions
                Layout.fillWidth: true
                spacing: root._pad * 0.6

                QGCLabel {
                    text: qsTr("Video")
                    color: "#b0bec5"
                    font.bold: true
                    font.pixelSize: root._buttonFont * 0.95
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root._pad

                    QGCButton {
                        text: root._recording ? qsTr("Stop Rec") : qsTr("Start Rec")
                        Layout.fillWidth: true
                        // Follow current project safety constraints:
                        // enable recording shortcut only for non-UVC decode-active video.
                        enabled: root.videoManager && root._videoDecoding && !root._isUvc
                        font.pixelSize: root._buttonFont

                        onClicked: {
                            if (!root.videoManager) {
                                return
                            }
                            if (root._recording) {
                                root.videoManager.stopRecording()
                            } else {
                                root.videoManager.startRecording()
                            }
                        }
                    }

                    QGCButton {
                        text: qsTr("Screenshot")
                        Layout.fillWidth: true
                        enabled: root.videoManager && root.videoManager.hasVideo
                        font.pixelSize: root._buttonFont
                        onClicked: {
                            if (root.videoManager) {
                                root.videoManager.grabImage()
                            }
                        }
                    }
                }
            }

            // ──────────────────────────────────────────────────────────────
            // Detector Actions
            // ──────────────────────────────────────────────────────────────
            ColumnLayout {
                visible: root.showDetectorActions
                Layout.fillWidth: true
                spacing: root._pad * 0.6

                QGCLabel {
                    text: qsTr("Detector")
                    color: "#b0bec5"
                    font.bold: true
                    font.pixelSize: root._buttonFont * 0.95
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root._pad

                    QGCButton {
                        text: root._yoloEnabled ? qsTr("YOLO ON") : qsTr("YOLO OFF")
                        Layout.fillWidth: true
                        enabled: root._hasYolo
                        font.pixelSize: root._buttonFont

                        onClicked: {
                            if (root._hasYolo) {
                                root.videoManager.yoloDetector.enabled = !root.videoManager.yoloDetector.enabled
                            }
                        }
                    }

                    QGCButton {
                        text: qsTr("Conf +")
                        Layout.fillWidth: true
                        enabled: root._hasYolo
                        font.pixelSize: root._buttonFont
                        onClicked: {
                            if (root._hasYolo) {
                                const det = root.videoManager.yoloDetector
                                const current = Number(det.confidenceThreshold)
                                const next = Math.min(0.95, current + 0.05)
                                det.confidenceThreshold = next
                            }
                        }
                    }
                }
            }

            // ──────────────────────────────────────────────────────────────
            // Telemetry / Utility Actions
            // ──────────────────────────────────────────────────────────────
            ColumnLayout {
                visible: root.showTelemetryActions
                Layout.fillWidth: true
                spacing: root._pad * 0.6

                QGCLabel {
                    text: qsTr("Utilities")
                    color: "#b0bec5"
                    font.bold: true
                    font.pixelSize: root._buttonFont * 0.95
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root._pad

                    QGCButton {
                        text: qsTr("Recenter Map")
                        Layout.fillWidth: true
                        font.pixelSize: root._buttonFont
                        enabled: true
                        onClicked: {
                            // No direct map handle here by design; this is a placeholder
                            // shortcut slot to keep the module additive and safe.
                            // Integrator can bind an external handler to this signal.
                            root.recenterMapRequested()
                        }
                    }

                    QGCButton {
                        text: qsTr("Start Video")
                        Layout.fillWidth: true
                        font.pixelSize: root._buttonFont
                        enabled: root.videoManager !== null
                        onClicked: {
                            if (root.videoManager) {
                                root.videoManager.startVideo()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#2c3e50"
                opacity: 0.8
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root._pad * 0.35

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root._pad

                    QGCButton {
                        text: qsTr("Conf -")
                        Layout.fillWidth: true
                        enabled: root._hasYolo
                        font.pixelSize: root._buttonFont
                        onClicked: {
                            if (root._hasYolo) {
                                const det = root.videoManager.yoloDetector
                                const current = Number(det.confidenceThreshold)
                                const next = Math.max(0.10, current - 0.05)
                                det.confidenceThreshold = next
                            }
                        }
                    }

                    QGCLabel {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        color: "#90a4ae"
                        font.pixelSize: root._buttonFont * 0.9
                        text: root._hasYolo
                              ? qsTr("Conf: %1%").arg(Math.round(root.videoManager.yoloDetector.confidenceThreshold * 100))
                              : qsTr("Conf: —")
                    }
                }

                QGCLabel {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#90a4ae"
                    font.pixelSize: root._buttonFont * 0.88
                    text: qsTr("Quick actions call existing commands only. Use full controls for advanced operations.")
                }
            }
        }
    }

    // Optional extension point to keep this module decoupled from map internals.
    signal recenterMapRequested()
}
