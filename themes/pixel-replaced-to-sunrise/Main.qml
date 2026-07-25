import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import SddmComponents 2.0

Rectangle {
    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }
    readonly property real s: Screen.height / 768
    id: root; width: Screen.width; height: Screen.height; color: "#16101a"
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0
    readonly property color latte: "#d2976b"
    readonly property color steel: "#5c7996"
    readonly property color textDim: "#a09088"

    // ---- Localization ----
    // Locale is read from theme.conf, key "Locale" in [General] (any letter casing),
    // e.g. "Locale=ru_RU". Falls back to "en" if missing/unsupported.
    readonly property var translations: ({
        "en": { password: "password...", login: "LOGIN", accessDenied: "ACCESS DENIED", session: "Session", restart: "RESTART", shutdown: "SHUT DOWN" },
        "ru": { password: "пароль...",   login: "ВХОД",  accessDenied: "ДОСТУП ЗАПРЕЩЁН",  session: "Сессия", restart: "ПЕРЕЗАГРУЗКА", shutdown: "ВЫКЛЮЧИТЬ" },
        "uk": { password: "пароль...",   login: "УВІЙТИ", accessDenied: "ДОСТУП ЗАБОРОНЕНО", session: "Сесія",  restart: "ПЕРЕЗАВАНТАЖИТИ", shutdown: "ВИМКНУТИ" },
        "de": { password: "passwort...", login: "ANMELDEN", accessDenied: "ZUGRIFF VERWEIGERT", session: "Sitzung", restart: "NEUSTART", shutdown: "AUSSCHALTEN" }
    })

    readonly property string configLocale: {
        if (typeof config === "undefined") return ""
        // Accept any casing of the "Locale" key (Locale, locale, LOCALE, ...)
        var keys = Object.keys(config)
        for (var i = 0; i < keys.length; i++) {
            if (keys[i].toLowerCase() === "locale" && config[keys[i]]) return config[keys[i]]
        }
        return ""
    }
    readonly property string lang: {
        var code = root.configLocale.length >= 2 ? root.configLocale.substring(0, 2).toLowerCase() : "en"
        return translations[code] ? code : "en"
    }
    // Full locale tag for Qt.locale(), e.g. "ru_RU". Falls back to "en_US".
    readonly property string localeTag: root.configLocale.length > 0 ? root.configLocale : "en_US"

    function t(key) { return root.translations[root.lang][key] }

    FolderListModel { id: fontFolder; folder: Qt.resolvedUrl("font"); nameFilters: ["*.ttf", "*.otf"] }
    FontLoader { id: pf; source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : "" }
    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" } }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Component.onCompleted: { fadeAnim.start(); keyboard.numLock = true }
    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 800; easing.type: Easing.OutCubic }

    Loader { anchors.fill: parent; source: "BackgroundVideo.qml" }

    // Top Overlay
    Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 160 * s; gradient: Gradient { GradientStop { position: 0.0; color: "#d8000000" } GradientStop { position: 1.0; color: "transparent" } } }
    // Bottom Overlay
    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 320 * s; gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#e8000000" } } }

    // Clock Section
    Column {
        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 60 * s; spacing: 4 * s; opacity: root.ui
        Row {
            spacing: 8 * s
            Rectangle { width: 4 * s; height: 4 * s; color: root.latte; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Qt.formatDate(new Date(), Qt.locale(root.localeTag), "dddd, MMMM d").toUpperCase(); color: root.steel; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; anchors.verticalCenter: parent.verticalCenter }
        }
        Text { id: clockText; text: Qt.formatTime(new Date(), "HH:mm"); color: "white"; font.family: pf.name; font.pixelSize: 76 * s; Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm") } }
    }

    // Login Section
    Item {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 60 * s; opacity: root.ui
        width: 320 * s; height: loginCol.implicitHeight
        
        Column {
            id: loginCol; width: parent.width; spacing: 18 * s
            Text { text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase(); color: "white"; font.family: pf.name; font.pixelSize: 22 * s; font.letterSpacing: 4 * s; anchors.horizontalCenter: parent.horizontalCenter
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (typeof userModel !== "undefined" && userModel.rowCount() > 0) root.userIndex = (root.userIndex + 1) % userModel.rowCount() } }
            }
            
            Item {
                width: parent.width; height: 36 * s
                Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; height: 1 * s; color: root.steel; opacity: pwd.activeFocus ? 1.0 : 0.3 }
                Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: pwd.activeFocus ? parent.width : 0; height: 2 * s; color: root.latte; Behavior on width { NumberAnimation {duration: 300; easing.type: Easing.OutExpo} } }
                TextInput {
                    id: pwd; anchors.fill: parent; color: root.latte; font.family: pf.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s
                    echoMode: TextInput.Password; onTextEdited: err.text = ""; passwordCharacter: "─"; focus: true; clip: true; horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                    cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                    selectionColor: root.latte
                    property bool wasClicked: false
                    onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false
                    Keys.onReturnPressed: doLogin(); Keys.onEnterPressed: doLogin()
                }
                Text { 
                    anchors.centerIn: parent; text: root.t("password"); color: root.textDim; font.family: pf.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s
                    opacity: pwd.text.length === 0 ? 0.5 : 0
                    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
                }
                Rectangle {
                    id: customCursor
                    width: 2 * s; height: 20 * s
                    color: root.latte
                    anchors.verticalCenter: parent.verticalCenter
                    x: pwd.cursorRectangle.x
                    visible: pwd.focus && (pwd.text.length > 0 || pwd.wasClicked)
                    SequentialAnimation {
                        loops: Animation.Infinite; running: customCursor.visible
                        NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                        NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pwd.forceActiveFocus()
                        pwd.wasClicked = true
                    }
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter; width: 140 * s; height: 36 * s
                Rectangle { anchors.fill: parent; color: sbm.containsMouse ? root.latte : "transparent"; border.color: root.latte; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                Text { anchors.centerIn: parent; text: root.t("login"); color: sbm.containsMouse ? "#000" : root.latte; font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
                MouseArea { id: sbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: doLogin() }
            }
            Text { id: err; text: ""; height: 12 * s; verticalAlignment: Text.AlignBottom; color: "#ff4444"; anchors.horizontalCenter: parent.horizontalCenter; font.family: pf.name; font.pixelSize: 10 * s }
        }
    }

    Row {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 40 * s; spacing: 20 * s; opacity: root.ui
        Repeater {
            model: [{l: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : root.t("session")).toUpperCase(), a: 2}, {l: root.t("restart"), a: 0}, {l: root.t("shutdown"), a: 1}]
            delegate: Item {
                visible: modelData.a === 2 ? !root.isQuickshell : true
                width: pmt.implicitWidth + 24 * s; height: 28 * s
                Rectangle { anchors.fill: parent; color: "transparent"; border.color: root.steel; border.width: 1 * s; opacity: pm.containsMouse ? 1.0 : 0.3; Behavior on opacity { NumberAnimation { duration: 150 } } Rectangle { anchors.fill: parent; anchors.margins: 1 * s; color: modelData.a === 2 ? root.latte : root.steel; radius: 2 * s; opacity: pm.containsMouse ? 0.3 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } } }
                Text { id: pmt; anchors.centerIn: parent; text: modelData.l; color: "white"; font.family: pf.name; font.pixelSize: 10 * s; font.letterSpacing: 2 * s }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.a === 0) { if (typeof sddm !== "undefined") sddm.reboot() } else if (modelData.a === 1) { if (typeof sddm !== "undefined") sddm.powerOff() } else if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() } }
            }
        }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() { err.text = root.t("accessDenied"); pwd.text = ""; pwd.focus = true }
    }
    
    function doLogin() { var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : ""); if (typeof sddm !== "undefined") sddm.login(u, pwd.text, root.sessionIndex) }
}
