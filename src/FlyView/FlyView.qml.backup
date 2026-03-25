import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.Palette
import QGroundControl.ScreenTools

QGCPopupWindow {
    id:         _root
    title:       qsTr("Fly View")

    property var _activeVehicle:      QGroundControl.multiVehicleManager.activeVehicle
    property var _missionController:   QGroundControl.missionController
    property var _planMasterController: QGroundController.planMasterController

    QGCPalette {
        id: qgcPal
        colorGroupEnabled: true
    }

    Component.onCompleted: {
        // Set initial size to 80% of available screen space
        var screenSize = ScreenTools.availableScreenSize
        width = screenSize.width * 0.8
        height = screenSize.height * 0.8
    }

    // Main content area with split-screen layout
    Item {
        id: mainContent
        anchors.fill: parent

        // Left side - Video feed (70% width)
        Rectangle {
            id: videoContainer
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.7
            color: "black"

            FlightDisplayViewVideo {
                id: flightVideo
                anchors.fill: parent
                pipView: pipViewLoader.item
            }
        }

        // Right side - Control panel (30% width)
        Rectangle {
            id: controlPanel
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.3
            color: qgcPal.window

            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    // Vehicle Status Section
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        color: qgcPal.windowShade
                        border.color: qgcPal.text
                        border.width: 1
                        radius: 5

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Text {
                                text: "Vehicle Status"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            GridLayout {
                                columns: 2
                                Layout.fillWidth: true

                                Text { text: "Battery:"; color: "white" }
                                Text {
                                    text: _activeVehicle ? (_activeVehicle.battery.percentRemaining.valueString + "%") : "N/A"
                                    color: _activeVehicle && _activeVehicle.battery.percentRemaining.value > 20 ? "green" : "red"
                                }

                                Text { text: "Altitude:"; color: "white" }
                                Text {
                                    text: _activeVehicle ? (_activeVehicle.altitudeRelative.valueString + "m") : "N/A"
                                    color: "cyan"
                                }

                                Text { text: "Speed:"; color: "white" }
                                Text {
                                    text: _activeVehicle ? (_activeVehicle.groundSpeed.valueString + "m/s") : "N/A"
                                    color: "yellow"
                                }

                                Text { text: "GPS:"; color: "white" }
                                Text {
                                    text: _activeVehicle ? (_activeVehicle.gps.count.value + " sats") : "N/A"
                                    color: _activeVehicle && _activeVehicle.gps.count.value > 5 ? "green" : "red"
                                }
                            }
                        }
                    }

                    // Control Buttons Section
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        color: qgcPal.windowShade
                        border.color: qgcPal.text
                        border.width: 1
                        radius: 5

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Text {
                                text: "Controls"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                QGCButton {
                                    Layout.fillWidth: true
                                    text: _activeVehicle ? (_activeVehicle.armed ? "Disarm" : "Arm") : "Arm"
                                    enabled: _activeVehicle
                                    onClicked: {
                                        if (_activeVehicle) {
                                            if (_activeVehicle.armed) {
                                                _activeVehicle.disarm()
                                            } else {
                                                _activeVehicle.arm()
                                            }
                                        }
                                    }
                                }

                                QGCButton {
                                    Layout.fillWidth: true
                                    text: QGroundControl.videoManager.isRecording ? "Stop Recording" : "Start Recording"
                                    enabled: QGroundControl.videoManager.hasVideo
                                    onClicked: {
                                        if (QGroundControl.videoManager.isRecording) {
                                            QGroundControl.videoManager.stopRecording()
                                        } else {
                                            QGroundControl.videoManager.startRecording()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Mission Section
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        color: qgcPal.windowShade
                        border.color: qgcPal.text
                        border.width: 1
                        radius: 5

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            QGCButton {
                                text: "Start Mission"
                                enabled: _activeVehicle && _missionController.readyForMission
                                Layout.fillWidth: true
                                onClicked: _missionController.startMission()
                            }
                        }
                    }

                    // Spacer
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    // PiP View Loader
    Loader {
        id: pipViewLoader
        source: videoPipState.pipVisible ? "qrc:/qml/FlightDisplayViewPiP.qml" : ""
    }
}
