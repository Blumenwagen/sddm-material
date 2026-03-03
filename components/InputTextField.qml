import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    property alias textInput: textInput
    property alias text: textInput.text
    property string placeholderText: typeof textConstants !== "undefined" ? textConstants.password : "Password"
    property bool isPassword: true
    property color surfaceColor: config.SurfaceColor || "#FFFFFF"
    property color textColor: config.TextColor || "#2D3436"
    property color hintColor: config.TextHintColor || "#636E72"
    property color accentColor: config.AccentColor || "#FF6B6B"
    property int radius: config.InputCornerRadius ? parseInt(config.InputCornerRadius) : 24
    
    signal accepted()

    width: 300
    height: 56

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: root.radius
        color: root.surfaceColor
        opacity: config.SurfaceColorAlpha ? parseFloat(config.SurfaceColorAlpha) : 0.8
        
        // Border animation for focus
        border.color: textInput.activeFocus ? root.accentColor : "transparent"
        border.width: textInput.activeFocus ? 2 : 0

        Behavior on border.width {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        // Slightly increase opacity and scale when focused
        scale: textInput.activeFocus ? 1.02 : 1.0
        opacity: textInput.activeFocus ? 1.0 : (config.SurfaceColorAlpha ? parseFloat(config.SurfaceColorAlpha) : 0.8)

        TextInput {
            id: textInput
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 80 // Extra margin to make room for caps lock indicator
            verticalAlignment: TextInput.AlignVCenter
            
            color: root.textColor
            font.family: config.FontFamily || "sans-serif"
            font.pixelSize: 16
            
            echoMode: root.isPassword ? TextInput.Password : TextInput.Normal
            passwordCharacter: "•"
            
            clip: true
            
            onAccepted: root.accepted()

            // Caps Lock Warning Indicator
            Text {
                id: capsLockWarning
                anchors.right: parent.right
                anchors.rightMargin: -60 // Position in the space we freed up
                anchors.verticalCenter: parent.verticalCenter
                text: "CAPS LOCK"
                color: root.accentColor
                font.family: textInput.font.family
                font.pixelSize: 10
                font.bold: true
                visible: typeof keyboard !== "undefined" && keyboard.capsLock && root.isPassword
            }

            Text {
                id: placeholder
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.placeholderText
                color: root.textColor // Match text color but lower opacity
                font.family: textInput.font.family
                font.pixelSize: textInput.font.pixelSize
                visible: !textInput.text && !textInput.inputMethodComposing
                opacity: 0.6
                
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
        }
    }
}
