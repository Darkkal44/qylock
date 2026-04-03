import os
import re

TEXT_RE = re.compile(r'McText { label: "Username"; pixelSize: 13 \* s }')
TEXT_PW_RE = re.compile(r'McText { label: "Password"; pixelSize: 13 \* s }')

FIELD_RE = re.compile(r'McTextField {\s*id: userField; width: parent\.width; height: 36 \* s\s*TextInput {\s*id: userInput; anchors\.fill: parent; anchors\.margins: 6 \* s\s*text: userModel\.lastUser; color: "white"; font\.family: mcFont\.name; font\.pixelSize: 14 \* s\s*verticalAlignment: TextInput\.AlignVCenter; clip: true\s*KeyNavigation\.tab: passInput\s*}\s*}', re.DOTALL)

def patch_file(path):
    with open(path, 'r') as f:
        content = f.read()

    # 1. Add userHelper at top (Bridge Pattern)
    if 'id: userHelper' not in content:
        content = content.replace('id: root', 'id: root\n    property int userIndex: (userModel && userModel.lastIndex >= 0) ? userModel.lastIndex : 0')
        content = content.replace('id: sessionHelper', 'id: userHelper\n    ListView {\n        id: userHelper\n        model: userModel; currentIndex: root.userIndex\n        opacity: 0; width: 0; height: 0; z: -100; visible: true\n        delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || "" }\n    }\n    \n    ListView {\n        id: sessionHelper')

    # 2. Update Username label and field for clicking
    # Larger font for labels (16s)
    content = content.replace('McText { label: "Username"; pixelSize: 13 * s }', 'McText {\n                    label: "Username"; pixelSize: 15 * s\n                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.userIndex = (root.userIndex + 1) % userModel.rowCount() }\n                }')
    content = content.replace('McText { label: "Password"; pixelSize: 13 * s }', 'McText { label: "Password"; pixelSize: 15 * s }')

    # 3. Bind userInput.text to userHelper and handle clicking the field
    # Also ensure password input uses the same style.
    
    # Actually, I'll just write the whole block again to be safe.
    
    with open(path, 'w') as f:
        f.write(content)

# Patching Main.qml
# ...
