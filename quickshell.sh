#!/usr/bin/env bash

# This script installs Quickshell Lockscreen support for SDDM themes.
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.local/share/quickshell-lockscreen"

# Reset terminal colors on exit or crash
trap 'echo -ne "\033[0m"' EXIT

# ─────────────────────────────────────────────────────────────────────────────
#  Theme Palette & UI Functions
# ─────────────────────────────────────────────────────────────────────────────

C_MAIN='\033[38;2;202;169;224m'
C_ACCENT='\033[38;2;145;177;240m'
C_DIM='\033[38;2;129;122;150m'
C_GREEN='\033[38;2;166;209;137m'
C_YELLOW='\033[38;2;229;200;144m'
C_RED='\033[38;2;231;130;132m'
C_BOLD='\033[1m'
C_RESET='\033[0m'

header() {
    clear
    echo -e "${C_MAIN}${C_BOLD}"
    echo " ╭──────────────────────────────────────────╮"
    echo " │     🔒 QUICKSHELL LOCKSCREEN SETUP 🔒    │"
    echo " ╰──────────────────────────────────────────╯"
    echo -e "${C_RESET}"
}

info() {
    echo -e "${C_MAIN}${C_BOLD} ╭─ 󰓅 $1${C_RESET}"
}

substep() {
    echo -e "${C_MAIN}${C_BOLD} │  ${C_DIM}❯ ${C_RESET}$1"
}

success() {
    echo -e "${C_MAIN}${C_BOLD} ╰─ ${C_GREEN}✔ ${C_RESET}$1\n"
}

error() {
    echo -e "${C_MAIN}${C_BOLD} ╰─ ${C_RED}✘ ${C_RESET}$1\n"
}

# ─────────────────────────────────────────────────────────────────────────────
#  Core Logic
# ─────────────────────────────────────────────────────────────────────────────

header

# Dependency check
info "Checking dependencies..."

if ! command -v quickshell &> /dev/null; then
    error "Quickshell is not installed. Install it with: pacman -S quickshell or yay -S quickshell"
    exit 1
fi
substep "Quickshell found"

success "Dependencies verified"

info "Initializing Installation..."
substep "Target directory: $TARGET_DIR"

echo -ne "${C_MAIN}${C_BOLD} │  ${C_YELLOW}Do you want to proceed? (y/n): ${C_RESET}"
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "Installation aborted."
    exit 1
fi

info "Deploying Base Files..."
rm -rf "$TARGET_DIR"
cp -r "$DIR/quickshell-lockscreen" "$TARGET_DIR"
substep "Copied wrapper successfully"

ln -sfn "$DIR/themes" "$TARGET_DIR/themes_link"
substep "Created symbolic link to local themes"

chmod +x "$TARGET_DIR/lock.sh"
success "Permissions applied"

info "Selecting Default Lockscreen Theme..."

THEMES_DIR="$DIR/themes"

if ! command -v fzf &> /dev/null; then
    substep "fzf not found. Using basic list..."
    THEMES=($(ls -1 "$THEMES_DIR"))
    for i in "${!THEMES[@]}"; do
        echo -e "${C_MAIN}${C_BOLD} │  ${C_ACCENT}$((i+1)) ${C_DIM}❯ ${C_RESET}${THEMES[$i]}"
    done
    echo -ne "${C_MAIN}${C_BOLD} ╰─ ${C_YELLOW}Choice: ${C_RESET}"
    read -rp "" SELECTION
    if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "${#THEMES[@]}" ]; then
        THEME_NAME="${THEMES[$((SELECTION-1))]}"
    else
        error "Invalid selection. Defaulting to 'Genshin'."
        THEME_NAME="Genshin"
    fi
else
    THEME_NAME=$(ls -1 "$THEMES_DIR" | fzf --prompt="Select theme: " --height=15 --reverse --border --header="Use arrow keys/Enter to select lockscreen theme")
    if [ -z "$THEME_NAME" ]; then
        error "No theme selected. Defaulting to 'Genshin'."
        THEME_NAME="Genshin"
    fi
fi

# Sub-selection logic for variants (Ported from sddm.sh)
if [ "$THEME_NAME" == "cozytile" ]; then
    info "Selecting variant for Cozytile theme..."
    COZYTILE_DIR="$THEMES_DIR/cozytile"
    if ! command -v fzf &> /dev/null; then
        VARIANTS=($(ls -1 "$COZYTILE_DIR"))
        for i in "${!VARIANTS[@]}"; do
            echo -e "${C_MAIN}${C_BOLD} │  ${C_ACCENT}$((i+1)) ${C_DIM}❯ ${C_RESET}${VARIANTS[$i]}"
        done
        echo -ne "${C_MAIN}${C_BOLD} ╰─ ${C_YELLOW}Choice: ${C_RESET}"
        read -rp "" V_SELECTION
        if [[ "$V_SELECTION" =~ ^[0-9]+$ ]] && [ "$V_SELECTION" -ge 1 ] && [ "$V_SELECTION" -le "${#VARIANTS[@]}" ]; then
            THEME_NAME="cozytile/${VARIANTS[$((V_SELECTION-1))]}"
        fi
    else
        SELECTED_VARIANT=$(ls -1 "$COZYTILE_DIR" | fzf --prompt="Select variant: " --height=10 --reverse --border --header="Choose a Cozytile variant")
        [ -n "$SELECTED_VARIANT" ] && THEME_NAME="cozytile/$SELECTED_VARIANT"
    fi
fi

if [ "$THEME_NAME" == "tui" ]; then
    info "Selecting variant for TUI theme..."
    TUI_VARIANTS_DIR="$THEMES_DIR/tui"
    if ! command -v fzf &> /dev/null; then
        VARIANTS=($(ls -1 "$TUI_VARIANTS_DIR"))
        for i in "${!VARIANTS[@]}"; do
            echo -e "${C_MAIN}${C_BOLD} │  ${C_ACCENT}$((i+1)) ${C_DIM}❯ ${C_RESET}${VARIANTS[$i]}"
        done
        echo -ne "${C_MAIN}${C_BOLD} ╰─ ${C_YELLOW}Choice: ${C_RESET}"
        read -rp "" V_SELECTION
        if [[ "$V_SELECTION" =~ ^[0-9]+$ ]] && [ "$V_SELECTION" -ge 1 ] && [ "$V_SELECTION" -le "${#VARIANTS[@]}" ]; then
            THEME_NAME="tui/${VARIANTS[$((V_SELECTION-1))]}"
        fi
    else
        SELECTED_VARIANT=$(ls -1 "$TUI_VARIANTS_DIR" | fzf --prompt="Select TUI variant: " --height=10 --reverse --border --header="Choose a TUI color variant")
        [ -n "$SELECTED_VARIANT" ] && THEME_NAME="tui/$SELECTED_VARIANT"
    fi
fi

if [ "$THEME_NAME" == "terraria" ]; then
    info "Customizing Terraria sub-theme..."
    echo -e "${C_MAIN}${C_BOLD} │  ${C_ACCENT}1 ${C_DIM}❯ ${C_RESET}Time-based (Transitions with day/night)"
    echo -e "${C_MAIN}${C_BOLD} │  ${C_ACCENT}2 ${C_DIM}❯ ${C_RESET}Random (New background per lock)"
    echo -ne "${C_MAIN}${C_BOLD} ╰─ ${C_YELLOW}Choice [1/2]: ${C_RESET}"
    read -rp "" SUB_OPT
    case $SUB_OPT in
        1) sed -i "s/^background_mode=.*/background_mode=time/" "$THEMES_DIR/terraria/theme.conf" ;;
        2) sed -i "s/^background_mode=.*/background_mode=random/" "$THEMES_DIR/terraria/theme.conf" ;;
    esac
fi

if [ "$THEME_NAME" == "Genshin" ]; then
    info "Customizing Genshin Impact sub-theme..."
    echo -e "${C_MAIN}${C_BOLD} │  ${C_ACCENT}1 ${C_DIM}❯ ${C_RESET}Time-based (Dawn / Day / Dusk / Night)"
    echo -e "${C_MAIN}${C_BOLD} │  ${C_ACCENT}2 ${C_DIM}❯ ${C_RESET}Random (New background per lock)"
    echo -ne "${C_MAIN}${C_BOLD} ╰─ ${C_YELLOW}Choice [1/2]: ${C_RESET}"
    read -rp "" SUB_OPT
    case $SUB_OPT in
        1) sed -i "s/^background_mode=.*/background_mode=time/" "$THEMES_DIR/Genshin/theme.conf" ;;
        2) sed -i "s/^background_mode=.*/background_mode=random/" "$THEMES_DIR/Genshin/theme.conf" ;;
    esac
fi

# Check for fonts in the selected theme
FONT_COUNT=$(ls -1 "$THEMES_DIR/$THEME_NAME/font" 2>/dev/null | grep -E "\.(ttf|otf)$" | wc -l)
if [ "$FONT_COUNT" -eq 0 ]; then
    echo -e "${C_YELLOW}${C_BOLD} ╭─   MISSING FONT DETECTED${C_RESET}"
    echo -e "${C_YELLOW}${C_BOLD} │${C_RESET}  ${C_DIM}This theme looks better with its specific font!${C_RESET}"
    echo -e "${C_YELLOW}${C_BOLD} │${C_RESET}  ${C_DIM}Please put the .ttf/.otf file in:${C_RESET}"
    echo -e "${C_YELLOW}${C_BOLD} │${C_RESET}  ${C_ACCENT}$THEMES_DIR/$THEME_NAME/font/${C_RESET}"
    echo -e "${C_YELLOW}${C_BOLD} ╰─ ${C_DIM}Refer to README.md for font suggestions.${C_RESET}\n"
fi

sed -i "s|export QS_THEME=.*$|export QS_THEME=\"\${1:-$THEME_NAME}\"|" "$TARGET_DIR/lock.sh"
success "Theme '$THEME_NAME' set as lockscreen default!"

info "Keyboard Shortcut Instructions"
substep "To use this lockscreen natively, bind a shortcut (e.g., Mod + L) in your Window Manager's configuration."
substep "Set the shortcut to execute: ${C_YELLOW}$TARGET_DIR/lock.sh${C_RESET}"
echo ""
success "Setup completely successfully. Stay secure!"
