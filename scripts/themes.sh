# Shared theme discovery and validation for the setup scripts.

qylock_theme_exists() {
    local root="$1" theme="$2"
    [[ "$theme" =~ ^[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)*$ ]] &&
        [[ -f "$root/$theme/Main.qml" ]] &&
        [[ -f "$root/$theme/theme.conf" || -f "$root/$theme/metadata.desktop" ]]
}

qylock_themes() (
    local root="$1" main theme
    shopt -s globstar nullglob
    for main in "$root"/**/Main.qml; do
        theme="${main#"$root/"}"
        theme="${theme%/Main.qml}"
        if qylock_theme_exists "$root" "$theme"; then
            printf '%s\n' "$theme"
        fi
    done
)

qylock_has_fonts() (
    shopt -s nullglob
    local -a fonts=("$1"/font/*.ttf "$1"/font/*.otf)
    [[ ${#fonts[@]} -gt 0 ]]
)
