import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl

ApplicationWindow {
    id:         _root
    title:      qsTr("Fly View - Simplified")
    visible:    true
    width:      1200
    height:     800
    
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // Video area (left side)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "black"
            
            Text {
                anchors.centerIn: parent
                text: "Video Feed Area\n(Working on YOLO integration)"
                color: "white"
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
            }
        }
        
        // Control panel (right side)
        Rectangle {
            Layout.width: 300
            Layout.fillHeight: true
            color: "#2c2c2c"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                
                Text {
                    text: "Vehicle Status"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    color: "#1e1e1e"
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Text {
                            text: _activeVehicle ? "Connected" : "No Vehicle"
                            color: _activeVehicle ? "green" : "red"
                        }
                        
                        Text {
                            text: _activeVehicle ? "Armed: " + (_activeVehicle.armed ? "Yes" : "No") : "N/A"
                            color: "white"
                        }
                        
                        Text {
                            text: _activeVehicle ? "Battery: " + (_activeVehicle.batteryPercent ? _activeVehicle.batteryPercent + "%" : "Unknown") : "N/A"
                            color: "white"
                        }
                    }
                }
                
                Item {
                    Layout.fillHeight: true
                }
                
                Button {
                    Layout.fillWidth: true
                    text: _activeVehicle ? (_activeVehicle.armed ? "Disarm" : "Arm") : "No Vehicle"
                    enabled: _activeVehicle !== null
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
                
                Button {
                    Layout.fillWidth: true
                    text: "Start Mission"
                    enabled: _activeVehicle !== null
                    onClicked: {
                        console.log("Start mission clicked")
                    }
                }
            }
        }
    }
}
