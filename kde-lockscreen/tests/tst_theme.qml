import QtQuick
import QtTest

TestCase {
    id: test
    name: "ExistingThemeCompatibility"
    when: windowShown
    width: 1366
    height: 768
    property var config: ({ background: Qt.resolvedUrl("../../themes/nier-automata/bg.png") })
    property var sddm: sddmMock
    property var userModel: users
    property var sessionModel: sessions
    property var keyboard: keyboardMock

    QtObject { id: keyboardMock; property bool numLock: false }
    QtObject {
        id: sddmMock
        property string hostName: "test-host"
        signal loginFailed()
    }
    QtObject { id: quickshellMock; signal loginFailed() }
    ListModel {
        id: users
        property int lastIndex: 0
        ListElement { name: "test"; realName: "Test user" }
    }
    ListModel {
        id: sessions
        property int lastIndex: 0
        ListElement { name: "Plasma" }
    }
    Loader {
        id: theme
        anchors.fill: parent
        active: false
        source: "../../themes/nier-automata/Main.qml"
    }

    function cleanup() { theme.active = false; }
    function test_sddm() {
        sddm = sddmMock;
        keyboardMock.numLock = false;
        theme.active = true;
        compare(theme.status, Loader.Ready);
        verify(!theme.item.isKdeLock);
        verify(!theme.item.isQuickshell);
        verify(keyboardMock.numLock);
        verify(findChild(theme.item, "qylockPassword").enabled);
    }
    function test_quickshell() {
        sddm = quickshellMock;
        theme.active = true;
        compare(theme.status, Loader.Ready);
        verify(!theme.item.isKdeLock);
        verify(theme.item.isQuickshell);
        verify(findChild(theme.item, "qylockPassword").enabled);
    }
}
