import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

Rectangle {
    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }
    readonly property real s: Screen.height / 768
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0c0a08"

    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int  userIndex:   userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    // Theme colors
    readonly property color amberHot:   "#e8803c"
    readonly property color amberSoft:  "#c8a060"
    readonly property color tealSign:   "#4dd8c4"
    readonly property color textWhite:  "#f0ece4"
    readonly property color textDim:    "#907860"

    // Clock color scheme (edit these to restyle the clock independently)
    readonly property color clockHourColor:      textWhite
    readonly property color clockSeparatorColor: amberHot
    readonly property color clockMinuteColor:    amberSoft

    // ---- Localization ----
    // Locale is read strictly from theme.conf, key "Locale" in [General],
    // e.g. "Locale=ru_RU". Falls back to "en" if missing/unsupported.
    // NOTE: SDDM's ini parser matches keys by exact case — "Locale" != "locale".
    // Getting the case wrong silently falls back to defaults with no error, so
    // when adding new theme.conf keys always match the exact casing used here.
    readonly property var translations: ({
        "en": { password: "password", login: "LOGIN", incorrectPassword: "incorrect password", session: "Session", restart: "RESTART", shutdown: "SHUT DOWN",
                weatherToday: "In the city", weatherWind: "wind", weatherPrecip: "precipitation possible", unitMs: "m/s" },
        "ru": { password: "пароль",   login: "ВХОД",  incorrectPassword: "неверный пароль",      session: "Сессия", restart: "ПЕРЕЗАГРУЗКА", shutdown: "ВЫКЛЮЧИТЬ",
                weatherToday: "В сити", weatherWind: "ветер", weatherPrecip: "возможны осадки", unitMs: "м/с" },
        "de": { password: "passwort", login: "ANMELDEN", incorrectPassword: "falsches passwort",  session: "Sitzung", restart: "NEUSTART", shutdown: "AUSSCHALTEN",
                weatherToday: "In der Stadt", weatherWind: "Wind", weatherPrecip: "Niederschlag möglich", unitMs: "m/s" }
    })

    readonly property string configLocale: (typeof config !== "undefined" && config.Locale) ? config.Locale : ""
    readonly property string lang: {
        var code = root.configLocale.length >= 2 ? root.configLocale.substring(0, 2).toLowerCase() : "en"
        return translations[code] ? code : "en"
    }
    // Full locale tag for Qt.locale(), e.g. "ru_RU". Falls back to "en_US".
    readonly property string localeTag: root.configLocale.length > 0 ? root.configLocale : "en_US"

    function t(key) { return root.translations[root.lang][key] }

    // ---- Weather ----
    // Set to false once everything is confirmed stable to silence the [weather] logs.
    readonly property bool weatherDebug: true
    function _wlog() { if (root.weatherDebug) console.warn.apply(console, arguments) }

    // How often we poll Open-Meteo. This is the ONLY place that controls request
    // frequency — everything else (Timer below) just reads this value.
    readonly property int weatherRefreshIntervalMs: 15 * 60 * 1000 // 15 minutes

    // If the API doesn't respond within this window, abort and treat it as failed
    // rather than leaving a stale XHR hanging forever (bit us before with wttr.in).
    readonly property int weatherTimeoutMs: 10 * 1000 // 10 seconds

    // Precipitation probability (%) at/above which we append the "precipitation
    // possible" phrase to the weather line.
    readonly property int weatherRainThreshold: 30

    // Coordinates are read from theme.conf, keys "WeatherLat"/"WeatherLon" in [General],
    // e.g. "WeatherLat=55.7491" / "WeatherLon=37.6176". Falls back to Moscow if unset
    // or if the value doesn't look like a valid decimal number after normalization.
    readonly property string weatherLat: root._resolveCoord(typeof config !== "undefined" ? config.WeatherLat : undefined, "55.7491")
    readonly property string weatherLon: root._resolveCoord(typeof config !== "undefined" ? config.WeatherLon : undefined, "37.6176")

    // SDDM's ini reader can treat a numeric-looking theme.conf value as a
    // QVariant(double) and stringify it using the *current* Qt locale — e.g. under
    // ru_RU that means "55,7558" with a comma instead of a dot, which would
    // otherwise silently break the URL query string below. We normalize the
    // separator and then validate the result actually looks like a coordinate;
    // if not (missing key, garbage value, etc.) we fall back to a known-good default
    // instead of sending a malformed request to the API.
    function _resolveCoord(raw, fallback) {
        if (raw === undefined || raw === null || raw === "") return fallback
        var normalized = String(raw).replace(",", ".")
        return /^-?\d+(\.\d+)?$/.test(normalized) ? normalized : fallback
    }

    readonly property string weatherApiUrl:
        "https://api.open-meteo.com/v1/forecast?latitude=" + root.weatherLat +
        "&longitude=" + root.weatherLon +
        "&current_weather=true&hourly=precipitation_probability&windspeed_unit=ms&timezone=auto"

    property bool   weatherReady:   false
    property string weatherTempC:   ""
    property string weatherWindMs:  ""
    property int    weatherRainPct: 0
    property var    _weatherXhr:    null

    // Aborts a hung request so a single slow/unresponsive API call can't leave the
    // theme waiting forever (see weatherTimeoutMs above).
    Timer {
        id: weatherTimeoutTimer
        interval: root.weatherTimeoutMs
        repeat: false
        onTriggered: {
            root._wlog("[weather] timed out after", root.weatherTimeoutMs, "ms, aborting")
            if (root._weatherXhr) root._weatherXhr.abort()
            root.weatherReady = false
        }
    }

    function fetchWeather() {
        root._wlog("[weather] fetch start, url:", root.weatherApiUrl)
        var xhr = new XMLHttpRequest()
        root._weatherXhr = xhr
        weatherTimeoutTimer.restart()

        // Fires on every readyState transition (0 -> 4); only DONE (4) carries a
        // final result, earlier states are just progress markers we log for debugging.
        xhr.onreadystatechange = function() {
            root._wlog("[weather] state:", xhr.readyState, "status:", xhr.status)
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            weatherTimeoutTimer.stop()
            if (xhr.status !== 200) {
                root._wlog("[weather] non-200, body snippet:", (xhr.responseText || "").substring(0, 200))
                root.weatherReady = false
                return
            }
            try {
                var data = JSON.parse(xhr.responseText)
                var cur = data.current_weather
                root.weatherTempC  = Math.round(cur.temperature).toString()
                root.weatherWindMs = Math.round(cur.windspeed).toString() // already m/s (windspeed_unit=ms)

                // Match the current hour's precipitation probability against
                // current_weather.time — Open-Meteo guarantees both arrays use the
                // same ISO8601 timestamp format, so a direct indexOf lookup is
                // reliable without needing to parse dates.
                var rainPct = 0
                if (data.hourly && data.hourly.time && data.hourly.precipitation_probability) {
                    var idx = data.hourly.time.indexOf(cur.time)
                    if (idx >= 0) rainPct = data.hourly.precipitation_probability[idx]
                }
                root.weatherRainPct = rainPct
                root.weatherReady = true
                root._wlog("[weather] parsed ok:", root.weatherTempC, "C,", root.weatherWindMs, "m/s, rain%", root.weatherRainPct)
            } catch (e) {
                root._wlog("[weather] parse error:", e)
                root.weatherReady = false
            }
        }
        xhr.onerror = function() {
            weatherTimeoutTimer.stop()
            root._wlog("[weather] network error (xhr.onerror)")
            root.weatherReady = false
        }
        xhr.open("GET", root.weatherApiUrl)
        xhr.send()
    }

    // Builds the localized weather line, or "" while data isn't available yet.
    function weatherLine() {
        if (!root.weatherReady) return ""
        var line = root.t("weatherToday") + " +" + root.weatherTempC + "°C, " +
                   root.t("weatherWind") + " " + root.weatherWindMs + " " + root.t("unitMs")
        if (root.weatherRainPct >= root.weatherRainThreshold) line += ", " + root.t("weatherPrecip")
        return line
    }

    // Single source of truth for request frequency: see weatherRefreshIntervalMs above.
    // triggeredOnStart fires the first fetch immediately; do not ALSO call
    // fetchWeather() from Component.onCompleted, or every refresh cycle sends two
    // requests instead of one.
    Timer {
        interval: root.weatherRefreshIntervalMs
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.fetchWeather()
    }

    TextConstants { id: textConstants }
    FontLoader { id: pfReg; source: "font/PixelifySans-Bold.ttf" }
    FontLoader { id: pfMed; source: "font/PixelifySans-Bold.ttf" }
    FontLoader { id: pfSemi; source: "font/PixelifySans-Bold.ttf" }
    FontLoader { id: pfBold; source: "font/PixelifySans-Bold.ttf" }

    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex
        visible: false; width: 100; height: 100
        delegate: Item { property string sName: model.name || "" }
    }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex
        visible: false; width: 100; height: 100
        delegate: Item {
            property string uName:  model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: passwordField.forceActiveFocus() }

    Component.onCompleted: { fadeAnim.start(); keyboard.numLock = true }
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1800; easing.type: Easing.OutCubic }

    // Background
    Rectangle { anchors.fill: parent; color: "#0c0a08" }
    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    // View Vignette
    RadialGradient {
        anchors.fill: parent; opacity: 0.88
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.6;  color: "#50000000" }
            GradientStop { position: 1.0;  color: "#f5000000" }
        }
    }
    // Bottom Shadow
    Rectangle {
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        height: 300 * s
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#f0000000" }
        }
    }

    // Particles
    Repeater {
        model: 18
        delegate: Item {
            id: em
            property real sx:  Math.random() * root.width * 0.6 + root.width * 0.2
            property real dr:  (Math.random() - 0.5) * 80
            property real dur: 5500 + Math.random() * 7000
            property real sz:  (1.5 + Math.random() * 2.5) * s
            property real dl:  Math.random() * 10000
            property int  ct:  Math.floor(Math.random() * 3)
            x: sx; y: root.height + 10; width: sz; height: sz; opacity: 0
            Rectangle {
                anchors.fill: parent; radius: width
                color: em.ct === 0 ? root.amberHot : em.ct === 1 ? root.amberSoft : root.tealSign
            }
            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: em.dl }
                ParallelAnimation {
                    NumberAnimation { target: em; property: "y"; from: root.height + 10; to: -20; duration: em.dur; easing.type: Easing.OutQuad }
                    NumberAnimation { target: em; property: "x"; from: em.sx; to: em.sx + em.dr; duration: em.dur; easing.type: Easing.InOutSine }
                    SequentialAnimation {
                        NumberAnimation { target: em; property: "opacity"; to: 0.85; duration: 700 }
                        PauseAnimation  { duration: em.dur - 1600 }
                        NumberAnimation { target: em; property: "opacity"; to: 0; duration: 900 }
                    }
                }
            }
        }
    }

    // Clock Unit
    Column {
        anchors.left: parent.left; anchors.top: parent.top
        anchors.leftMargin: 52 * s; anchors.topMargin: 48 * s
        spacing: 5 * s; opacity: root.ui

        Row {
            spacing: 12 * s
            Text {
                id: hT
                text: Qt.formatTime(new Date(), "HH")
                color: root.clockHourColor
                font.family: pfBold.name; font.pixelSize: 78 * s
                Timer { interval: 1000; running: true; repeat: true; onTriggered: hT.text = Qt.formatTime(new Date(), "HH") }
            }
            // Neon Needle
            Rectangle {
                width: 3 * s; height: 62 * s; color: root.clockSeparatorColor; radius: 1.5 * s
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: mT
                text: Qt.formatTime(new Date(), "mm")
                color: root.clockMinuteColor
                font.family: pfBold.name; font.pixelSize: 78 * s
                Timer { interval: 1000; running: true; repeat: true; onTriggered: mT.text = Qt.formatTime(new Date(), "mm") }
            }
        }
        Row {
            spacing: 8 * s
            Rectangle {
                width: 4 * s; height: 4 * s; color: root.amberHot
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity { loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                }
            }
            Text {
                text: Qt.formatDate(new Date(), Qt.locale(root.localeTag), "ddd, MMM d").toUpperCase()
                color: root.amberSoft; font.family: pfMed.name
                font.pixelSize: 11 * s; font.letterSpacing: 3 * s
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Row {
            spacing: 8 * s
            visible: root.weatherReady
            Rectangle {
                width: 4 * s; height: 4 * s; color: root.amberHot
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity { loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                }
            }
            Text {
                text: root.weatherLine().toUpperCase()
                color: root.amberSoft; font.family: pfMed.name
                font.pixelSize: 11 * s; font.letterSpacing: 3 * s
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Login Unit
    Item {
        id: loginPanel
        anchors.bottom: parent.bottom; anchors.bottomMargin: 90 * s
        anchors.horizontalCenter: parent.horizontalCenter
        width: 340 * s
        height: loginCol.implicitHeight
        opacity: root.ui

        Column {
            id: loginCol
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width; spacing: 0

            // Current User
                Text {
                    text: ((userHelper.currentItem && userHelper.currentItem.uName)
                          ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase()
                    color: root.textWhite; font.family: pfBold.name; font.pixelSize: 17 * s; font.letterSpacing: 4 * s
                    anchors.horizontalCenter: parent.horizontalCenter
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { var c = userModel.rowCount(); if (c > 1) root.userIndex = (root.userIndex + 1) % c } }
                }

            Item { width: 1; height: 8 * s }

            // Section Break
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 5 * s
                Rectangle { width: 44 * s; height: 1 * s; color: root.amberHot; opacity: 0.35; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 5 * s; height: 5 * s; color: root.amberHot; opacity: 0.65; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 44 * s; height: 1 * s; color: root.amberHot; opacity: 0.35; anchors.verticalCenter: parent.verticalCenter }
            }

            Item { width: 1; height: 20 * s }

            // Pass Input
            Item {
                width: parent.width; height: 52 * s
                anchors.horizontalCenter: parent.horizontalCenter

                // Base line
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                    height: 1 * s
                    color: Qt.rgba(0.91, 0.50, 0.24, 0.25)
                }
                // Focus track
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 2 * s
                    color: root.amberHot
                    width: passwordField.activeFocus ? parent.width : 0
                    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                }

                Text {
                    anchors.left: parent.left; anchors.leftMargin: 2 * s
                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1 * s
                    text: root.t("password")
                    color: root.amberSoft
                    font.family: pfMed.name; font.pixelSize: 14 * s; font.letterSpacing: 3 * s
                    opacity: passwordField.text.length === 0 ? 0.38 : 0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                }

                TextInput {
                    id: passwordField
                    anchors.left: parent.left; anchors.leftMargin: 2 * s
                    anchors.right: submitBtn.left; anchors.rightMargin: 12 * s
                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1 * s
                    color: root.textWhite
                    font.family: pfReg.name; font.pixelSize: 14 * s; font.letterSpacing: 3 * s
                    echoMode: TextInput.Password
                    // Clears any stale "wrong password" message left over from a
                    // previous failed attempt as soon as the user starts typing again.
                    onTextEdited: errorMessage.text = ""
                    passwordCharacter: "─"
                    focus: true; clip: true
                    cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                    selectionColor: root.amberHot
                    property bool wasClicked: false
                    Keys.onReturnPressed: doLogin()
                    Keys.onEnterPressed:  doLogin()
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            passwordField.forceActiveFocus()
                            passwordField.wasClicked = true
                        }
                    }
                }
                Rectangle {
                    id: customCursor
                    width: 2 * s; height: 16 * s
                    color: root.amberHot
                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1 * s
                    x: passwordField.x + passwordField.cursorRectangle.x
                    visible: passwordField.focus && (passwordField.text.length > 0 || passwordField.wasClicked)
                    SequentialAnimation {
                        loops: Animation.Infinite; running: customCursor.visible
                        NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                        NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                    }
                }

                // Submit Action
                Item {
                    id: submitBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -1 * s
                    width: loginText.implicitWidth + 16 * s
                    height: 24 * s

                    Rectangle {
                        anchors.fill: parent
                        color: submitMouse.containsMouse
                               ? Qt.rgba(0.91, 0.50, 0.24, 0.18)
                               : "transparent"
                        border.color: Qt.rgba(0.91, 0.50, 0.24, passwordField.text.length > 0 ? 0.55 : 0.20)
                        border.width: 1 * s
                        Behavior on color        { ColorAnimation { duration: 160 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        id: loginText
                        anchors.centerIn: parent
                        text: root.t("login")
                        color: root.amberHot
                        font.family: pfBold.name; font.pixelSize: 9 * s; font.letterSpacing: 2 * s
                        opacity: passwordField.text.length > 0 ? 1.0 : 0.30
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                    MouseArea {
                        id: submitMouse; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor; onClicked: doLogin()
                    }
                }
            }

            Item { width: 1; height: 10 * s }

            Text {
                id: errorMessage; anchors.horizontalCenter: parent.horizontalCenter
                text: ""; color: "#f07050"
                font.family: pfSemi.name; font.pixelSize: 10 * s; font.letterSpacing: 2 * s
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // Error Animation
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x + 10; duration: 45 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x - 8;  duration: 45 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x + 6;  duration: 45 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x - 4;  duration: 45 }
        NumberAnimation { target: loginPanel; property: "x"; to: loginPanel.x;      duration: 45 }
    }

    // Footer Area
    Rectangle {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 36 * s
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: 44 * s; anchors.rightMargin: 44 * s
        height: 1 * s; color: Qt.rgba(0.91, 0.50, 0.24, 0.18); opacity: root.ui
    }
    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: 44 * s; anchors.rightMargin: 44 * s
        height: 36 * s; opacity: root.ui * 0.9

        Row {
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
            Item {
                width: sessionText.implicitWidth + 24 * s; height: 22 * s
                Rectangle {
                    anchors.fill: parent; radius: 2 * s
                    color: "transparent"; border.color: root.amberHot; border.width: 1 * s
                    opacity: sessionMouse.containsMouse ? 1.0 : 0.30
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 1 * s; color: root.amberHot; radius: 1 * s
                        opacity: sessionMouse.containsMouse ? 0.15 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
                Row {
                    anchors.centerIn: parent; spacing: 6 * s
                    Rectangle { width: 4 * s; height: 4 * s; color: root.amberHot; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        id: sessionText
                        text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : root.t("session")).toUpperCase()
                        color: root.textWhite; font.family: pfMed.name; font.pixelSize: 9 * s; font.letterSpacing: 1 * s
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: sessionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (sessionModel && sessionModel.rowCount() > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() }
                }
            }
        }
        Row {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 14 * s
            Repeater {
                model: [{ key: "restart", act: 0 }, { key: "shutdown", act: 1 }]
                delegate: Item {
                    width: powerText.implicitWidth + 20 * s; height: 22 * s
                    Rectangle {
                        anchors.fill: parent; radius: 2 * s
                        color: "transparent"; border.color: root.amberHot; border.width: 1 * s
                        opacity: pm.containsMouse ? 1.0 : 0.30
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 1 * s; color: root.amberHot; radius: 1 * s
                            opacity: pm.containsMouse ? 0.15 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                    Text {
                        id: powerText; anchors.centerIn: parent
                        text: root.t(modelData.key); color: root.amberSoft
                        font.family: pfMed.name; font.pixelSize: 9 * s; font.letterSpacing: 1 * s
                    }
                    MouseArea {
                        id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (modelData.act === 0) sddm.reboot(); else sddm.powerOff() }
                    }
                }
            }
        }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            errorMessage.text = root.t("incorrectPassword")
            passwordField.text = ""; passwordField.focus = true; shakeAnim.start()
        }
    }
    function doLogin() {
        var uname = (userHelper.currentItem && userHelper.currentItem.uLogin)
                    ? userHelper.currentItem.uLogin : userModel.lastUser
        sddm.login(uname, passwordField.text, root.sessionIndex)
    }
}
