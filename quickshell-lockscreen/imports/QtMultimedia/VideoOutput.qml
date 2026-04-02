import QtQuick 2.15
import QtMultimedia 6.0 as Native

Native.VideoOutput {
    id: videoOut
    
    // Shims for Qt5 constants for themes that use VideoOutput.PreserveAspectCrop
    enum FillMode { 
        Stretch = 0, 
        PreserveAspectFit = 1, 
        PreserveAspectCrop = 2 
    }
}
