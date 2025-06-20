import QtQuick 2.15
import CustomControls 1.0
import QtQuick.Window 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5
import SerialCom 1.0
import "./"

ApplicationWindow {
    width: 1800
    height: 960
    visible: true
    title: qsTr("Car DashBoard")
    color: "#1E1E1E"
    property int nextSpeed: 60
    property int fuelLevel: 100
    property bool isReady: false // Mặc định là "Stop"
    property bool isAccelerating: false
    // Properties for mode tracking
    property string pModeState: "P" // P -> E -> D -> P
    property string aModeState: "A" // A -> S -> W -> A
    
    // Serial Handler
    SerialHandler {
        id: serialHandler
        onDataReceived: function(data) {
            console.log("Received data:", data);
            var cmd = data.trim();
            
            // Check if data starts with 'v' for speed value
            if (cmd.startsWith('v')) {
                var speed = parseInt(cmd.substring(1));
                if (!isNaN(speed) && isReady) {
                    speedLabel.value = speed;
                    leftGauge.value = speed;
                    rightGauge.value = speed;   
                    
                    // Set accelerating state based on speed
                    isAccelerating = speed > 0;
                    speedLabel.accelerating = speed > 0;
                }
            } else if (cmd === '1' && !isReady) {
                fuelLevel = 33;
            } else if (cmd === '2' && !isReady) {
                fuelLevel = 66;
            } else if (cmd === '3' && !isReady) {
                fuelLevel = 100;
            } else if (cmd === 'p') {
                // Cycle pModeState (P -> E -> D -> P)
                if (pModeState === "P") {
                    pModeState = "E"
                } else if (pModeState === "E") {
                    pModeState = "D"
                } else if (pModeState === "D") {
                    pModeState = "P"
                }
            } else if (cmd === 'a') {
                // Cycle aModeState (A -> S -> W -> A)
                if (aModeState === "A") {
                    aModeState = "S"
                } else if (aModeState === "S") {
                    aModeState = "W"
                } else if (aModeState === "W") {
                    aModeState = "A"
                }
            } else if (cmd === 's') {
                // Toggle Start/Stop
                isReady = !isReady;
                speedLabel.acceptingInput = isReady;
                
                if (!isReady) {
                    isAccelerating = false;
                    speedLabel.accelerating = false;
                    leftGauge.accelerating = false;
                    rightGauge.accelerating = false;
                } else {
                    speedLabel.forceActiveFocus();
                }
            }
        }
        onErrorOccurred: function(error) {
            console.error("Serial error:", error);
        }
        onIsConnectedChanged: function(connected) {
            console.log("Connection status:", connected);
        }
    }

    // Function to get color based on mode state
    function getModeColor(state) {
        switch(state) {
            case "P": return "#0000FF" // Blue
            case "E": return "#32D74B" // Green
            case "D": return "#FF3B30" // Red
            case "A": return "#FF3B30" // Red
            case "S": return "#32D74B" // Green
            case "W": return "#0000FF" // Blue
            default: return "#FFFFFF"
        }
    }

    Timer {
        id: fuelConsumptionTimer
        interval: 1000 // Check every second
        running: isReady && isAccelerating
        repeat: true
        onTriggered: {
            console.log("Keys.onPressed - speedLabel.accelerating:", speedLabel.accelerating);
            console.log("Keys.onPressed - leftGauge.accelerating:", leftGauge.accelerating);
            console.log("Keys.onPressed - rightGauge.accelerating:", rightGauge.accelerating);
            console.log("Keys.onPressed - isAccelerating:", isAccelerating);

            if (fuelLevel > 0) {
                // Calculate fuel consumption based on speed
                var consumption = 0;
                if (speedLabel.value > 200) {
                    consumption = 3; // High speed, high consumption
                } else if (speedLabel.value > 100) {
                    consumption = 2; // Medium speed, medium consumption
                } else if (speedLabel.value > 0) {
                    consumption = 1; // Low speed, low consumption
                }
                
                fuelLevel = Math.max(0, fuelLevel - consumption);
                console.log("Fuel Level:", fuelLevel, "Speed:", speedLabel.value);
            }
            if (fuelLevel <= 0) {
                // Stop everything when fuel runs out
                isAccelerating = false;
                speedLabel.accelerating = false;
                leftGauge.accelerating = false;
                rightGauge.accelerating = false;
                
                // Force stop state
                isReady = false;
                speedLabel.acceptingInput = false;
                
                // Reset all speeds to 0
                speedLabel.value = 0;
                leftGauge.value = 0;
                rightGauge.value = 0;
            }
        }
    }

    function generateRandom(maxLimit = 70) {
        let rand = Math.random() * maxLimit;
        rand = Math.floor(rand);
        return rand;
    }

    function speedColor(value) {
        if (value < 60) {
            return "green";
        } else if (value > 60 && value < 150) {
            return "yellow";
        } else {
            return "Red";
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            currentTime.text = Qt.formatDateTime(new Date(), "hh:mm");
        }
    }

    Timer {
        repeat: true
        interval: 3000
        running: true
        onTriggered: {
            nextSpeed = generateRandom();
        }
    }

    Shortcut {
        sequence: "Ctrl+Q"
        context: Qt.ApplicationShortcut
        onActivated: Qt.quit()
    }

    Image {
        id: dashboard
        width: parent.width
        height: parent.height
        anchors.centerIn: parent
        source: "qrc:/assets/Dashboard.svg"

        /*
          Top Bar Of Screen
        */

        Image {
            id: topBar
            width: 1357
            source: "qrc:/assets/Vector 70.svg"

            anchors {
                top: parent.top
                topMargin: 26.50
                horizontalCenter: parent.horizontalCenter
            }

            Image {
                id: headLight
                property bool indicator: false
                width: 42.5
                height: 38.25
                anchors {
                    top: parent.top
                    topMargin: 25
                    leftMargin: 230
                    left: parent.left
                }
                source: indicator ? "qrc:/assets/Low beam headlights.svg" : "qrc:/assets/Low_beam_headlights_white.svg"
                Behavior on indicator {
                    NumberAnimation {
                        duration: 300
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        headLight.indicator = !headLight.indicator;
                    }
                }
            }

            RowLayout {
                anchors.top: parent.top
                anchors.topMargin: 25
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Label {
                    id: currentTime
                    text: Qt.formatDateTime(new Date(), "hh:mm")
                    font.pixelSize: 32
                    font.family: "Inter"
                    font.bold: Font.DemiBold
                    color: "#FFFFFF"
                }

                // Serial Connection Panel
                Rectangle {
                    color: "#2D2D2D"
                    radius: 5
                    width: serialLayout.implicitWidth + 20
                    height: serialLayout.implicitHeight + 10

                    RowLayout {
                        id: serialLayout
                        anchors.centerIn: parent
                        spacing: 10

                        ComboBox {
                            id: portSelector
                            model: serialHandler.availablePorts
                            onCurrentTextChanged: serialHandler.currentPort = currentText
                            Layout.preferredWidth: 120
                        }

                        Button {
                            text: serialHandler.isConnected ? "Disconnect" : "Connect"
                            onClicked: {
                                if (serialHandler.isConnected) {
                                    serialHandler.disconnectFromPort();
                                } else {
                                    serialHandler.connectToPort();
                                }
                            }
                            background: Rectangle {
                                color: serialHandler.isConnected ? "#FF3B30" : "#32D74B"
                                radius: 5
                            }
                        }

                        Button {
                            text: "Refresh"
                            onClicked: serialHandler.refreshPorts()
                            background: Rectangle {
                                color: "#0066CC"
                                radius: 5
                            }
                        }
                    }
                }
            }

            Label {
                id: currentDate
                text: Qt.formatDateTime(new Date(), "dd/MM/yyyy")
                font.pixelSize: 32
                font.family: "Inter"
                font.bold: Font.DemiBold
                color: "#FFFFFF"
                anchors.right: parent.right
                anchors.rightMargin: 230
                anchors.top: parent.top
                anchors.topMargin: 25
            }
        }

        /*
          Speed Label
        */

        //        Label{
        //            id:speedLabel
        //            text: "68"
        //            font.pixelSize: 134
        //            font.family: "Inter"
        //            color: "#01E6DE"
        //            font.bold: Font.DemiBold
        //            anchors.top: parent.top
        //            anchors.topMargin:Math.floor(parent.height * 0.35)
        //            anchors.horizontalCenter: parent.horizontalCenter
        //        }

        Gauge {
            id: speedLabel
            width: 450
            height: 450
            property bool accelerating
            property bool acceptingInput: true
            focus: true
            value: accelerating ? maximumValue : 0
            maximumValue: 250
            Keys.forwardTo: parent

            anchors.top: parent.top
            anchors.topMargin: Math.floor(parent.height * 0.25)
            anchors.horizontalCenter: parent.horizontalCenter

            Component.onCompleted: {
                forceActiveFocus()
                acceptingInput = isReady
                console.log("SpeedLabel initialized with focus");
                console.log("SpeedLabel initialized - acceptingInput:", acceptingInput);
            }

            onVisibleChanged: {
                if (visible && acceptingInput) {
                    forceActiveFocus()
                }
            }

            onAcceptingInputChanged: {
                if (acceptingInput) {
                    forceActiveFocus()
                }
                console.log("AcceptingInput changed:", acceptingInput);
            }

            Behavior on value {
                NumberAnimation { duration: 1000 }
            }

            Timer {
                id: focusTimer
                interval: 50
                running: isReady
                repeat: true
                onTriggered: {
                    if (!speedLabel.activeFocus && speedLabel.acceptingInput) {
                        console.log("Restoring focus to speedLabel");
                        speedLabel.forceActiveFocus();
                    }
                }
            }

            Keys.onReleased: {
                if (!acceptingInput) {
                    return;
                }

                console.log("Key Released - Event key:", event.key);
                console.log("Before Release - States:", 
                    "isReady:", isReady, 
                    "fuelLevel:", fuelLevel,
                    "isAccelerating:", isAccelerating,
                    "speedLabel:", speedLabel.accelerating,
                    "leftGauge:", leftGauge.accelerating,
                    "rightGauge:", rightGauge.accelerating
                );

                if (event.key === Qt.Key_Space) {
                    speedLabel.accelerating = false;
                } else if (event.key === Qt.Key_Left) {
                    leftGauge.accelerating = false;
                } else if (event.key === Qt.Key_Right) {
                    rightGauge.accelerating = false;
                }
                isAccelerating = speedLabel.accelerating || leftGauge.accelerating || rightGauge.accelerating;

                console.log("After Release - States:", 
                    "isReady:", isReady, 
                    "fuelLevel:", fuelLevel,
                    "isAccelerating:", isAccelerating,
                    "speedLabel:", speedLabel.accelerating,
                    "leftGauge:", leftGauge.accelerating,
                    "rightGauge:", rightGauge.accelerating
                );
                event.accepted = true;
            }

            
            Keys.onPressed: {
                // Only process key events if accepting input
                if (!acceptingInput) {
                    console.log("Key events blocked - Not accepting input");
                    return;
                }

                console.log("Key Pressed - Event key:", event.key);
                console.log("Before Press - States:", 
                    "isReady:", isReady, 
                    "fuelLevel:", fuelLevel,
                    "isAccelerating:", isAccelerating,
                    "speedLabel:", speedLabel.accelerating,
                    "leftGauge:", leftGauge.accelerating,
                    "rightGauge:", rightGauge.accelerating
                );

                // Validate state for acceleration keys
                if (event.key === Qt.Key_Space || event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                    if (!isReady || fuelLevel <= 0) {
                        console.log("Acceleration blocked - Not ready or no fuel");
                        return;
                    }
                }

                
                if (event.key === Qt.Key_Space) {
                    speedLabel.accelerating = true;
                } else if (event.key === Qt.Key_Left) {
                    leftGauge.accelerating = true;
                } else if (event.key === Qt.Key_Right) {
                    rightGauge.accelerating = true;
                }
                isAccelerating = speedLabel.accelerating || leftGauge.accelerating || rightGauge.accelerating;
                event.accepted = true;
            }
        }

        Rectangle {
            id: speedLimit
            width: 130
            height: 130
            radius: height / 2
            color: "#D9D9D9"
            border.color: speedColor(maxSpeedlabel.text)
            border.width: 10

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50

            Label {
                id: maxSpeedlabel
                text: getRandomInt(150, speedLabel.maximumValue).toFixed(0)
                font.pixelSize: 45
                font.family: "Inter"
                font.bold: Font.Bold
                color: "#01E6DE"
                anchors.centerIn: parent

                function getRandomInt(min, max) {
                    return Math.floor(Math.random() * (max - min + 1)) + min;
                }
            }
        }

        Image {
            anchors {
                bottom: car.top
                bottomMargin: 30
                horizontalCenter: car.horizontalCenter
            }
            source: "qrc:/assets/Model 3.png"
        }

        Image {
            id: car
            anchors {
                bottom: speedLimit.top
                bottomMargin: 30
                horizontalCenter: speedLimit.horizontalCenter
            }
            source: "qrc:/assets/Car.svg"
        }

        // IMGonline.com.ua  ==> Compress Image With

        /*
          Left Road
        */

        Image {
            id: leftRoad
            width: 127
            height: 397
            anchors {
                left: speedLimit.left
                leftMargin: 100
                bottom: parent.bottom
                bottomMargin: 26.50
            }

            source: "qrc:/assets/Vector 2.svg"
        }

        Item {
            anchors {
                left: parent.left
                leftMargin: 290
                bottom: parent.bottom
                bottomMargin: 26.50 + 80
            }

            width: 350
            height: 180

            RadialBar {
                id: fuelGauge
                anchors.centerIn: parent
                width: 120
                height: 140
                penStyle: Qt.RoundCap
                dialType: RadialBar.FullDial
                progressColor: fuelLevel > 20 ? "#01E6DE" : "#FF3B30"
                backgroundColor: "#2D2D2D"
                dialWidth: 15
                startAngle: 180
                spanAngle: 180
                minValue: 0
                maxValue: 100
                value: fuelLevel
                showText: false

                Image {
                    source: "qrc:/assets/fuel.svg"
                    width: 40
                    height: 40
                    anchors.centerIn: parent
                }
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: fuelGauge.bottom
                spacing: 5
                anchors.topMargin: 10

            Label {
                text: fuelLevel + "%"
                font.pixelSize: 30
                font.family: "Inter"
                font.bold: Font.DemiBold
                color: "#FFFFFF"
                Layout.alignment: Qt.AlignHCenter
            }

            // Refuel buttons
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                
                Button {
                    text: "33%"
                    enabled: !isReady
                    onClicked: fuelLevel = 33
                    width: 60
                    height: 30
                    background: Rectangle {
                        color: parent.enabled ? "#32D74B" : "#666666"
                        radius: 5
                    }
                }
                Button {
                    text: "66%"
                    enabled: !isReady
                    onClicked: fuelLevel = 66
                    width: 60
                    height: 30
                    background: Rectangle {
                        color: parent.enabled ? "#32D74B" : "#666666" 
                        radius: 5
                    }
                }
                Button {
                    text: "100%"
                    enabled: !isReady
                    onClicked: fuelLevel = 100
                    width: 60
                    height: 30
                    background: Rectangle {
                        color: parent.enabled ? "#32D74B" : "#666666"
                        radius: 5
                    }
                }
            }
            }
        }

        /*
          Right Road
        */

        Image {
            id: rightRoad
            width: 127
            height: 397
            anchors {
                right: speedLimit.right
                rightMargin: 100
                bottom: parent.bottom
                bottomMargin: 26.50
            }

            source: "qrc:/assets/Vector 1.svg"
        }

        /*
          Right Side gear
        */

        RowLayout {
            spacing: 20
            anchors {
                right: parent.right
                rightMargin: 350
                bottom: parent.bottom
                bottomMargin: 26.50 + 65
            }

            Label {
                id: readyLabel
                text: isReady ? "Ready" : "Stop"
                font.pixelSize: 32
                font.family: "Inter"
                font.bold: Font.Normal
                font.capitalization: Font.AllUppercase
                color: isReady ? "#32D74B" : "#FF3B30" // Xanh khi "Ready", đỏ khi "Stop"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Before Ready Toggle - States:", 
                            "isReady:", isReady, 
                            "fuelLevel:", fuelLevel,
                            "isAccelerating:", isAccelerating,
                            "speedLabel:", speedLabel.accelerating,
                            "leftGauge:", leftGauge.accelerating,
                            "rightGauge:", rightGauge.accelerating
                        );

                        isReady = !isReady;
                        speedLabel.acceptingInput = isReady;
                        
                        if (!isReady) {
                            isAccelerating = false;
                            speedLabel.accelerating = false;
                            leftGauge.accelerating = false;
                            rightGauge.accelerating = false;
                        } else {
                            speedLabel.forceActiveFocus();
                        }

                        console.log("After Ready Toggle - States:", 
                            "isReady:", isReady, 
                            "fuelLevel:", fuelLevel,
                            "isAccelerating:", isAccelerating,
                            "speedLabel:", speedLabel.accelerating,
                            "leftGauge:", leftGauge.accelerating,
                            "rightGauge:", rightGauge.accelerating
                        );
                    }
                }
            }

            Label {
                text: pModeState
                font.pixelSize: 32
                font.family: "Inter"
                font.bold: Font.Normal
                font.capitalization: Font.AllUppercase
                color: getModeColor(pModeState)
                opacity: 1.0
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // P -> E -> D -> P cycle
                        if (pModeState === "P") {
                            pModeState = "E"
                        } else if (pModeState === "E") {
                            pModeState = "D"
                        } else if (pModeState === "D") {
                            pModeState = "P"
                        }
                    }
                }
            }
            
            Label {
                text: aModeState
                font.pixelSize: 32
                font.family: "Inter"
                font.bold: Font.Normal
                font.capitalization: Font.AllUppercase
                color: getModeColor(aModeState)
                opacity: 1.0
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // A -> S -> W -> A cycle
                        if (aModeState === "A") {
                            aModeState = "S"
                        } else if (aModeState === "S") {
                            aModeState = "W"
                        } else if (aModeState === "W") {
                            aModeState = "A"
                        }
                    }
                }
            }

        }

        /*Left Side Icons*/
        Image {
            id: forthLeftIndicator
            property bool parkingLightOn: true
            width: 72
            height: 62
            anchors {
                left: parent.left
                leftMargin: 175
                bottom: thirdLeftIndicator.top
                bottomMargin: 25
            }
            Behavior on parkingLightOn {
                NumberAnimation {
                    duration: 300
                }
            }
            source: parkingLightOn ? "qrc:/assets/Parking lights.svg" : "qrc:/assets/Parking_lights_white.svg"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    forthLeftIndicator.parkingLightOn = !forthLeftIndicator.parkingLightOn;
                }
            }
        }

        Image {
            id: thirdLeftIndicator
            property bool lightOn: true
            width: 52
            height: 70.2
            anchors {
                left: parent.left
                leftMargin: 145
                bottom: secondLeftIndicator.top
                bottomMargin: 25
            }
            source: lightOn ? "qrc:/assets/Lights.svg" : "qrc:/assets/Light_White.svg"
            Behavior on lightOn {
                NumberAnimation {
                    duration: 300
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    thirdLeftIndicator.lightOn = !thirdLeftIndicator.lightOn;
                }
            }
        }

        Image {
            id: secondLeftIndicator
            property bool headLightOn: true
            width: 51
            height: 51
            anchors {
                left: parent.left
                leftMargin: 125
                bottom: firstLeftIndicator.top
                bottomMargin: 30
            }
            Behavior on headLightOn {
                NumberAnimation {
                    duration: 300
                }
            }
            source: headLightOn ? "qrc:/assets/Low beam headlights.svg" : "qrc:/assets/Low_beam_headlights_white.svg"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    secondLeftIndicator.headLightOn = !secondLeftIndicator.headLightOn;
                }
            }
        }

        Image {
            id: firstLeftIndicator
            property bool rareLightOn: false
            width: 51
            height: 51
            anchors {
                left: parent.left
                leftMargin: 100
                verticalCenter: speedLabel.verticalCenter
            }
            source: rareLightOn ? "qrc:/assets/Rare_fog_lights_red.svg" : "qrc:/assets/Rare fog lights.svg"
            Behavior on rareLightOn {
                NumberAnimation {
                    duration: 300
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    firstLeftIndicator.rareLightOn = !firstLeftIndicator.rareLightOn;
                }
            }
        }

        /*Right Side Icons*/

        Image {
            id: forthRightIndicator
            property bool indicator: true
            width: 56.83
            height: 36.17
            anchors {
                right: parent.right
                rightMargin: 195
                bottom: thirdRightIndicator.top
                bottomMargin: 50
            }
            source: indicator ? "qrc:/assets/FourthRightIcon.svg" : "qrc:/assets/FourthRightIcon_red.svg"
            Behavior on indicator {
                NumberAnimation {
                    duration: 300
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    forthRightIndicator.indicator = !forthRightIndicator.indicator;
                }
            }
        }

        Image {
            id: thirdRightIndicator
            property bool indicator: true
            width: 56.83
            height: 36.17
            anchors {
                right: parent.right
                rightMargin: 155
                bottom: secondRightIndicator.top
                bottomMargin: 50
            }
            source: indicator ? "qrc:/assets/thirdRightIcon.svg" : "qrc:/assets/thirdRightIcon_red.svg"
            Behavior on indicator {
                NumberAnimation {
                    duration: 300
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    thirdRightIndicator.indicator = !thirdRightIndicator.indicator;
                }
            }
        }

        Image {
            id: secondRightIndicator
            property bool indicator: true
            width: 56.83
            height: 36.17
            anchors {
                right: parent.right
                rightMargin: 125
                bottom: firstRightIndicator.top
                bottomMargin: 50
            }
            source: indicator ? "qrc:/assets/SecondRightIcon.svg" : "qrc:/assets/SecondRightIcon_red.svg"
            Behavior on indicator {
                NumberAnimation {
                    duration: 300
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    secondRightIndicator.indicator = !secondRightIndicator.indicator;
                }
            }
        }

        Image {
            id: firstRightIndicator
            property bool sheetBelt: true
            width: 36
            height: 45
            anchors {
                right: parent.right
                rightMargin: 100
                verticalCenter: speedLabel.verticalCenter
            }
            source: sheetBelt ? "qrc:/assets/FirstRightIcon.svg" : "qrc:/assets/FirstRightIcon_grey.svg"
            Behavior on sheetBelt {
                NumberAnimation {
                    duration: 300
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    firstRightIndicator.sheetBelt = !firstRightIndicator.sheetBelt;
                }
            }
        }

        SideGauge {
            id: leftGauge
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: parent.width / 7
            }
            property bool accelerating
            width: 400
            height: 400
            value: accelerating ? maximumValue : 0
            maximumValue: 250
            Component.onCompleted: forceActiveFocus()
            Behavior on value {
                NumberAnimation {
                    duration: 1000
                }
            }
        }

        // Progress Bar
        RadialBar {
            id: radialBar
            visible: false
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: parent.width / 6
            }

            width: 338
            height: 338
            penStyle: Qt.RoundCap
            dialType: RadialBar.NoDial
            progressColor: "#01E4E0"
            backgroundColor: "transparent"
            dialWidth: 17
            startAngle: 270
            spanAngle: 3.6 * value
            minValue: 0
            maxValue: 100
            value: accelerating ? maxValue : 65
            textFont {
                family: "inter"
                italic: false
                bold: Font.Medium
                pixelSize: 60
            }
            showText: false
            suffixText: ""
            textColor: "#FFFFFF"

            property bool accelerating
            Behavior on value {
                NumberAnimation {
                    duration: 1000
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                Label {
                    text: radialBar.value.toFixed(0) + "%"
                    font.pixelSize: 65
                    font.family: "Inter"
                    font.bold: Font.Normal
                    color: "#FFFFFF"
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "Battery charge"
                    font.pixelSize: 28
                    font.family: "Inter"
                    font.bold: Font.Normal
                    opacity: 0.8
                    color: "#FFFFFF"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        SideGauge {
            id: rightGauge
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: parent.width / 7
            }
            property bool accelerating
            width: 400
            height: 400
            value: accelerating ? maximumValue : 0
            maximumValue: 250
            Component.onCompleted: forceActiveFocus()
            Behavior on value {
                NumberAnimation {
                    duration: 1000
                }
            }
        }
        ColumnLayout {
            visible: false
            spacing: 40

            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: parent.width / 6
            }

            RowLayout {
                spacing: 30
                Image {
                    width: 72
                    height: 50
                    source: "qrc:/assets/road.svg"
                }

                ColumnLayout {
                    Label {
                        text: "188 KM"
                        font.pixelSize: 30
                        font.family: "Inter"
                        font.bold: Font.Normal
                        opacity: 0.8
                        color: "#FFFFFF"
                    }
                    Label {
                        text: "Distance"
                        font.pixelSize: 20
                        font.family: "Inter"
                        font.bold: Font.Normal
                        opacity: 0.8
                        color: "#FFFFFF"
                    }
                }
            }
            RowLayout {
                spacing: 30
                Image {
                    width: 72
                    height: 78
                    source: "qrc:/assets/fuel.svg"
                }

                ColumnLayout {
                    Label {
                        text: "34 mpg"
                        font.pixelSize: 30
                        font.family: "Inter"
                        font.bold: Font.Normal
                        opacity: 0.8
                        color: "#FFFFFF"
                    }
                    Label {
                        text: "Avg. Fuel Usage"
                        font.pixelSize: 20
                        font.family: "Inter"
                        font.bold: Font.Normal
                        opacity: 0.8
                        color: "#FFFFFF"
                    }
                }
            }
            RowLayout {
                spacing: 30
                Image {
                    width: 72
                    height: 72
                    source: "qrc:/assets/speedometer.svg"
                }

                ColumnLayout {
                    Label {
                        text: "78 mph"
                        font.pixelSize: 30
                        font.family: "Inter"
                        font.bold: Font.Normal
                        opacity: 0.8
                        color: "#FFFFFF"
                    }
                    Label {
                        text: "Avg. Speed"
                        font.pixelSize: 20
                        font.family: "Inter"
                        font.bold: Font.Normal
                        opacity: 0.8
                        color: "#FFFFFF"
                    }
                }
            }
        }
    }
}
