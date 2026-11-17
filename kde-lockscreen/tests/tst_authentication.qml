import QtQuick
import QtTest
import "../package/contents/lockscreen"

TestCase {
    id: test
    name: "KdeAuthentication"
    when: windowShown

    QtObject {
        id: backend
        property bool unlocked: false
        property bool busy: false
        property bool inPasswordDelay: false
        property string prompt: ""
        property string promptForSecret: ""
        property string infoMessage: ""
        property string errorMessage: ""
        property int authenticator: 0
        property int starts: 0
        property int stops: 0
        property int responses: 0
        property string lastResponse: ""
        signal succeeded()
        signal failed(int kind)
        function startAuthenticating() { starts++; }
        function stopAuthenticating() { stops++; }
        function respond(password) { responses++; lastResponse = password; }
    }
    AuthenticationBridge { id: bridge; backend: backend }
    AuthenticationBridge { id: secondScreen; backend: backend; active: bridge.active }
    SignalSpy { id: authenticated; target: bridge; signalName: "authenticated" }
    SignalSpy { id: secondAuthenticated; target: secondScreen; signalName: "authenticated" }
    SignalSpy { id: cleared; target: bridge; signalName: "clearRequested" }
    SignalSpy { id: failed; target: bridge; signalName: "loginFailed" }

    function init() {
        bridge.active = false;
        bridge.message = "";
        bridge.capsLockOn = false;
        AuthenticationState.responsePending = false;
        AuthenticationState.successHandled = false;
        backend.unlocked = false;
        backend.busy = false;
        backend.inPasswordDelay = false;
        backend.prompt = "";
        backend.promptForSecret = "";
        backend.starts = 0; backend.stops = 0; backend.responses = 0;
        backend.lastResponse = "";
        backend.authenticator = 0;
        bridge.reset();
        bridge.awaitingPrompt = false;
        secondScreen.awaitingPrompt = false;
        authenticated.clear(); cleared.clear(); failed.clear();
        secondAuthenticated.clear();
        bridge.active = true;
    }
    function prompt() { backend.promptForSecret = "Password:"; }

    function test_waits_for_prompt() {
        bridge.login("ignored", "secret", 99);
        compare(backend.responses, 0);
        prompt();
        verify(bridge.canSubmit);
        bridge.login("other-user", "secret", 99);
        compare(backend.responses, 1);
        compare(backend.lastResponse, "secret");
        verify(!bridge.canSubmit);
        bridge.login("ignored", "duplicate", 0);
        compare(backend.responses, 1);
        verify(cleared.count > 0);
    }
    function test_password_label_is_hidden_but_notices_remain_available() {
        prompt();
        compare(bridge.statusText, "");
        backend.promptForSecret = "One-time code:";
        compare(bridge.statusText, "One-time code:");
        backend.inPasswordDelay = true;
        verify(bridge.statusText.includes("Please wait"));
        backend.inPasswordDelay = false;
        bridge.capsLockOn = true;
        verify(bridge.statusText.includes("Caps Lock"));
    }
    function test_delay_blocks_but_prompt_allows_native_busy_state() {
        prompt();
        backend.inPasswordDelay = true;
        bridge.login("", "secret", 0);
        compare(backend.responses, 0);
        backend.inPasswordDelay = false;
        // KDE's authentication heartbeat can set busy even at an open prompt.
        backend.busy = true;
        verify(bridge.canSubmit);
        bridge.login("", "secret", 0);
        compare(backend.responses, 1);
        verify(!bridge.canSubmit);
    }
    function test_failure_restarts_without_unlocking() {
        prompt();
        bridge.login("", "wrong", 0);
        const starts = backend.starts;
        backend.failed(0);
        compare(failed.count, 1);
        verify(backend.starts > starts);
        compare(authenticated.count, 0);
        verify(!bridge.canSubmit);
        // Repeated, identical prompts still arrive as signals from KDE.
        backend.promptForSecretChanged();
        verify(bridge.canSubmit);
    }
    function test_background_failure_keeps_prompt() {
        prompt();
        backend.failed(1);
        verify(bridge.canSubmit);
        compare(failed.count, 0);
    }
    function test_only_native_success_unlocks() {
        backend.succeeded();
        compare(authenticated.count, 0);
        compare(backend.stops, 0);
        backend.unlocked = true;
        backend.succeeded();
        compare(authenticated.count + secondAuthenticated.count, 1);
        compare(backend.stops, 1);
        verify(!bridge.canSubmit);
    }
    function test_visibility_clears_and_disables() {
        prompt();
        const count = cleared.count;
        bridge.active = false;
        verify(cleared.count > count);
        verify(!bridge.canSubmit);
        bridge.login("", "secret", 0);
        compare(backend.responses, 0);
        bridge.active = true;
        verify(bridge.canSubmit);
    }
    function test_monitor_views_share_submission_guard() {
        prompt();
        verify(secondScreen.canSubmit);
        bridge.login("", "secret", 0);
        secondScreen.login("", "duplicate", 0);
        compare(backend.responses, 1);
        verify(!secondScreen.canSubmit);
    }
    function test_method_change_and_followup_prompt() {
        prompt();
        backend.authenticator = 1;
        verify(!bridge.canSubmit);
        backend.prompt = "One-time code:";
        compare(bridge.promptLabel, "One-time code:");
        verify(bridge.canSubmit);
    }
}
