import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.12
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

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordField.text = ""
            passwordField.textInput.forceActiveFocus()
            shakeAnim.start()
        }
    }

    SequentialAnimation {
        id: shakeAnim
        // Animate the transform instead of x to avoid breaking layout anchors
        NumberAnimation { target: loginTranslate; property: "x"; from: 0; to: 10; duration: 50 }
        NumberAnimation { target: loginTranslate; property: "x"; from: 10; to: -10; duration: 50 }
        NumberAnimation { target: loginTranslate; property: "x"; from: -10; to: 10; duration: 50 }
        NumberAnimation { target: loginTranslate; property: "x"; from: 10; to: -10; duration: 50 }
        NumberAnimation { target: loginTranslate; property: "x"; from: -10; to: 0; duration: 50 }
    }
    
    // --- Battery Info ---
    property string batteryPercent: ""
    property bool isBatteryCharging: false
    property bool hasBattery: false

    Timer {
        interval: 10000 // every 10 seconds
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var req = new XMLHttpRequest();
            req.onreadystatechange = function() {
                if (req.readyState === XMLHttpRequest.DONE) {
                    if (req.status === 200 || req.status === 0) {
                        var val = parseInt(req.responseText.trim());
                        if (!isNaN(val)) {
                            root.batteryPercent = val + "%";
                            root.hasBattery = true;
                        }
                    }
                }
            }
            req.open("GET", "file:///sys/class/power_supply/BAT0/capacity");
            req.send();

            var reqStatus = new XMLHttpRequest();
            reqStatus.onreadystatechange = function() {
                if (reqStatus.readyState === XMLHttpRequest.DONE) {
                    if (reqStatus.status === 200 || reqStatus.status === 0) {
                        var statusStr = reqStatus.responseText.trim();
                        root.isBatteryCharging = (statusStr === "Charging" || statusStr === "Full" || statusStr === "Not charging");
                    }
                }
            }
            reqStatus.open("GET", "file:///sys/class/power_supply/BAT0/status");
            reqStatus.send();
        }
    }

    // --- Top Right Area (Battery) ---
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 48
        spacing: 8
        visible: root.hasBattery
        z: 10
        
        Text {
            text: root.isBatteryCharging ? "⚡" : "🔋"
            color: config.TextColor || "#2D3436"
            font.pixelSize: 24
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: root.batteryPercent
            color: config.TextColor || "#2D3436"
            font.pixelSize: 24
            font.family: config.FontFamily || "sans-serif"
            font.bold: true
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // --- Bottom Right Area (Virtual Keyboard) ---
    MyComponents.ActionButton {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 48
        text: "⌨"
        hoverText: typeof textConstants !== "undefined" ? textConstants.layout : "Virtual Keyboard"
        isIcon: true
        iconSize: 26
        backgroundColor: config.SurfaceColor || "#FFFFFF"
        textColor: config.TextColor || "#2D3436"
        z: 10
        onClicked: {
            if (typeof Qt.inputMethod !== "undefined") {
                if (Qt.inputMethod.visible) {
                    Qt.inputMethod.hide();
                } else {
                    Qt.inputMethod.show();
                }
            }
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
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var currentTime = new Date()
            hourLabel.text = Qt.formatTime(currentTime, "hh")
            minuteLabel.text = Qt.formatTime(currentTime, "mm")
            dateLabel.text = Qt.formatDate(currentTime, "dddd, d MMMM")
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
            
            // Container to decouple Canvas and Date from the column's heavy -110 spacing
            Item {
                width: parent.width
                height: 140 // Counteract the negative spacing so it sits naturally
                
                Canvas {
                    id: separatorLine
                    width: 240
                    height: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 60 // Push it cleanly below the minutes
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.strokeStyle = config.TextColor || "#2D3436";
                        ctx.lineWidth = 4;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.moveTo(10, 15);
                        for (var i = 10; i < width - 10; i+=2) {
                            ctx.lineTo(i, 15 + Math.sin(i * 0.12) * 6);
                        }
                        ctx.stroke();
                    }
                }
                
                Text {
                    id: dateLabel
                    text: Qt.formatDate(new Date(), "dddd, d MMMM")
                    font.family: config.FontFamily || "sans-serif"
                    font.pixelSize: 32
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                    color: config.TextColor || "#2D3436"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: separatorLine.bottom
                    anchors.topMargin: 16
                    opacity: 0.8
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
            transform: Translate { id: loginTranslate }
            
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
                
                Text {
                    id: avatarInitial
                    anchors.centerIn: parent
                    visible: parent.avatarSource === "" || avatarImageBase.status === Image.Error
                    text: (root.users && root.users.length > 0 && root.currentUserIndex >= 0 && root.currentUserIndex < root.users.length && root.users[root.currentUserIndex].name) ? root.users[root.currentUserIndex].name.charAt(0).toUpperCase() : "U"
                    color: config.TextColor || "#2D3436"
                    font.pixelSize: 48
                    font.bold: true
                    renderType: Text.NativeRendering
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
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.currentUserIndex = (root.currentUserIndex + 1) % userModel.count
                    }
                    cursorShape: Qt.PointingHandCursor
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.width / 2
                        color: "#000000"
                        opacity: parent.containsMouse ? 0.1 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    hoverEnabled: true
                }
            }
            
            // Password Field & Side Login Circle Button
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16
                
                MyComponents.InputTextField {
                    id: passwordField
                    // placeholderText is now handled by InputTextField internally via textConstants
                    Layout.preferredWidth: 280
                    Layout.alignment: Qt.AlignVCenter
                    
                    onAccepted: {
                        loginButton.clicked()
                    }
                    
                    Component.onCompleted: passwordField.textInput.forceActiveFocus()
                }
                
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
                    hoverText: typeof textConstants !== "undefined" ? textConstants.powerOff : "Power"
                    isIcon: true
                    iconSize: 24
                    backgroundColor: config.SurfaceColor || "#FFFFFF"
                    textColor: config.TextColor || "#2D3436"
                    onClicked: sddm.powerOff()
                }
                
                MyComponents.ActionButton {
                    text: "↻"
                    hoverText: typeof textConstants !== "undefined" ? textConstants.reboot : "Restart"
                    isIcon: true
                    iconSize: 24
                    backgroundColor: config.SurfaceColor || "#FFFFFF"
                    textColor: config.TextColor || "#2D3436"
                    onClicked: sddm.reboot()
                }
                
                MyComponents.ActionButton {
                    text: "⏾"
                    hoverText: typeof textConstants !== "undefined" ? textConstants.suspend : "Sleep"
                    isIcon: true
                    iconSize: 24
                    backgroundColor: config.SurfaceColor || "#FFFFFF"
                    textColor: config.TextColor || "#2D3436"
                    onClicked: sddm.suspend()
                }
                
                MyComponents.ActionButton {
                    text: "⫶"
                    hoverText: (root.sessions && root.sessions.length > 0 && root.currentSessionIndex >= 0 && root.currentSessionIndex < root.sessions.length) ? root.sessions[root.currentSessionIndex].name : (typeof textConstants !== "undefined" ? textConstants.session : "Session")
                    isIcon: true
                    iconSize: 24
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
