import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import "components" as MyComponents

Rectangle {
    id: root
    
    // The background color defined in theme.conf
    color: config.BackgroundColor || "#FFEADD"
    width: 1920
    height: 1080
    
    // Background Image Layer
    Image {
        id: bgImage
        anchors.fill: parent
        source: config.Background ? config.Background : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        
        // Subtle Material 3 fade-in
        opacity: status === Image.Ready ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 1000; easing.type: Easing.OutCubic }
        }
    }
    
    // --- Data Management ---
    property int currentSessionIndex: sessionModel.lastIndex
    property int currentUserIndex: userModel.lastIndex
    
    // Map SDDM indices to safe values
    onCurrentUserIndexChanged: {
        if (currentUserIndex < 0 || currentUserIndex >= userModel.count) {
            currentUserIndex = 0;
        }
    }
    
    // --- Model Data Extraction via Item Views ---
    // SDDM's ListModels only reliably expose their named roles (name, icon, etc) 
    // inside QML Item View delegates. We use a hidden Item with Repeaters to extract them.
    
    property var users: []
    property var sessions: []

    Item {
        visible: false
        Repeater {
            model: userModel
            Item {
                Component.onCompleted: {
                    var newArray = root.users.slice();
                    newArray[index] = { name: model.name, realName: model.realName, icon: model.icon, homeDir: model.homeDir };
                    root.users = newArray;
                }
            }
        }
        Repeater {
            model: sessionModel
            Item {
                Component.onCompleted: {
                    var newArray = root.sessions.slice();
                    newArray[index] = { name: model.name, comment: model.comment };
                    root.sessions = newArray;
                }
            }
        }
    }
    
    // --- Clock & Abstract Canvas ---
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var currentTime = new Date()
            hourLabel.text = Qt.formatTime(currentTime, "hh")
            minuteLabel.text = Qt.formatTime(currentTime, "mm")
        }
    }
    
    // Opaque rounded rectangle connecting to the screen edge with inverted inner curves
    Canvas {
        id: bgShape
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 700
        z: 0 // above wallpaper, below clock
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = config.SurfaceColor || "#FFFFFF";
            ctx.beginPath();
            
            var h = height;
            var w = 580;       // Width extending from left edge
            var blockH = 780;  // Height of the rounded clock block
            var startY = (h - blockH) / 2;
            var endY = startY + blockH;
            var r = 48;        // Standard outer corner radius
            var invR = 64;     // Inverted corner radius for edge flow
            
            ctx.moveTo(0, startY - invR);
            
            // Top-left inverted corner swooping in from screen edge
            ctx.quadraticCurveTo(0, startY, invR, startY);
            
            // Top edge
            ctx.lineTo(w - r, startY);
            
            // Top-right normal corner
            ctx.quadraticCurveTo(w, startY, w, startY + r);
            
            // Right edge
            ctx.lineTo(w, endY - r);
            
            // Bottom-right normal corner
            ctx.quadraticCurveTo(w, endY, w - r, endY);
            
            // Bottom edge
            ctx.lineTo(invR, endY);
            
            // Bottom-left inverted corner swooping back out to the screen edge
            ctx.quadraticCurveTo(0, endY, 0, endY + invR);
            
            ctx.lineTo(0, startY - invR);
            ctx.fill();
        }
    }
    
    Item {
        id: timeContainer
        anchors.left: parent.left
        anchors.leftMargin: 60
        anchors.verticalCenter: parent.verticalCenter
        width: 480
        height: timeLayout.implicitHeight
        z: 1
        
        Column {
            id: timeLayout
            anchors.fill: parent
            spacing: -110
            
            Text {
                id: hourLabel
                text: Qt.formatTime(new Date(), "hh")
                font.family: "Unique"
                font.pixelSize: 420
                font.weight: Font.Bold
                font.letterSpacing: -12
                font.hintingPreference: Font.PreferFullHinting
                renderType: Text.QtRendering
                antialiasing: true
                smooth: true
                color: config.TextColor || "#2D3436"
                anchors.horizontalCenter: parent.horizontalCenter
                rotation: -4
                
                scale: 0.6
                opacity: 0
                Component.onCompleted: { scaleAnim.start(); opacityAnim.start(); }
                SpringAnimation on scale { id: scaleAnim; to: 1.0; spring: 4.0; damping: 0.35 }
                NumberAnimation on opacity { id: opacityAnim; to: 1.0; duration: 800; easing.type: Easing.OutCubic }
                
                SequentialAnimation on rotation {
                    loops: Animation.Infinite
                    NumberAnimation { to: -1; duration: 3000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -4; duration: 3000; easing.type: Easing.InOutSine }
                }
            }
            
            Text {
                id: minuteLabel
                text: Qt.formatTime(new Date(), "mm")
                font.family: "Unique"
                font.pixelSize: 420
                font.weight: Font.Bold
                font.letterSpacing: -12
                font.hintingPreference: Font.PreferFullHinting
                renderType: Text.QtRendering
                antialiasing: true
                smooth: true
                color: config.AccentColor || "#FF6B6B"
                anchors.horizontalCenter: parent.horizontalCenter
                rotation: 3
                
                scale: 0.6
                opacity: 0
                Component.onCompleted: { minScaleAnim.start(); minOpacityAnim.start(); }
                SpringAnimation on scale { id: minScaleAnim; to: 1.0; spring: 3.5; damping: 0.4 }
                NumberAnimation on opacity { id: minOpacityAnim; to: 1.0; duration: 1000; easing.type: Easing.OutCubic }
                
                SequentialAnimation on rotation {
                    loops: Animation.Infinite
                    NumberAnimation { to: 6; duration: 4000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 3; duration: 4000; easing.type: Easing.InOutSine }
                }
            }
            
            // The drawn squiggly line from the sketch serving as a dynamic divider
            Canvas {
                width: 240
                height: 30
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 30
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.strokeStyle = config.TextColor || "#2D3436";
                    ctx.lineWidth = 4;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.moveTo(10, 15);
                    // A simple hand-drawn-style sine wave
                    for (var i = 10; i < width - 10; i+=2) {
                        ctx.lineTo(i, 15 + Math.sin(i * 0.12) * 6);
                    }
                    ctx.stroke();
                }
            }
        }
    }
    
    // --- Sketch Login Area ---
    Item {
        anchors.right: parent.right
        anchors.rightMargin: 160
        anchors.verticalCenter: parent.verticalCenter
        width: 400
        height: loginLayout.implicitHeight
        
        ColumnLayout {
            id: loginLayout
            anchors.fill: parent
            spacing: 28
            
            // Central Avatar Above Inputs exactly as placed in Sketch
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 96
                height: 96
                radius: 48
                color: config.SurfaceColor || "#FFFFFF"
                border.width: 4
                border.color: config.BackgroundColor || "#EEEEEE"
                // Do not use clip: true here, it forces rectangular clipping
                
                property string avatarSource: (root.users && root.users.length > 0 && root.currentUserIndex >= 0 && root.currentUserIndex < root.users.length) ? (root.users[root.currentUserIndex].icon || "") : ""
                
                // Fallback Text Initial
                Text {
                    id: avatarInitial
                    anchors.centerIn: parent
                    visible: parent.avatarSource === "" || avatarImageBase.status === Image.Error
                    text: (root.users && root.users.length > 0 && root.currentUserIndex >= 0 && root.currentUserIndex < root.users.length && root.users[root.currentUserIndex].name) ? root.users[root.currentUserIndex].name.charAt(0).toUpperCase() : "U"
                    color: config.TextColor || "#2D3436"
                    font.pixelSize: 42
                    font.bold: true
                }
                
                // User Face Image
                Image {
                    id: avatarImageBase
                    anchors.fill: parent
                    anchors.margins: parent.border.width // Don't occlude border
                    visible: source.toString() !== "" && status !== Image.Error
                    source: parent.avatarSource ? parent.avatarSource : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(width, height)
                    asynchronous: true
                    mipmap: true
                    
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: avatarImageBase.width
                            height: avatarImageBase.height
                            radius: width / 2
                            visible: true
                        }
                    }
                    
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("Failed to load avatar image: " + source);
                        }
                    }
                }
            }
            
            // Password Field & Side Login Circle Button
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                
                MyComponents.InputTextField {
                    id: passwordField
                    placeholderText: "Password"
                    Layout.preferredWidth: 260
                    Layout.alignment: Qt.AlignVCenter
                    
                    onAccepted: {
                        loginButton.clicked()
                    }
                    
                    Component.onCompleted: passwordField.textInput.forceActiveFocus()
                }
                
                // Small Circle inline action for Submit
                MyComponents.ActionButton {
                    id: loginButton
                    text: "➔" // Minimalist arrow
                    isIcon: true
                    iconSize: 24
                    Layout.alignment: Qt.AlignVCenter
                    
                    backgroundColor: config.AccentColor || "#FF6B6B"
                    textColor: "#FFFFFF"
                    
                    onClicked: {
                        var user = (root.users && root.users.length > 0 && root.currentUserIndex >= 0 && root.currentUserIndex < root.users.length) ? root.users[root.currentUserIndex].name : ""
                        sddm.login(user, passwordField.text, root.currentSessionIndex)
                    }
                }
            }
            
            // System Action Buttons vertically structured under Login
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 24
                spacing: 16
                
                MyComponents.ActionButton {
                    text: "⏻"
                    hoverText: "Power"
                    isIcon: true
                    iconSize: 22
                    backgroundColor: config.SurfaceColor || "#FFFFFF"
                    textColor: config.TextColor || "#2D3436"
                    onClicked: sddm.powerOff()
                }
                
                MyComponents.ActionButton {
                    text: "↻"
                    hoverText: "Restart"
                    isIcon: true
                    iconSize: 22
                    backgroundColor: config.SurfaceColor || "#FFFFFF"
                    textColor: config.TextColor || "#2D3436"
                    onClicked: sddm.reboot()
                }
                
                MyComponents.ActionButton {
                    text: "⏾"
                    hoverText: "Sleep"
                    isIcon: true
                    iconSize: 22
                    backgroundColor: config.SurfaceColor || "#FFFFFF"
                    textColor: config.TextColor || "#2D3436"
                    onClicked: sddm.suspend()
                }
                
                MyComponents.ActionButton {
                    text: "⫶"
                    hoverText: (root.sessions && root.sessions.length > 0 && root.currentSessionIndex >= 0 && root.currentSessionIndex < root.sessions.length) ? root.sessions[root.currentSessionIndex].name : "Session"
                    isIcon: true
                    iconSize: 22
                    backgroundColor: config.SurfaceColor || "#FFFFFF"
                    textColor: config.TextColor || "#2D3436"
                    onClicked: {
                        root.currentSessionIndex = (root.currentSessionIndex + 1) % sessionModel.count
                    }
                }
            }
        }
    }
}
