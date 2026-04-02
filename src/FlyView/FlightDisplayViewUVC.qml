import QtQuick
import QtMultimedia

import QGroundControl

Rectangle {
    id:                 _root
    width:              parent.width
    height:             parent.height
    color:              Qt.rgba(0,0,0,0.75)
    clip:               true
    anchors.centerIn:   parent
    visible:            _videoManager.isUvc

    property var _videoManager: QGroundControl.videoManager

    function adjustAspectRatio() {
        //-- Set aspect ratio
        var resolution = camera.cameraFormat.resolution
        if (resolution.height > 0 && resolution.width > 0) {
            var aspectRatio = resolution.width / resolution.height
            _root.height = parent.height * aspectRatio
        }
    }

    MediaDevices {
        id: mediaDevices

        function findCameraDevice(cameraId) {
            var videoInputs = mediaDevices.videoInputs
            for (var i = 0; i < videoInputs.length; i++) {
                if (videoInputs[i].description === cameraId) {
                    return videoInputs[i]
                }
            }
            return mediaDevices.defaultVideoInput
        }
    }

    CaptureSession {
        camera: Camera {
            id:             camera
            cameraDevice:   mediaDevices.findCameraDevice(_videoManager.uvcVideoSourceID)
            active:         _videoManager.isUvc

            onCameraDeviceChanged: {
                if (active) {
                    adjustAspectRatio()
                }
            }

            onActiveChanged: {
                if (active) {
                    adjustAspectRatio()
                }
            }
        }
        videoOutput: videoOutput
    }

    VideoOutput {
        id:             videoOutput
        anchors.fill:   parent
        fillMode:       VideoOutput.PreserveAspectCrop
    }

    // Connect UVC video to YOLO detector
    Connections {
        target: _videoManager

        function onIsUvcChanged() {
            if (_videoManager.isUvc && _videoManager.yoloDetector) {
                _videoManager.connectUVCToYolo(videoOutput)
            } else {
                _videoManager.disconnectUVCFromYolo()
            }
        }
    }

    Component.onCompleted: {
        if (_videoManager.isUvc && _videoManager.yoloDetector) {
            _videoManager.connectUVCToYolo(videoOutput)
        }
    }

    Component.onDestruction: {
        _videoManager.disconnectUVCFromYolo()
    }
}
