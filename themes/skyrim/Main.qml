pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel

Item {
    id: root
    width: 1920
    height: 1080
    readonly property real s: width / 1920   // UI scale relative to 1080p

    // ---- SDDM globals -----------------------------------------------------
    // sddm, userModel, sessionModel and keyboard are context properties that the
    // SDDM greeter injects at runtime, so the linter can't know them. They're only
    // read here; each is null when not running under SDDM (e.g. Quickshell).
    // qmllint disable unqualified
    readonly property var sddmApi: typeof sddm !== "undefined" ? sddm : null
    readonly property var users: typeof userModel !== "undefined" ? userModel : null
    readonly property var sessions: typeof sessionModel !== "undefined" ? sessionModel : null
    readonly property var keyboardApi: typeof keyboard !== "undefined" ? keyboard : null
    // qmllint enable unqualified

    readonly property bool isQuickshell: !sddmApi || sddmApi.hostName === undefined

    // Colors
    readonly property color textPrimary: "#fbfbfb"
    readonly property color textSecondary: "#5e5e5e"
    readonly property color accent: "#cde4ef"

    // ---- State ------------------------------------------------------------

    property int userIndex: (users && users.lastIndex >= 0) ? users.lastIndex : 0
    property int sessionIndex: (sessions && sessions.lastIndex >= 0) ? sessions.lastIndex : 0
    property bool loginError: false   // shows WRONG PASSWORD in the password row

    // Menu rows
    readonly property int selUser: 0
    readonly property int selPassword: 1
    readonly property int selSession: 2
    readonly property int selRestart: 3
    readonly property int selShutdown: 4

    // Selection: the highlighted row, and what Enter acts on. Set by hover,
    // click, typing, and by arrows/mouse wheel.
    property int selectedIndex: selUser
    // Scroll position: the row the menu is centered on (the biggest one).
    // Only arrows and the mouse wheel move it; hover never resizes anything.
    property int scrollIndex: selUser

    function selectionOrder() {
        return isQuickshell ? [selUser, selPassword, selRestart, selShutdown] : [selUser, selPassword, selSession, selRestart, selShutdown];
    }
    // Arrows / wheel: selection and scroll position each step one row on their
    // own, clamped at the ends, so after a hover they stay offset until one of
    // them hits an end and they line up again.
    function moveSelection(dir) {
        var order = selectionOrder();
        function step(idx) {
            var pos = Math.max(order.indexOf(idx), 0);
            return order[Math.min(Math.max(pos + dir, 0), order.length - 1)];
        }
        scrollIndex = step(scrollIndex);
        selectedIndex = step(selectedIndex);
    }
    function rowColor(idx) {
        return idx === selectedIndex ? textPrimary : textSecondary;
    }

    // ---- Actions ----------------------------------------------------------

    function login() {
        var n = (currentUser && currentUser.login !== "") ? currentUser.login : (users ? users.lastUser : "");
        if (sddmApi)
            sddmApi.login(n, passInput.text, sessionIndex);
    }
    function cycleUser() {
        if (users && users.count > 1)
            userIndex = (userIndex + 1) % users.count;
    }
    function cycleSession() {
        if (sessions && sessions.count > 1)
            sessionIndex = (sessionIndex + 1) % sessions.count;
    }
    // Click on a row, or Enter on the selected row
    function activate(idx) {
        switch (idx) {
        case selUser:
            cycleUser();
            break;
        case selSession:
            cycleSession();
            break;
        case selRestart:
            if (sddmApi)
                sddmApi.reboot();
            break;
        case selShutdown:
            if (sddmApi)
                sddmApi.powerOff();
            break;
        default:
            login();
        }
    }

    // ---- Menu layout ------------------------------------------------------
    // Rows shrink with their distance from the scroll position; spacing and row
    // boxes follow their size, and the centered row is pinned to a fixed Y.

    readonly property real menuFontSize: 36 * s
    readonly property real iconHeight: 47 * s              // selector arrow (currently disabled)
    readonly property real baseRowHeight: 34 * s
    readonly property real menuBottomMargin: 140 * s
    // Center-to-center spacing of two adjacent rows at full size; it shrinks
    // with them (see stepSpacingAt), so small rows pull closer together.
    readonly property real rowCenterSpacing: 52 * s
    // Extra row-box height: a fully shrunk row gains rowSpacingExtra, the
    // centered row gets selectedSpacingExtra.
    readonly property real rowSpacingExtra: 12 * s
    readonly property real selectedSpacingExtra: 18 * s
    // Extra shrink applied to every non-centered row.
    readonly property real unselectedFactor: 0.9
    // How far sizes / row heights are pulled apart around their average. >1
    // grows the centered row and shrinks the rest while the total stays the same.
    readonly property real sizeContrast: 1.15
    readonly property real marginContrast: 1.6
    // Smallest scale a row can reach, so far rows stay legible.
    readonly property real minScale: 0.55

    // Size before contrast: 1 for the centered row, halving every 4 rows away.
    function rawScaleFor(idx) {
        var order = selectionOrder();
        var pos = order.indexOf(idx);
        var selPos = order.indexOf(scrollIndex);
        if (pos === -1 || selPos === -1)
            return 1.0;
        var dist = Math.abs(pos - selPos);
        return dist === 0 ? 1.0 : Math.pow(0.5, dist / 4) * unselectedFactor;
    }
    function meanRawScale() {
        var order = selectionOrder();
        var sum = 0;
        for (var i = 0; i < order.length; i++)
            sum += rawScaleFor(order[i]);
        return sum / order.length;
    }
    function scaleFor(idx) {
        var mean = meanRawScale();
        return Math.max(mean + sizeContrast * (rawScaleFor(idx) - mean), minScale);
    }
    function rawRowHeightFor(idx) {
        if (idx === scrollIndex)
            return baseRowHeight + selectedSpacingExtra;
        return baseRowHeight + (1 - scaleFor(idx)) * rowSpacingExtra;
    }
    function meanRawRowHeight() {
        var order = selectionOrder();
        var sum = 0;
        for (var i = 0; i < order.length; i++)
            sum += rawRowHeightFor(order[i]);
        return sum / order.length;
    }
    function rowHeightFor(idx) {
        var mean = meanRawRowHeight();
        return mean + marginContrast * (rawRowHeightFor(idx) - mean);
    }
    // Fixed screen Y where the centered row's center sits.
    function topSlotCenterY() {
        return height - menuBottomMargin - baseRowHeight / 2 - (selectionOrder().length - 1) * rowCenterSpacing;
    }
    // Gap between list positions posA and posA+1, proportional to their average scale.
    function stepSpacingAt(posA) {
        var order = selectionOrder();
        return rowCenterSpacing * (scaleFor(order[posA]) + scaleFor(order[posA + 1])) / 2;
    }
    function menuRowCenterY(idx) {
        var order = selectionOrder();
        var pos = order.indexOf(idx);
        var selPos = order.indexOf(scrollIndex);
        if (pos === -1 || selPos === -1)
            return 0;
        var offset = 0;
        var i;
        for (i = selPos; i < pos; i++)
            offset += stepSpacingAt(i);
        for (i = pos; i < selPos; i++)
            offset -= stepSpacingAt(i);
        return topSlotCenterY() + offset;
    }
    function menuRowY(idx) {
        return menuRowCenterY(idx) - rowHeightFor(idx) / 2;
    }

    // ---- SDDM data --------------------------------------------------------

    // Loads the first font found in font/
    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }
    FontLoader {
        id: mainFont
        source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : ""
    }

    // Invisible views, used only to read the current user/session names
    // (SDDM's models can only be read through a view delegate).
    component UserEntry: Item {
        required property var model
        readonly property string displayName: model.realName || model.name || ""
        readonly property string login: model.name || ""
    }
    component SessionEntry: Item {
        required property var model
        readonly property string displayName: model.name || ""
    }
    ListView {
        id: userHelper
        model: root.users
        currentIndex: root.userIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: UserEntry {}
    }
    ListView {
        id: sessionHelper
        model: root.sessions
        currentIndex: root.sessionIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: SessionEntry {}
    }
    readonly property UserEntry currentUser: userHelper.currentItem as UserEntry
    readonly property SessionEntry currentSession: sessionHelper.currentItem as SessionEntry

    Connections {
        target: root.sddmApi
        function onLoginFailed() {
            root.loginError = true;
            wrongPasswordTimer.restart();
            passInput.text = "";
            errorShake.start();
            passInput.forceActiveFocus();
        }
    }
    // How long the password row reads WRONG PASSWORD after a failed login
    Timer {
        id: wrongPasswordTimer
        interval: 1000
        onTriggered: root.loginError = false
    }

    Component.onCompleted: if (keyboardApi)
        keyboardApi.numLock = true

    // ---- Keyboard ---------------------------------------------------------

    // Keep the password field focused; SDDM may activate the window late.
    Timer {
        interval: 300
        running: true
        onTriggered: passInput.forceActiveFocus()
    }
    readonly property bool windowActive: Window.active
    onWindowActiveChanged: if (windowActive)
        passInput.forceActiveFocus()

    // Fallback when the password field doesn't have focus: arrows and Enter
    // still navigate, and typed characters go to the password field.
    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Up) {
            root.moveSelection(-1);
        } else if (event.key === Qt.Key_Down) {
            root.moveSelection(1);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            // TextInput passes Enter on after firing onAccepted; don't act twice
            if (!passInput.activeFocus)
                root.activate(root.selectedIndex);
        } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            passInput.forceActiveFocus();
            passInput.insert(passInput.cursorPosition, event.text);
            root.selectedIndex = root.selPassword;
        } else {
            return;
        }
        event.accepted = true;
    }

    // ---- Mouse & cursor ---------------------------------------------------
    // The system cursor is hidden everywhere (every cursorShape is BlankCursor)
    // and assets/cursor.png is drawn at the pointer instead.

    // Wayland cursor fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.BlankCursor
        z: -1
    }
    // Wheel / touchpad scroll anywhere moves the menu like the arrow keys: one
    // notch (120 units) = one Up/Down press; small touchpad deltas accumulate.
    MouseArea {
        anchors.fill: parent
        z: 90000                        // above everything, so no item can swallow the wheel
        acceptedButtons: Qt.NoButton    // clicks and hover pass through to the items below
        cursorShape: Qt.BlankCursor     // topmost item, so it decides the cursor everywhere
        property real acc: 0
        onWheel: wheel => {
            acc += wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
            while (acc >= 120) {
                acc -= 120;
                root.moveSelection(-1);
            }
            while (acc <= -120) {
                acc += 120;
                root.moveSelection(1);
            }
            wheel.accepted = true;
        }
    }
    HoverHandler {
        id: pointer
        cursorShape: Qt.BlankCursor
    }
    Image {
        property real size: 63          // cursor size in px at 1080p (scales with the screen)
        property real hotX: 0.04        // tip position inside the image, fraction of its width
        property real hotY: 0.02        // tip position inside the image, fraction of its height

        source: "assets/cursor.png"
        width: size * root.s
        height: width
        sourceSize: Qt.size(width * 2, height * 2)
        smooth: true
        mipmap: true
        x: pointer.point.position.x - width * hotX
        y: pointer.point.position.y - height * hotY
        visible: pointer.hovered
        enabled: false                  // never intercepts clicks
        z: 100000
    }

    // ---- Background -------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: "black"
        z: -1000
    }
    // Logo, drawn over the smoke
    Image {
        id: logo

        // Placement as fractions of the screen (0 = left/top, 1 = right/bottom)
        property real sizeH: 0.70       // logo height relative to screen height (width follows aspect ratio)
        property real centerX: 0.36     // horizontal position of the logo's center (0.375 = middle of the 25-50% column)
        property real centerY: 0.48     // vertical position of the logo's center (0.5 = vertically centered)
        property real alpha: 1.0        // logo opacity (0 = invisible, 1 = fully opaque)

        source: "assets/logo.png"
        height: parent.height * sizeH
        width: sourceSize.height > 0 ? height * sourceSize.width / sourceSize.height : 0
        x: parent.width * centerX - width / 2
        y: parent.height * centerY - height / 2
        opacity: alpha
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        z: -400                         // -400 = in front of the smoke (-500); use -700 to put it behind
    }
    Smoke {
        anchors.fill: parent
        z: -500
    }
    // Darkens the bottom half behind the menu
    Rectangle {
        anchors.fill: parent
        z: -300
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#00000000"
            }
            GradientStop {
                position: 0.5
                color: "#00000000"
            }
            GradientStop {
                position: 1.0
                color: "#aa05080c"
            }
        }
    }

    // ---- Menu -------------------------------------------------------------

    // A text row: sized and placed by its distance from the scroll position,
    // highlighted when selected. Hover selects it, click activates it. The
    // hitbox is the text itself, so it follows the text's size.
    component MenuRow: Item {
        id: row
        required property int rowIndex
        property string label

        width: 320 * root.s
        height: root.rowHeightFor(rowIndex)
        y: root.menuRowY(rowIndex)

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            font.family: mainFont.name
            font.pixelSize: root.menuFontSize
            font.letterSpacing: 1.5 * root.s
            font.weight: Font.Normal
            color: root.rowColor(row.rowIndex)
            scale: root.scaleFor(row.rowIndex)
            transformOrigin: Item.Right
            layer.enabled: true
            layer.effect: DropShadow {
                color: "#90000000"
                radius: 10 * root.s
                samples: 17
                transparentBorder: true
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.BlankCursor
                onEntered: root.selectedIndex = row.rowIndex
                onClicked: root.activate(row.rowIndex)
            }
        }
    }

    Item {
        anchors.right: parent.right
        anchors.rightMargin: 110 * root.s
        width: 320 * root.s

        MenuRow {
            rowIndex: root.selUser
            label: (root.currentUser && root.currentUser.displayName ? root.currentUser.displayName : "UNKNOWN").toUpperCase()
        }

        // Password
        Item {
            width: 320 * root.s
            height: root.rowHeightFor(root.selPassword)
            y: root.menuRowY(root.selPassword)

            TextInput {
                id: passInput
                anchors.right: parent.right
                width: parent.width
                height: parent.height
                horizontalAlignment: TextInput.AlignRight
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "·"
                font.family: mainFont.name
                font.pixelSize: root.menuFontSize
                font.letterSpacing: 2 * root.s
                font.weight: Font.Normal
                color: "transparent"            // passwordDots below draws the characters
                clip: true
                focus: true
                scale: root.scaleFor(root.selPassword)
                transformOrigin: Item.Right
                cursorVisible: false
                cursorDelegate: Item {
                    width: 0
                    height: 0
                }
                selectionColor: root.accent
                onAccepted: root.activate(root.selectedIndex)
                onTextEdited: {
                    root.loginError = false;
                    wrongPasswordTimer.stop();
                    root.selectedIndex = root.selPassword;
                }
                Keys.onUpPressed: event => {
                    event.accepted = true;
                    root.moveSelection(-1);
                }
                Keys.onDownPressed: event => {
                    event.accepted = true;
                    root.moveSelection(1);
                }

                Text {
                    id: passPlaceholder
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.loginError ? "WRONG PASSWORD" : "PASSWORD"
                    font.family: mainFont.name
                    font.pixelSize: root.menuFontSize
                    font.letterSpacing: 1.5 * root.s
                    font.weight: Font.Normal
                    color: root.rowColor(root.selPassword)
                    visible: passInput.text.length === 0
                }

                // Hitbox = the PASSWORD label, or the typed dots
                MouseArea {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: passInput.text.length === 0 ? passPlaceholder.width : passwordDots.width
                    height: passPlaceholder.height
                    hoverEnabled: true
                    cursorShape: Qt.BlankCursor   // also hides TextInput's I-beam
                    onEntered: root.selectedIndex = root.selPassword
                    onClicked: {
                        passInput.forceActiveFocus();
                        root.selectedIndex = root.selPassword;
                    }
                }

                SequentialAnimation {
                    id: errorShake
                    NumberAnimation {
                        target: passInput
                        property: "x"
                        to: -10 * root.s
                        duration: 50
                    }
                    NumberAnimation {
                        target: passInput
                        property: "x"
                        to: 10 * root.s
                        duration: 50
                    }
                    NumberAnimation {
                        target: passInput
                        property: "x"
                        to: -10 * root.s
                        duration: 50
                    }
                    NumberAnimation {
                        target: passInput
                        property: "x"
                        to: 10 * root.s
                        duration: 50
                    }
                    NumberAnimation {
                        target: passInput
                        property: "x"
                        to: 0
                        duration: 50
                    }
                }
            }

            // One marker image per typed character
            Row {
                id: passwordDots
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                layoutDirection: Qt.RightToLeft
                spacing: 6 * root.s
                scale: root.scaleFor(root.selPassword)
                transformOrigin: Item.Right
                opacity: root.selectedIndex === root.selPassword ? 1.0 : 0.7
                Repeater {
                    model: passInput.text.length
                    delegate: Image {
                        source: "assets/marker.png"
                        height: root.menuFontSize * 0.4
                        width: height
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }
        }

        MenuRow {
            rowIndex: root.selSession
            visible: !root.isQuickshell
            height: root.isQuickshell ? 0 : root.rowHeightFor(root.selSession)
            label: (root.currentSession && root.currentSession.displayName ? root.currentSession.displayName : "DEFAULT").toUpperCase()
        }
        MenuRow {
            rowIndex: root.selRestart
            label: "RESTART"
        }
        MenuRow {
            rowIndex: root.selShutdown
            label: "SHUTDOWN"
        }

        // Selector arrow: always next to whichever row is selected. That row's
        // own center is always pinned to topSlotCenterY() (a plain constant),
        // so this can sit there directly with no Behavior — it never needs to
        // animate, it's just always in the right place.
        // Image {
        //     anchors.left: parent.right; anchors.leftMargin: 14 *root.s
        //     y: root.topSlotCenterY() - height / 2
        //     height: root.iconHeight; width: height * (291 / 308)
        //     fillMode: Image.PreserveAspectFit
        //     source: "assets/selector-left.png"
        // }
    }
}
