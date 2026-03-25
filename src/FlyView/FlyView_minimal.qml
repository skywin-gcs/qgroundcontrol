import QtQuick
import QtQuick.Controls

ApplicationWindow {
    title: "QGroundControl Test"
    visible: true
    width: 800
    height: 600
    
    Rectangle {
        anchors.fill: parent
        color: "#2c2c2c"
        
        Text {
            anchors.centerIn: parent
            text: "QGroundControl is Running!\nYOLO Integration Ready"
            color: "white"
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
        }
        
        Button {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 20
            text: "Test Button"
            onClicked: {
                console.log("Button clicked - QML working!")
            }
        }
    }
}
