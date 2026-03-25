import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap
import QGroundControl.Toolbar
// import QGroundControl.Viewer3D   // commented out - remove if not needed

Item {
    id: _root

    readonly property bool _is3DMode: (typeof QGCViewer3DManager !== "undefined") &&
            QGCViewer3DManager.displayMode === QGCViewer3DManager.View3D

    // These should only be used by MainRootWindow
    property var planController: _planController
    property var guidedController: _guidedController

    PlanMasterController {
        id: _planController
        flyView: true
        Component.onCompleted: start()
    }

    property bool _mainWindowIsMap: !QGroundControl.videoManager.hasVideo
    property bool _isFullWindowItemDark: _mainWindowIsMap ? (typeof mapControl !== "undefined" ? mapControl.isSatelliteMap : true) : true
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var _missionController: _planController.missionController
    property var _geoFenceController: _planController.geoFenceController
    property var _rallyPointController: _planController.rallyPointController
    property real _margins: ScreenTools.defaultFontPixelWidth / 2
    property var _guidedController: (typeof guidedActionsController !== "undefined") ? guidedActionsController : null
    property var _guidedValueSlider: (typeof guidedValueSlider !== "undefined") ? guidedValueSlider : null
    property var _widgetLayer: (typeof widgetLayer !== "undefined") ? widgetLayer : null
    property real _toolsMargin: ScreenTools.defaultFontPixelWidth * 0.75
    property rect _centerViewport: Qt.rect(0, 0, width, height)
    property real _rightPanelWidth: ScreenTools.defaultFontPixelWidth * 30
    property var _mapControl: (typeof mapControl !== "undefined") ? mapControl : null
    property var _startRecording: (typeof startRecording !== "undefined") ? startRecording : null
    property var _stopRecording: (typeof stopRecording !== "undefined") ? stopRecording : null
    property var _takeScreenshot: (typeof takeScreenshot !== "undefined") ? takeScreenshot : null

    function _calcCenterViewPort() {
        var newToolInset = Qt.rect(0, 0, width, height)
        if (typeof toolstrip !== "undefined" && toolstrip !== null) {
            toolstrip.adjustToolInset(newToolInset)
        }
    }

    function dropMainStatusIndicatorTool() {
        if (typeof toolbar !== "undefined" && toolbar !== null) {
            toolbar.dropMainStatusIndicatorTool();
        }
    }

    QGCToolInsets {
        id: _toolInsets
        topEdgeLeftInset: toolbar.height
        topEdgeCenterInset: topEdgeLeftInset
        topEdgeRightInset: topEdgeLeftInset
        leftEdgeBottomInset: 0
        bottomEdgeLeftInset: 0
    }

    // ──────────────────────────────────────────────────────────────
    //               MAIN SPLIT-SCREEN LAYOUT
    // ──────────────────────────────────────────────────────────────

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // LEFT HALF: Video feed (or map if no video)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            FlyViewVideo {
                id: videoControl
                anchors.fill: parent
                visible: QGroundControl.videoManager.hasVideo
            }

            FlyViewMap {
                id: mapControl
                planMasterController: _planController
                rightPanelWidth: 0
                mapName: "FlightDisplayView"
                enabled: !_is3DMode && !QGroundControl.videoManager.hasVideo
                visible: !_is3DMode && !QGroundControl.videoManager.hasVideo
                anchors.fill: parent
            }

            Loader {
                id: viewer3DLoader
                z: 1
                anchors.fill: parent
                active: _is3DMode
                onActiveChanged: {
                    if (active) {
                        setSource("qrc:/qml/QGroundControl/Viewer3D/Models3D/Viewer3DModel.qml")
                    }
                }
            }
        }

        // RIGHT HALF: Controller panel
        Rectangle {
            Layout.preferredWidth: 380
            Layout.fillHeight: true
            color: "#121212"
            border.color: "#333333"
            border.width: 1
            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: rightColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { }

                ColumnLayout {
                    id: rightColumn
                    width: parent.width
                    spacing: 12

                // ═══════════════════════════════════════════════════════
                //                    TELEMETRY DASHBOARD
                // ═══════════════════════════════════════════════════════

                Text {
                    text: "✈ TELEMETRY"
                    color: "#00d2d3"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // Main flight data grid
                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    rowSpacing: 6
                    columnSpacing: 12

                    // Row 1 - Core data
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "ALTITUDE"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle ? (_activeVehicle.altitudeRelative.valueString) : "--" + " m"
                                color: "#00d2d3"; font.pixelSize: 16; font.bold: true
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "SPEED (H)"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle ? (_activeVehicle.groundSpeed.valueString) : "--" + " m/s"
                                color: "#feca57"; font.pixelSize: 16; font.bold: true
                            }
                        }
                    }

                    // Row 2
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "SPEED (V)"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle ? (_activeVehicle.climbRate.valueString) : "--" + " m/s"
                                color: "#ff9f43"; font.pixelSize: 16; font.bold: true
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "HEADING"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle ? (_activeVehicle.heading.valueString + "°") : "--°"
                                color: "#a29bfe"; font.pixelSize: 16; font.bold: true
                            }
                        }
                    }

                    // Row 3
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "DISTANCE"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle ? (_activeVehicle.distanceToHome.valueString) : "--" + " m"
                                color: "#fd79a8"; font.pixelSize: 16; font.bold: true
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "BATTERY"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle ? (_activeVehicle.battery.percentRemaining.valueString + "%") : "--%"
                                color: _activeVehicle && _activeVehicle.battery.percentRemaining.value > 20 ? "#2ecc71" : "#e74c3c"
                                font.pixelSize: 16; font.bold: true
                            }
                        }
                    }

                    // Row 4 - GPS & Signal
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "GPS SATELLITES"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle ? (_activeVehicle.gps.count.value) : "--"
                                color: _activeVehicle && _activeVehicle.gps.count.value > 5 ? "#2ecc71" : "#e74c3c"
                                font.pixelSize: 16; font.bold: true
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "RSSI"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle && _activeVehicle.linkManager && _activeVehicle.linkManager.activeLink ? _activeVehicle.linkManager.activeLink.rssi.valueString : "--"
                                color: "#ffeaa7"; font.pixelSize: 16; font.bold: true
                            }
                        }
                    }

                    // Row 5 - Flight mode & Status
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "FLIGHT MODE"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle ? _activeVehicle.flightMode : "N/A"
                                color: "#74b9ff"; font.pixelSize: 14; font.bold: true
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#1a1a2e"
                        radius: 8
                        Column {
                            anchors.centerIn: parent
                            Text { text: "ARMED STATUS"; color: "#666"; font.pixelSize: 10; font.bold: true }
                            Text {
                                text: _activeVehicle ? (_activeVehicle.armed ? "ARMED" : "DISARMED") : "N/A"
                                color: _activeVehicle && _activeVehicle.armed ? "#e74c3c" : "#2ecc71"
                                font.pixelSize: 14; font.bold: true
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════
                //                      CONTROLS
                // ═══════════════════════════════════════════════════════

                Text {
                    text: "⚡ CONTROLS"
                    color: "#00d2d3"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                }

                // ARM/DISARM Button
                QGCButton {
                    text: _activeVehicle ? (_activeVehicle.armed ? "DISARM" : "ARM") : "No Vehicle"
                    enabled: _activeVehicle
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    font.pixelSize: 16
                    font.bold: true
                    background: Rectangle {
                        color: _activeVehicle && _activeVehicle.armed ? "#c0392b" : "#27ae60"
                        radius: 10
                    }
                    onClicked: _activeVehicle.armed ? _activeVehicle.disarm() : _activeVehicle.arm()
                }

                // Recording Button
                QGCButton {
                    text: (QGroundControl.videoManager && QGroundControl.videoManager.recording) ? "⏹ Stop Recording" : "⏺ Start Recording"
                    enabled: QGroundControl.videoManager && QGroundControl.videoManager.hasVideo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    background: Rectangle {
                        color: (QGroundControl.videoManager && QGroundControl.videoManager.recording) ? "#e74c3c" : "#3498db"
                        radius: 8
                    }
                    onClicked: {
                        if (QGroundControl.videoManager) {
                            if (QGroundControl.videoManager.recording) {
                                QGroundControl.videoManager.stopRecording()
                            } else {
                                QGroundControl.videoManager.startRecording()
                            }
                        }
                    }
                }

                // Flight Mode Selector
                FlightModeMenu {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    currentVehicle: _activeVehicle
                }

                // Guided Actions
                Text {
                    text: "Guided Actions"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    QGCButton {
                        text: "RTL"
                        enabled: _activeVehicle && guidedActionsController.showRTL
                        Layout.fillWidth: true
                        background: Rectangle { color: "#9b59b6"; radius: 6 }
                        onClicked: guidedActionsController.confirmAction(guidedActionsController.actionRTL)
                    }

                    QGCButton {
                        text: "Emergency"
                        enabled: _activeVehicle
                        Layout.fillWidth: true
                        background: Rectangle { color: "#c0392b"; radius: 6 }
                        onClicked: guidedActionsController.confirmAction(guidedActionsController.actionEmergencyStop)
                    }
                }

                // Camera Controls
                Text {
                    text: "Camera"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                QGCButton {
                    text: "📷 Screenshot"
                    enabled: QGroundControl.videoManager && QGroundControl.videoManager.hasVideo
                    Layout.fillWidth: true
                    background: Rectangle { color: "#34495e"; radius: 6 }
                    onClicked: {
                        if (QGroundControl.videoManager) {
                            QGroundControl.videoManager.grabImage()
                        }
                    }
                }

                // Joystick Status
                Text {
                    text: "Joystick: " + (QGroundControl.joystickManager.activeJoystick ? "Connected" : "Disconnected")
                    color: QGroundControl.joystickManager.activeJoystick ? "#2ecc71" : "#e74c3c"
                    Layout.alignment: Qt.AlignHCenter
                }

                // Virtual Joystick
                Loader {
                    id: virtualJoystickLoader
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    active: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue && _activeVehicle
                    source: "qrc:/qml/QGroundControl/FlyView/VirtualJoystick.qml"
                    property bool autoCenterThrottle: QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
                    property bool leftHandedMode: QGroundControl.settingsManager.appSettings.virtualJoystickLeftHandedMode.rawValue
                }

                // Start Mission Button
                QGCButton {
                    text: "🚀 Start Mission"
                    enabled: _activeVehicle && _missionController.readyForMission
                    Layout.fillWidth: true
                    background: Rectangle { color: "#27ae60"; radius: 8 }
                    onClicked: _missionController.startMission()
                }

                Text {
                    text: "Advanced Controls"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    QGCButton {
                        text: "Orbit"
                        enabled: _activeVehicle && guidedActionsController.showOrbit
                        Layout.fillWidth: true
                        onClicked: guidedActionsController.confirmAction(guidedActionsController.actionOrbit)
                    }

                    QGCButton {
                        text: "Change Alt"
                        enabled: _activeVehicle && guidedActionsController.showChangeAlt
                        Layout.fillWidth: true
                        onClicked: guidedActionsController.confirmAction(guidedActionsController.actionChangeAlt)
                    }
                }

                Item { Layout.fillHeight: true } // spacer
                }
            }
        }
    }

    // ── Keep original overlays and toolbar on top ────────────────────────────
    FlyViewToolBar {
        id: toolbar
        guidedValueSlider: _guidedValueSlider
        visible: !QGroundControl.videoManager.fullScreen
    }

    FlyViewWidgetLayer {
        id: widgetLayer
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: _widgetMargin
        anchors.topMargin: toolbar.height + _widgetMargin
        anchors.rightMargin: 380 + _widgetMargin  // Leave space for right panel
        z: _fullItemZorder + 2
        parentToolInsets: _toolInsets
        mapControl: _mapControl
        visible: !QGroundControl.videoManager.fullScreen && _mainWindowIsMap
    }

    FlyViewCustomLayer {
        id: customOverlay
        anchors.fill: widgetLayer
        z: _fullItemZorder + 2
        parentToolInsets: widgetLayer.totalToolInsets
        mapControl: _mapControl
        visible: !QGroundControl.videoManager.fullScreen && _mainWindowIsMap
    }

    FlyViewInsetViewer {
        id: widgetLayerInsetViewer
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: widgetLayer.right
        z: widgetLayer.z + 1
        insetsToView: widgetLayer.totalToolInsets
        visible: false
    }

    GuidedActionsController {
        id: guidedActionsController
        missionController: _missionController
        guidedValueSlider: _guidedValueSlider
    }

    GuidedValueSlider {
        id: guidedValueSlider
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: toolbar.height
        z: QGroundControl.zOrderTopMost
        visible: false
    }
}
