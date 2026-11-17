#!/usr/bin/env bash
# One entry point for login-screen and session-lock installation.
set -euo pipefail

INSTALLER_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$INSTALLER_DIR/scripts/themes.sh"

usage() {
    cat <<'EOF'
Usage: ./install.sh [--login auto|sddm|none] [--lock auto|kde|quickshell|none]
                    [--theme NAME | --separate-themes] [--qt5]
                    [--detect | --dry-run]

Detect the login manager and desktop separately, then run the selected setup
scripts. With no options, a terminal menu lets you accept or change each choice.
Choose one shared theme for all selected components by default.
Install it system-wide and synchronize existing user profiles automatically.

  --login BACKEND  Login-screen backend (default: auto)
  --lock BACKEND   Session-lock backend (default: auto)
  --theme NAME     Apply this theme to all selected components
  --separate-themes  Choose login and lock themes independently
  --qt5           Use the legacy Qt5 SDDM backend (default: Qt6)
  --detect        Show detection and recommendations without making changes
  --dry-run       Show the selected installers without running them
  -h, --help      Show this help

Examples:
  ./install.sh                               # Detect and choose components
  ./install.sh --detect                      # Inspect this system
  ./install.sh --login sddm --lock kde        # SDDM login + KDE lock
  ./install.sh --login none --lock quickshell # Only Quickshell setup

Theme variants appear in the shared picker, including clockwork/tape.
Installation uses the selected theme's existing theme.conf settings.
Install dependencies with your distribution's package manager first.
EOF
}

detect_display_manager() {
    local root="${1:-/}" service manager
    service="$root/etc/systemd/system/display-manager.service"
    if [[ -L "$service" ]]; then
        manager="$(readlink -- "$service")"
        manager="${manager##*/}"
        manager="${manager%.service}"
        [[ "$manager" != null ]] || manager=unknown
    elif [[ -r "$root/etc/X11/default-display-manager" ]]; then
        IFS= read -r manager < "$root/etc/X11/default-display-manager" || true
        manager="${manager##*/}"
    else
        manager=unknown
    fi
    printf '%s\n' "${manager:-unknown}"
}

detect_session() {
    local desktops token hints_present=false
    local -a tokens
    # Prefer the current desktop over session/login hints left by another WM.
    for desktops in "${XDG_CURRENT_DESKTOP:-}" "${XDG_SESSION_DESKTOP:-}" "${DESKTOP_SESSION:-}"; do
        [[ -z "$desktops" ]] || hints_present=true
        desktops="${desktops,,}"
        desktops="${desktops//;/:}"
        desktops="${desktops// /:}"
        IFS=: read -r -a tokens <<< "$desktops"
        for token in "${tokens[@]}"; do
            case "$token" in
                kde|plasma|plasmawayland|plasmax11|plasma-wayland|plasma-x11) printf 'kde\n'; return ;;
                gnome|gnome-*|ubuntu|cinnamon|x-cinnamon|xfce|xfce4|mate)
                    printf 'unsupported\n'; return ;;
                hyprland|sway) printf '%s\n' "$token"; return ;;
            esac
        done
    done
    if [[ "$hints_present" == true ]]; then
        printf 'unknown\n'
    elif [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        printf 'hyprland\n'
    elif [[ -n "${SWAYSOCK:-}" ]]; then
        printf 'sway\n'
    else
        printf 'unknown\n'
    fi
}

recommend_lock() {
    case "$1" in
        kde) printf 'kde\n' ;;
        hyprland|sway)
            if [[ "${XDG_SESSION_TYPE:-wayland}" == wayland ]]; then
                printf 'quickshell\n'
            else
                printf 'none\n'
            fi
            ;;
        *) printf 'none\n' ;;
    esac
}

interactive() { [[ -t 0 && -t 1 ]]; }

choose_backend() {
    local label="$1" choices="$2" default="$3" answer backend
    local -a allowed
    IFS=/ read -r -a allowed <<< "$choices"
    while true; do
        read -r -p "$label [$choices] (Enter = $default, q = cancel): " answer || return 130
        answer="${answer:-$default}"
        case "$answer" in q|Q) return 130 ;; esac
        for backend in "${allowed[@]}"; do
            if [[ "$answer" == "$backend" ]]; then
                SELECTED_BACKEND="$answer"
                return 0
            fi
        done
        printf 'Choose one of: %s\n' "$choices"
    done
}

theme_catalog() {
    if [[ "$1" == kde ]]; then
        python3 -c 'import json, pathlib, sys
root = pathlib.Path(sys.argv[2])
for theme in sorted(json.load(open(sys.argv[1]))):
    path = root / theme
    if (path / "Main.qml").is_file() and ((path / "theme.conf").is_file() or (path / "metadata.desktop").is_file()):
        print(theme)' "$INSTALLER_DIR/kde-lockscreen/themes.json" "$INSTALLER_DIR/themes"
    else
        qylock_themes "$INSTALLER_DIR/themes"
    fi
}

choose_theme() {
    local label="$1" backend="$2" catalog selected default=nier-automata index result
    local -a choices
    catalog="$(theme_catalog "$backend")" || return 1
    if [[ -z "$catalog" ]]; then
        printf 'No compatible themes found for %s.\n' "$label" >&2
        return 1
    fi
    mapfile -t choices <<< "$catalog"
    if [[ $'\n'"$catalog"$'\n' != *$'\n'"$default"$'\n'* ]]; then default="${choices[0]}"; fi
    printf '\n%s\n' "$label"
    if command -v fzf > /dev/null; then
        result=0
        selected="$(printf '%s\n' "${choices[@]}" | fzf --prompt='Theme: ' --height=70% --reverse --border \
            --header="$label • Esc cancels")" || result=$?
        case "$result" in 0) ;; 1|130) return 130 ;; *) return "$result" ;; esac
    else
        for index in "${!choices[@]}"; do printf '  %2d. %s\n' "$((index + 1))" "${choices[index]}"; done
        while true; do
            read -r -p "Theme number or ID (Enter = $default, q = cancel): " selected || return 130
            case "$selected" in q|Q) return 130 ;; esac
            selected="${selected:-$default}"
            for index in "${!choices[@]}"; do
                if [[ "$selected" == "$((index + 1))" || "$selected" == "${choices[index]}" ]]; then
                    SELECTED_THEME="${choices[index]}"
                    return 0
                fi
            done
            printf 'Choose a listed theme number or ID.\n'
        done
    fi
    for index in "${choices[@]}"; do
        if [[ "$selected" == "$index" ]]; then SELECTED_THEME="$selected"; return 0; fi
    done
    printf 'Theme picker returned an unknown selection.\n' >&2
    return 1
}

validate_theme() {
    local theme="$1" backend="$2" catalog
    if ! qylock_theme_exists "$INSTALLER_DIR/themes" "$theme"; then
        printf 'Unknown theme: %s\n' "$theme" >&2
        return 2
    fi
    if [[ "$backend" == kde ]]; then
        catalog="$(theme_catalog kde)" || return 1
        if [[ $'\n'"$catalog"$'\n' != *$'\n'"$theme"$'\n'* ]]; then
            printf 'Theme has no KDE port: %s\n' "$theme" >&2
            return 2
        fi
    fi
}

preflight() {
    local login="$1" lock="$2" missing=0 script
    local -a scripts=()
    [[ "$login" != sddm ]] || scripts+=(sddm.sh)
    [[ "$lock" == none ]] || scripts+=(scripts/system-lock.py)
    case "$lock" in
        kde) scripts+=(kde.sh kde-lockscreen/manage.py kde-lockscreen/themes.json) ;;
        quickshell) scripts+=(quickshell.sh) ;;
    esac
    for script in "${scripts[@]}"; do
        if [[ ! -f "$INSTALLER_DIR/$script" ]]; then
            printf 'Missing %s: run install.sh from a complete Qylock checkout.\n' "$script" >&2
            missing=1
        fi
    done
    [[ "$missing" == 0 ]] || return 1
    if [[ "$login" == sddm ]]; then
        if ! command -v sddm > /dev/null; then
            printf 'Missing SDDM: install your distribution\x27s sddm package.\n' >&2
            missing=1
        fi
    fi
    if [[ "$login" != none || "$lock" != none ]] && ! command -v sudo > /dev/null; then
        printf 'Missing sudo: system-wide theme installation requires it.\n' >&2
        missing=1
    fi
    if [[ "$lock" != none ]] && ! command -v python3 > /dev/null; then
        printf 'Missing Python 3: install python3 for system-wide lock setup.\n' >&2
        missing=1
    fi
    if [[ "$lock" == kde ]]; then
        if ! command -v python3 > /dev/null; then
            printf 'Missing Python 3: install python3 for KDE setup.\n' >&2
            missing=1
        elif ! python3 -c 'import runpy, sys; m = runpy.run_path(sys.argv[1]); m["system_shell"](); m["greeter"]()' \
                "$INSTALLER_DIR/kde-lockscreen/manage.py"; then
            printf 'KDE setup requires a compatible Plasma shell and kscreenlocker. See kde-lockscreen/README.md.\n' >&2
            missing=1
        fi
    elif [[ "$lock" == quickshell ]] && ! command -v quickshell > /dev/null; then
        printf 'Missing Quickshell: install it and the Qt dependencies listed in README.md.\n' >&2
        missing=1
    fi
    [[ "$missing" == 0 ]]
}

main() {
    local login=auto lock=auto mode=install manager session login_default=none lock_default
    local theme="" separate=false qt5=false login_theme="" lock_theme=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --login|--lock)
                if [[ $# -lt 2 ]]; then
                    printf 'Missing value for %s. See --help.\n' "$1" >&2
                    return 2
                fi
                if [[ "$1" == --login ]]; then login="$2"; else lock="$2"; fi
                shift 2 ;;
            --theme)
                [[ $# -ge 2 && -n "$2" ]] || { printf 'Missing value for --theme.\n' >&2; return 2; }
                theme="$2"; shift 2 ;;
            --separate-themes) separate=true; shift ;;
            --qt5) qt5=true; shift ;;
            --detect) mode=detect; shift ;;
            --dry-run) mode=dry-run; shift ;;
            -h|--help) usage; return ;;
            *) printf 'Unknown option: %s. See --help.\n' "$1" >&2; return 2 ;;
        esac
    done
    case "$login" in auto|sddm|none) ;; *) printf 'Invalid login backend: %s\n' "$login" >&2; return 2 ;; esac
    case "$lock" in auto|kde|quickshell|none) ;; *) printf 'Invalid lock backend: %s\n' "$lock" >&2; return 2 ;; esac
    if [[ -n "$theme" && "$separate" == true ]]; then
        printf 'Use either --theme or --separate-themes.\n' >&2
        return 2
    fi

    manager="$(detect_display_manager)"
    session="$(detect_session)"
    [[ "$manager" != sddm ]] || login_default=sddm
    lock_default="$(recommend_lock "$session")"
    printf '\nQylock setup\nDisplay manager: %s\nDesktop session: %s (%s)\n' \
        "$manager" "${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-$session}}}" "${XDG_SESSION_TYPE:-unknown}"
    printf 'Recommended login: %s\nRecommended lock: %s\n' "$login_default" "$lock_default"
    if [[ "$manager" != sddm ]]; then
        printf 'No active SDDM installation detected; login theming defaults to none.\n'
    fi
    if [[ "$lock_default" == none ]]; then
        printf 'No supported session-lock backend detected; keep your current locker.\n'
        printf 'Quickshell needs a Wayland compositor with ext-session-lock-v1 support.\n'
    fi
    [[ "$mode" != detect ]] || return 0

    if [[ "$mode" == install ]]; then
        if ! interactive; then
            printf 'Setup needs a terminal for theme selection. Use --detect or --dry-run to inspect the plan.\n' >&2
            return 2
        fi
        if [[ "$login" == auto ]]; then
            choose_backend 'Login theme' 'sddm/none' "$login_default" || return "$?"
            login="$SELECTED_BACKEND"
        fi
        if [[ "$lock" == auto ]]; then
            choose_backend 'Lock screen' 'kde/quickshell/none' "$lock_default" || return "$?"
            lock="$SELECTED_BACKEND"
        fi
    else
        [[ "$login" != auto ]] || login="$login_default"
        [[ "$lock" != auto ]] || lock="$lock_default"
    fi

    # Plasma has its own native backend; the Quickshell lock protocol is not a
    # replacement for KScreenLocker. Reject this known mismatch before changes.
    if [[ "$session" == kde && "$lock" == quickshell ]]; then
        printf 'Use --lock kde on Plasma, or --lock none to keep its existing lock screen.\n' >&2
        return 2
    fi
    if [[ "$lock" == quickshell && ( "$session" == unsupported || "${XDG_SESSION_TYPE:-}" == x11 ) ]]; then
        printf 'Quickshell locking requires a compatible Wayland session. Use --lock none to keep your current locker.\n' >&2
        return 2
    fi
    printf '\nSelected login: %s\nSelected lock: %s\n' "$login" "$lock"
    if [[ "$login" == none && "$lock" == none ]]; then
        printf 'No components selected. Nothing changed.\n'
        return 0
    fi
    printf 'Scope: system-wide; existing profiles sync automatically and new profiles inherit it.\n'
    if [[ "$mode" == install ]]; then preflight "$login" "$lock" || return 1; fi
    if [[ "$separate" == true ]]; then
        if [[ "$mode" == install ]]; then
            if [[ "$login" != none ]]; then
                choose_theme 'Login-screen theme' sddm || return "$?"
                login_theme="$SELECTED_THEME"
            fi
            if [[ "$lock" != none ]]; then
                choose_theme 'Lock-screen theme' "$lock" || return "$?"
                lock_theme="$SELECTED_THEME"
            fi
        else
            login_theme='<choose login theme>'
            lock_theme='<choose lock theme>'
        fi
    else
        if [[ -z "$theme" && "$mode" == install ]]; then
            choose_theme 'Shared login and lock theme' "$lock" || return "$?"
            theme="$SELECTED_THEME"
        fi
        if [[ -n "$theme" ]]; then validate_theme "$theme" "$lock" || return "$?"; fi
        login_theme="${theme:-<choose once>}"
        lock_theme="$login_theme"
    fi
    local -a sddm_args=(--theme "$login_theme")
    [[ "$qt5" == false ]] || sddm_args+=(--qt5)
    if [[ "$login" == sddm ]]; then
        printf 'Run: ./sddm.sh --theme %s' "$login_theme"
        if [[ "$qt5" == true ]]; then printf ' --qt5'; fi
        printf '\n'
    fi
    case "$lock" in
        kde|quickshell) printf 'Prepare and install system-wide %s theme: %s\n' "$lock" "$lock_theme" ;;
    esac
    [[ "$mode" != dry-run ]] || return 0

    local -a completed=()
    local result=0
    local package=""
    if [[ "$lock" != none ]]; then
        package="$(mktemp -d -t qylock-system-package-XXXXXXXX)" || return 1
        python3 "$INSTALLER_DIR/scripts/system-lock.py" prepare \
            --backend "$lock" --theme "$lock_theme" --output "$package" || result=$?
        if [[ "$result" != 0 ]]; then
            rm -rf -- "$package"
            printf 'Lock theme could not be prepared. No installation was started.\n' >&2
            return "$result"
        fi
    fi
    if [[ "$login" == sddm ]]; then
        bash "$INSTALLER_DIR/sddm.sh" "${sddm_args[@]}" || result=$?
        if [[ "$result" != 0 ]]; then
            if [[ -n "$package" ]]; then rm -rf -- "$package"; fi
            printf 'SDDM setup stopped (exit %s). Lock-screen setup was not started.\n' "$result" >&2
            return "$result"
        fi
        completed+=(sddm)
    fi
    if [[ "$lock" != none ]]; then
        sudo python3 "$INSTALLER_DIR/scripts/system-lock.py" apply --package "$package" \
            --profile-data-home "${XDG_DATA_HOME:-$HOME/.local/share}" \
            --profile-state-home "${XDG_STATE_HOME:-$HOME/.local/state}" || result=$?
        rm -rf -- "$package"
        if [[ "$result" != 0 ]]; then
            printf '%s setup stopped (exit %s). Completed installers: %s.\n' \
                "$lock" "$result" "${completed[*]:-none}" >&2
            return "$result"
        fi
        completed+=("$lock")
    fi
    printf '\nFinished setup scripts: %s.\n' "${completed[*]}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
