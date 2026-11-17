# Native KDE Plasma lock screen

Experimental native KScreenLocker backend covering **all 42 theme variants** on
**Plasma 6.8**. It reuses the themes' QML and assets and submits authentication
responses to the authenticator supplied by KDE. Quickshell is not required.

Use `./install.sh` for a **system-wide** installation synchronized across user
profiles. It installs a shared package under `/usr/local/share/plasma/shells/`,
backs up older Qylock profile overlays, and migrates existing accounts
automatically. New profiles inherit it. The selected appearance is shared;
KScreenLocker still authenticates the owner of each locked session.

The `kde.sh install` commands below are advanced **per-profile overrides**. A
profile explicitly installed this way stays independent of the shared default.

## Use

Install `python3`, Plasma 6 with `kscreenlocker`, Qt 6 Quick Controls, Qt 6
5Compat, and the standard Plasma QML modules. On Arch, the Qt packages are
`qt6-declarative` and `qt6-5compat`; Plasma supplies the KDE imports. Other
distributions may split the QML modules into separate packages. Themes with video
backgrounds also require `qt6-multimedia` and its multimedia backend (on Arch,
`qt6-multimedia-ffmpeg`). Install `fzf` for the searchable theme picker; a numbered
picker is used when it is unavailable.

From the repository root:

```sh
# Detect the whole setup and install SDDM + KDE together when appropriate.
./install.sh

# Open the setup menu, like the SDDM and Quickshell setup scripts.
./kde.sh

# Choose and activate a theme directly.
./kde.sh select

# List supported themes, or include themes that still need a KDE port.
./kde.sh themes
./kde.sh themes --all

# Open the real KDE greeter in testing mode, without installing or locking.
./kde.sh preview

# Select a specific theme without interactive prompts.
./kde.sh preview --theme material-you
./kde.sh install --theme clockwork/tape

./kde.sh status

# Trigger KDE's real lock screen, using the installed theme.
./kde.sh lock

# Check settings and shortcuts when the theme does not appear.
./kde.sh doctor

# Remove a profile override and return to the shared/default lock screen.
./kde.sh uninstall

# Remove the shared package and restore backed-up profile installations.
sudo python3 scripts/system-lock.py uninstall --backend kde
```

Preview uses KDE's real authentication backend. Close the preview window to end
it; a successful authentication also closes it. Normal locking continues through
KDE's existing shortcut, menu, idle timeout, and suspend integration.

If locking returns straight to the desktop, run `./kde.sh doctor`. Check that
**Require password** is enabled in KDE's Screen Locking settings. A `Meta+L`
shortcut still bound to the old Quickshell `qylock` command bypasses this native
backend. Bind it to KDE's **Lock Session** action or the absolute path to
`kde-lockscreen/lock.sh`. That small launcher can also replace the old
`~/.local/bin/qylock` symlink if an existing application shortcut runs `qylock`.
The setup CLI (`kde.sh` without a subcommand) opens a menu; it does not lock.

`kde.sh lock` calls KDE's D-Bus `ScreenSaver.Lock` method to request an immediate
lock. It does not start Quickshell or run a testing-mode greeter. KDE must be
running with its screen-locking service available.

`preview` and `install` open the theme picker when `--theme` is omitted in a
terminal. In scripts, they reuse the installed theme, or default to
`nier-automata` when none is installed. Cancelling a picker makes no changes.
Re-run `install` after theme or `theme.conf` changes; the installed theme is a
snapshot. Optional fonts are copied from the selected theme's `font/` directory.

Supported theme IDs:

| Theme | ID |
|---|---|
| Genshin | `Genshin` |
| Reverse: 1999 / Variant 1 | `R1999_1` |
| Reverse: 1999 / Variant 2 | `R1999_2` |
| Clockwork / Neo Orbital | `clockwork/neo-orbital` |
| Clockwork / Orbital | `clockwork/orbital` |
| Clockwork / Tape | `clockwork/tape` |
| Dog Samurai | `dog-samurai` |
| Enfield | `enfield` |
| Field | `field` |
| Forest | `forest` |
| Girl Coffee | `girl-coffee` |
| Girl Pillow | `girl-pillow` |
| The Last of Us | `last-of-us` |
| Man Bicycle | `man-bicycle` |
| Material You | `material-you` |
| Material You Dark | `material-you-dark` |
| Minecraft | `minecraft` |
| NieR: Automata | `nier-automata` |
| Nine Sols | `ninesols` |
| Ninja Gaiden | `ninja_gaiden` |
| Nothing | `nothing` |
| osu! | `osu` |
| osu!mania | `osumania` |
| Pixel / Coffee | `pixel-coffee` |
| Pixel / Cyberpunk | `pixel-cyberpunk` |
| Pixel / Dusk City | `pixel-dusk-city` |
| Pixel / Emerald | `pixel-emerald` |
| Pixel / Hollow Knight | `pixel-hollowknight` |
| Pixel / Munchlax | `pixel-munchlax` |
| Pixel / Night City | `pixel-night-city` |
| Pixel / Rainy Room | `pixel-rainyroom` |
| Pixel / Sakura | `pixel-sakura` |
| Pixel / Skyscrapers | `pixel-skyscrapers` |
| Pixel / Waterfall | `pixel-waterfall` |
| Skyrim | `skyrim` |
| Honkai: Star Rail | `star-rail` |
| Sword | `sword` |
| Terraria | `terraria` |
| Windows 7 | `windows_7` |
| Winter | `winter` |
| Women Umbrella | `women-umbrella` |
| Wuthering Waves | `wuwa` |

## Packaging

The standalone `kde.sh` installer creates a user-level overlay at
`$XDG_DATA_HOME/plasma/shells/org.kde.plasma.desktop/` (normally
`~/.local/share/plasma/shells/org.kde.plasma.desktop/`). Its lock screen is supplied
by Qylock. The remaining shell components are copied from the distribution's
system package. They are deliberately not symlinked: KPackage refuses package
files that resolve outside the package root, which prevents Plasma's shutdown
dialog (`ksmserver-logout-greeter`) from loading `contents/logout` and makes the
Shutdown/Restart/Logout actions stop responding. The installer refuses to
overwrite an unrelated existing overlay or a symlink at that location.

Because the overlay is a snapshot, reinstall the theme after a Plasma upgrade so
its copied components match the running Plasma version. `./kde.sh doctor` reports
an overlay that links outside its package or was built from an older system shell.

Installation is staged before activation; an unsuccessful activation restores the
previous Qylock overlay. Uninstall removes only a marked Qylock overlay. It does
not modify SDDM, Quickshell, PAM, KWin, or KDE's lock shortcuts. A running lock
screen is not changed by installation or removal.

This is an overlay for the standard Plasma desktop shell, not a standalone theme
package selectable in System Settings. Other shell packages are not supported.
The native lock UI uses private Plasma APIs: after a Plasma upgrade, rebuild the
overlay (`./kde.sh install --theme NAME`, or `sudo ./install.sh` for the shared
package) so its copied shell components match the running Plasma version, then
preview the theme again and update or uninstall it if needed. Automatic detection
checks for the expected shell and authentication entry points; it is not a
guarantee of compatibility with every Plasma version.

For a custom distribution data directory, specify the system package explicitly:

```sh
./kde.sh --system-shell /usr/share/plasma/shells/org.kde.plasma.desktop preview
```

To inspect a package without activation:

```sh
./kde.sh build --output /tmp/qylock-kde-package
```

The output must be missing or empty. No root access is needed. If the theme fails
to load, the host loads the system lock UI. If the host itself fails to load,
KScreenLocker retains its own built-in fallback.

## Authentication and controls

KDE owns authentication, retry delays, and the actual unlock decision. The QML
adapter passes responses directly to KDE without retaining a pending password.
It clears the theme's password fields on submission, hide, suspend, method change,
failure, and success. All monitor views share a submission guard to prevent the
same Enter key from submitting more than once.

The theme fills the entire screen without an extra KDE footer. Authentication
messages, additional prompts, and Caps Lock status use the theme's existing
message area; the ordinary KDE "Password:" prompt is not duplicated.

Press **F10** or **right-click** to open the hidden **Lock options** menu for KDE's
authentication methods, keyboard layout controls, virtual keyboard toggle, Sleep,
and Switch User. Press Escape or click outside to close it and return to the
theme's password field. The menu reserves no space when closed.

Click the theme's **username selector** (or its **Switch User** button) to open
KDE's account chooser. You can also Tab to the selector and press Enter or Space.
The selector is disabled when KDE does not allow user switching. Password fields
are cleared before the handoff, and the current session stays locked. Choose and
authenticate the other account in the display manager. The lock screen continues
to display the account that owns its session until that handoff.
The handoff uses KDE's native
[`SessionManagement.switchUser()`](https://github.com/KDE/plasma-workspace/blob/v6.8.2/libkworkspace/sessionmanagement.cpp#L253).

Themes use their lock mode where available.
Theme power, reboot, and sleep buttons delegate to KDE's session-management API.
Additional PAM prompts use the same password response field and the theme's
existing masking. Authentication methods still depend on your system's KDE/PAM
configuration.

## Add another theme

The picker discovers theme directories recursively and exposes the ports registered
in [themes.json](themes.json). Add an entry using the directory name and the ID of
its password `TextInput`, for example:

```json
"pixel-waterfall": {"name": "Pixel / Waterfall", "passwordId": "pwd", "messageTarget": "err.text", "userSwitchAction": "root.userIndex ="}
```

`messageTarget` names the existing message text, such as `err.text` or a root
string property such as `root.errorMessage`. For a text item whose opacity is
normally zero, `messageOpacity` can name that same item to reveal its messages.
`userSwitchAction` identifies a unique statement in the username selector's
`MouseArea.onClicked` handler. The build replaces that handler with KDE user
switching and adds keyboard access, a focus indicator, and accessible semantics.
If the action is missing or ambiguous, the build requires the port to be reviewed.

Themes without an existing message label use `inlineStatus: true` to place a
status label directly below their password field. `passwordFocus` can reveal a
login panel before focusing the field. Reviewed, exact `replacements` handle
special menu functions; each source fragment must match once. A shared menu-row
delegate can use `userSwitchCondition` so only its user row triggers switching.

`configOverrides` supplies KDE-only settings. The osu! and osu!mania lock ports
use `gameMode: menu` for direct password submission. Their original SDDM settings
and game modes are preserved. Genshin reveals its password panel on prompt
readiness. Skyrim, Dog Samurai, and Terraria gain inline authentication notices.

The shared adapter adds password clearing, native prompt readiness, inline
messages, focus, and keyboard navigation to the **built copy**. The source theme is preserved. Themes
must have `Main.qml` with `id: root` and a `theme.conf` or theme metadata.
Missing configuration or an absent `[General]` section means empty settings.
Themes need an `import SddmComponents 2.0` (or a reviewed `sddmImport: false`
port) and an existing `sddm.login(...)` call. The build checks that the registered
password field still exists and rejects mismatches.

Review the theme's session actions, scale calculations, additional QML imports,
and any custom password or login logic before registering it. Themes with their
own `clearPassword()` or `focusPassword()` functions need their hooks reviewed
instead of injecting duplicate functions. `nativeHooks: true` is reserved for
themes that already implement the full KDE adapter contract, such as NieR.

Validate the new port before keeping its registry entry:

```sh
./kde.sh build --theme pixel-waterfall --output /tmp/qylock-waterfall-package
dbus-run-session -- python3 kde-lockscreen/tests/check_native.py \
    --theme pixel-waterfall --output /tmp/qylock-waterfall-check
./kde.sh preview --theme pixel-waterfall
```

The native checks verify rendering, prompt readiness, field enabling, password
clearing, username actions through pointer/keyboard/accessibility events with a
mock session backend, three resolutions, and fallback. Interactive preview is still needed
to check the theme's controls and actual authentication. Merely adding a registry
entry does not establish compatibility.

## Validation

```sh
python3 -m unittest discover -s kde-lockscreen/tests -p 'test_*.py' -v
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    /usr/lib/qt6/bin/qmltestrunner -input kde-lockscreen/tests \
    -import quickshell-lockscreen/imports -o -,txt

# Runs actual KScreenLocker testing mode with a private D-Bus session.
# Captures three resolutions and a deliberately broken theme's fallback.
# It does not submit credentials or lock the session.
dbus-run-session -- python3 kde-lockscreen/tests/check_native.py \
    --output /tmp/qylock-kde-native-check

# Render every registered port and check password submission and user controls.
dbus-run-session -- python3 kde-lockscreen/tests/check_native.py \
    --all-themes --all-resolutions --renderer opengl \
    --output /tmp/qylock-kde-all-themes
```

Video backgrounds need the OpenGL check; the software renderer can show an empty
video surface. Test configuration and caches stay under the output directory.

Native smoke checks require a working PAM worker and permission to create local
D-Bus sockets. Use a new or empty output directory for each run. The automated
checks cover the adapter, packaging, rendering, and fallback. Real password
authentication, fingerprint hardware, multiple physical outputs, compositor
scaling, and suspend/resume still need interactive validation before treating
this backend as production-ready.

The implementation follows the installed Plasma 6.8 lock UI and KDE's
[KScreenLocker greeter](https://invent.kde.org/plasma/kscreenlocker/-/tree/Plasma/6.8/greeter).
