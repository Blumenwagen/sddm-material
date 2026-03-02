import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    // Properties
    property string text: ""
    property string hoverText: ""
    property bool isIcon: false
    property int iconSize: 24
    property color backgroundColor: config.AccentColor || "#FF6B6B"
    property color hoverColor: config.AccentColorHover || "#FF8787"
    property color textColor: "#FFFFFF"
    
    // Signals
    signal clicked()
    
    // Dynamic width expansion for expressive hover
    property int expandedWidth: isIcon ? (56 + (hoverText !== "" ? hoverLabel.implicitWidth + 24 : 0)) : (labelOnly.implicitWidth + 48)
    width: (isIcon && !mouseArea.containsMouse) ? 56 : expandedWidth
    height: 56
    
    Behavior on width {
        NumberAnimation { duration: 250; easing.type: Easing.OutBack }
    }
    
    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: height / 2 // Guarantee perfect circle or pill
        color: mouseArea.containsMouse ? root.hoverColor : root.backgroundColor
        
        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        
        Behavior on scale {
            SpringAnimation { spring: 4.0; damping: 0.5 }
        }
        
        scale: mouseArea.pressed ? 0.92 : (mouseArea.containsMouse ? 1.05 : 1.0)
        
        Item {
            anchors.fill: parent
            clip: true
            
            // Label for normal text buttons
            Text {
                id: labelOnly
                visible: !root.isIcon && root.text !== ""
                anchors.centerIn: parent
                text: root.text
                color: root.textColor
                font.family: config.FontFamily || "sans-serif"
                font.pixelSize: 16
                font.weight: Font.Medium
            }

            // Fixed perfect icon square
            Text {
                id: iconText
                visible: root.isIcon && root.text !== ""
                text: root.text
                color: root.textColor
                font.family: "sans-serif"
                font.pixelSize: root.iconSize
                font.weight: Font.DemiBold
                
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 56
                height: 56
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            // Expanding text logic for icon pills
            Text {
                id: hoverLabel
                visible: root.isIcon && root.hoverText !== ""
                anchors.left: iconText.right
                anchors.leftMargin: -4
                anchors.verticalCenter: parent.verticalCenter
                text: root.hoverText
                color: root.textColor
                font.family: config.FontFamily || "sans-serif"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                
                opacity: mouseArea.containsMouse ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }
}
