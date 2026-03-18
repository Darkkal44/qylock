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

# Check for fonts in the selected theme
FONT_COUNT=$(ls -1 "$THEMES_DIR/$THEME_NAME/font" 2>/dev/null | grep -E "\.(ttf|otf)$" | wc -l)
if [ "$FONT_COUNT" -eq 0 ]; then
    echo -e "${C_YELLOW}${C_BOLD} ╭─   MISSING FONT DETECTED${C_RESET}"
    echo -e "${C_YELLOW}${C_BOLD} │${C_RESET}  ${C_DIM}This theme looks better with its specific font!${C_RESET}"
    echo -e "${C_YELLOW}${C_BOLD} │${C_RESET}  ${C_DIM}Please put the .ttf/.otf file in:${C_RESET}"
    echo -e "${C_YELLOW}${C_BOLD} │${C_RESET}  ${C_ACCENT}$THEMES_DIR/$THEME_NAME/font/${C_RESET}"
    echo -e "${C_YELLOW}${C_BOLD} ╰─ ${C_DIM}Refer to README.md for font suggestions.${C_RESET}\n"
fi

sed -i "s/export QS_THEME=.*$/export QS_THEME=\"\${1:-$THEME_NAME}\"/" "$TARGET_DIR/lock.sh"
success "Theme '$THEME_NAME' set as lockscreen default!"

info "Keyboard Shortcut Instructions"
substep "To use this lockscreen natively, bind a shortcut (e.g., Mod + L) in your Window Manager's configuration."
substep "Set the shortcut to execute: ${C_YELLOW}$TARGET_DIR/lock.sh${C_RESET}"
echo ""
success "Setup completely successfully. Stay secure!"
