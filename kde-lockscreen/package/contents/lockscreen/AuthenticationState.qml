pragma Singleton
import QtQml

QtObject {
    // All monitor views share one native authenticator and one outstanding reply.
    property bool responsePending: false
    property bool successHandled: false
}
