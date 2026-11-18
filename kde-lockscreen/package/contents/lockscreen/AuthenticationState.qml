pragma Singleton
import QtQml

QtObject {
    // All monitor views share one native authenticator and one outstanding reply.
    property bool responsePending: false
    // KDE emits each prompt once. Views created later (e.g. outputs re-added on
    // resume from sleep) must still know that the authenticator is waiting.
    property bool awaitingPrompt: false
    property string promptLabel: ""
    property bool successHandled: false
}
