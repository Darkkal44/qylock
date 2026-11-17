import QtQuick
import QtTest
import "../package/contents/lockscreen"

TestCase {
    name: "NativeUserSwitch"

    QtObject {
        id: session
        property bool canSwitchUser: true
        property bool canLock: true
        property int calls: 0
        property bool clearedBeforeSwitch: false
        function switchUser() {
            clearedBeforeSwitch = authentication.password === "";
            calls++;
        }
    }
    QtObject {
        id: authentication
        property string password: ""
        function reset() { password = ""; }
    }
    UserSwitchBridge {
        id: bridge
        backend: session
        authentication: authentication
    }
    SignalSpy { id: switching; target: bridge; signalName: "switchingUser" }

    function init() {
        bridge.active = true;
        session.canSwitchUser = true;
        session.canLock = true;
        session.calls = 0;
        session.clearedBeforeSwitch = false;
        authentication.password = "unfinished-password";
        switching.clear();
    }

    function test_switch_clears_password_before_native_handoff() {
        verify(bridge.canSwitchUser);
        verify(bridge.switchUser());
        compare(session.calls, 1);
        verify(session.clearedBeforeSwitch);
        compare(switching.count, 1);
    }

    function test_unavailable_backend_cannot_switch_data() {
        return [
            { tag: "switching-disabled", switchAllowed: false, lockAllowed: true, active: true },
            { tag: "locking-disabled", switchAllowed: true, lockAllowed: false, active: true },
            { tag: "hidden-view", switchAllowed: true, lockAllowed: true, active: false }
        ];
    }
    function test_unavailable_backend_cannot_switch(data) {
        session.canSwitchUser = data.switchAllowed;
        session.canLock = data.lockAllowed;
        bridge.active = data.active;
        verify(!bridge.canSwitchUser);
        verify(!bridge.switchUser());
        compare(session.calls, 0);
        compare(switching.count, 0);
    }
}
