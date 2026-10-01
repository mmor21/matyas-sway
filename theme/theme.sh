#!/usr/bin/env bash
# Palette variables come from the sourced palette files.
# shellcheck disable=SC2154
## Matyas Sway — Theme engine
##
## Applies a color palette across every themed component and reloads
## Sway. Called by waybar/lightmode.
##
## Modes:
##   --dark | --default   apply theme/dark.bash   (--default kept for lightmode)
##   --light              apply theme/light.bash
##   --orange             apply theme/orange.bash
##   --pywal              generate a palette from a random wallpaper via pywal
##   --wallpaper PATH     set a wallpaper only, palette untouched
##
## The pywal mode requires the "wal" command to be installed.

set -euo pipefail

##─ Paths ──────────────────────────────────────────────────────────
SWAY_DIR="$HOME/.config/sway"
THEME_DIR="$SWAY_DIR/theme"
PATH_SWAY_THEME="$SWAY_DIR/sway-theme"
PATH_SWAY_OUTPUT="$SWAY_DIR/sway-output"
PATH_WAYBAR_COLORS="$SWAY_DIR/waybar/colors.css"
PATH_WAYBAR_MODULES="$SWAY_DIR/waybar/modules"
PATH_ROFI_COLORS="$SWAY_DIR/rofi/shared/colors.rasi"
PATH_MAKO="$SWAY_DIR/mako/config"
PATH_GHOSTTY="$HOME/.config/ghostty/colors"

CURRENT="$THEME_DIR/current.bash"
PYWAL="$HOME/.cache/wal/colors.sh"

##─ Helpers ────────────────────────────────────────────────────────

# write_if_changed <file>   (reads new content from stdin)
# Writes atomically next to the real file (follows symlinks, so stow /
# chezmoi links survive) and keeps the original permissions.
write_if_changed() {
    local file tmp
    file="$(realpath -m "$1")"
    tmp="$(mktemp "${file}.XXXXXX")"
    cat > "$tmp"
    if cmp -s "$tmp" "$file"; then
        rm -f "$tmp"
        return
    fi
    [[ -e "$file" ]] && chmod --reference="$file" "$tmp"
    mv -f "$tmp" "$file"
}

# Lighten a hex color by ~8% (rough approximation, no dependencies).
lighten() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    r=$(( r + (255 - r) * 8 / 100 ))
    g=$(( g + (255 - g) * 8 / 100 ))
    b=$(( b + (255 - b) * 8 / 100 ))
    printf '#%02x%02x%02x' "$r" "$g" "$b"
}

# Darken a hex color by ~30%.
darken() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    printf '#%02x%02x%02x' $(( r * 70 / 100 )) $(( g * 70 / 100 )) $(( b * 70 / 100 ))
}

notify() {
    notify-send \
        -h string:x-canonical-private-synchronous:sys-notify-theme \
        -u normal \
        -i "$SWAY_DIR/mako/icons/palette.png" \
        "$1" 2>/dev/null || true
}

##─ Palette loaders ────────────────────────────────────────────────

# load_palette <file> <light|dark> <label>
load_palette() {
    local src="$1" kind="$2" label="$3"
    cp "$src" "$CURRENT"
    # shellcheck disable=SC1090
    source "$CURRENT"
    if [[ "$kind" == light ]]; then
        altbackground="$(darken "$background")"
        altforeground="$(lighten "$foreground")"
    else
        altbackground="$(lighten "$background")"
        altforeground="$(darken "$foreground")"
    fi
    accent="$color4"
    if [[ -n "$label" ]]; then notify "$label"; fi
}

source_pywal() {
    local wall_dir
    wall_dir="$(xdg-user-dir PICTURES)/wallpapers"

    if [[ ! -d "$wall_dir" ]]; then
        mkdir -p "$wall_dir"
        notify "Put some wallpapers in: $wall_dir"
        exit 1
    fi

    local -a wallpapers
    shopt -s nullglob nocaseglob
    wallpapers=( "$wall_dir"/*.{jpg,jpeg,png,webp,bmp} )
    shopt -u nullglob nocaseglob

    if (( ${#wallpapers[@]} == 0 )); then
        notify "There are no wallpapers in: $wall_dir"
        exit 1
    fi

    if ! command -v wal >/dev/null 2>&1; then
        notify "'pywal' is not installed."
        exit 1
    fi

    notify "Generating colorscheme. Please wait..."
    wal -q -n -s -t -e -i "$wall_dir"

    # Trim FZF color block (some wal versions append it and it breaks source)
    sed '/# FZF colors/Q' "$PYWAL" > "$CURRENT.tmp"
    load_palette "$CURRENT.tmp" dark ""
    rm -f "$CURRENT.tmp"
    # pywal's colors.sh defines $wallpaper; the static palettes don't.
}

##─ Per-component appliers ─────────────────────────────────────────

# set_bg_line <image>   — replace or append "output * bg" in sway-output.
# awk + ENVIRON instead of sed: paths with &, |, \ or spaces are safe,
# and the path is quoted for Sway.
set_bg_line() {
    local out
    out="$(BG="$1" awk '
        BEGIN { line = "output * bg \"" ENVIRON["BG"] "\" fill" }
        /^output \* bg/ { print line; done = 1; next }
        { print }
        END { if (!done) { print ""; print line } }
    ' "$PATH_SWAY_OUTPUT")"
    printf '%s\n' "$out" | write_if_changed "$PATH_SWAY_OUTPUT"
}

# All edits to sway-theme happen in ONE sed call. Two parallel
# "sed -i" runs on the same file race, and one edit gets lost.
apply_sway_theme() {
    local -a e=(
        -e "s|^set \$sway_cl_col_bg.*|set \$sway_cl_col_bg   $background|"
        -e "s|^set \$sway_cl_col_fg.*|set \$sway_cl_col_fg   $foreground|"
        -e "s|^set \$sway_cl_col_in.*|set \$sway_cl_col_in   $color3|"
        -e "s|^set \$sway_cl_col_afoc.*|set \$sway_cl_col_afoc $accent|"
        -e "s|^set \$sway_cl_col_ifoc.*|set \$sway_cl_col_ifoc $color2|"
        -e "s|^set \$sway_cl_col_ufoc.*|set \$sway_cl_col_ufoc $altbackground|"
        -e "s|^set \$sway_cl_col_urgt.*|set \$sway_cl_col_urgt $color1|"
        -e "s|^set \$sway_cl_col_phol.*|set \$sway_cl_col_phol $background|"
    )
    # GTK settings only exist in the static palettes, not in pywal's.
    if [[ -n "${gtk_theme:-}" ]]; then
        e+=(
            -e "s|^set \$sway_gtk_theme.*|set \$sway_gtk_theme    $gtk_theme|"
            -e "s|^set \$sway_icon_theme.*|set \$sway_icon_theme   $gtk_icons|"
            -e "s|^set \$sway_cursor_theme.*|set \$sway_cursor_theme $cursor_theme|"
            -e "s|^set \$sway_fonts.*|set \$sway_fonts        $gtk_font|"
        )
    fi
    sed -i --follow-symlinks "${e[@]}" "$PATH_SWAY_THEME"

    if [[ -n "${gtk_colors:-}" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme "'$gtk_colors'" 2>/dev/null || true
    fi
}

apply_waybar() {
    write_if_changed "$PATH_WAYBAR_COLORS" <<-EOF
			/* Matyas Sway — Waybar colors
			 * Overwritten by theme.sh.
			 */

			@define-color background     $background;
			@define-color background-alt $altbackground;
			@define-color foreground     $foreground;
			@define-color foreground-alt $altforeground;
			@define-color selected       $accent;
			@define-color black          $color0;
			@define-color red            $color1;
			@define-color green          $color2;
			@define-color yellow         $color3;
			@define-color blue           $color4;
			@define-color magenta        $color5;
			@define-color cyan           $color6;
			@define-color white          $color7;
		EOF
}

apply_waybar_modules() {
    # Rewrite the calendar span colors in waybar/modules (see
    # waybar-calendar.py, which validates JSONC before writing).
    "$THEME_DIR/waybar-calendar.py" \
        "$PATH_WAYBAR_MODULES" \
        "$foreground" "$color6" "$color3" "$color4" "$background" >/dev/null
}

apply_rofi() {
    write_if_changed "$PATH_ROFI_COLORS" <<-EOF
			/* Matyas Sway — Rofi shared colors
			 * Overwritten by theme.sh.
			 */

			* {
			    background:     $background;
			    background-alt: $altbackground;
			    foreground:     $foreground;
			    selected:       $accent;
			    active:         $color2;
			    urgent:         $color1;
			}
		EOF
}

apply_mako() {
    # Keep everything above the Mako_Colors marker, replace the rest.
    {
        sed '/# Mako_Colors/Q' "$PATH_MAKO"
        cat <<-EOF
			# Mako_Colors
			background-color=$background
			text-color=$foreground
			border-color=$altbackground
			progress-color=over $accent

			[urgency=low]
			border-color=$altbackground
			default-timeout=2000

			[urgency=normal]
			border-color=$altbackground
			default-timeout=5000

			[urgency=high]
			border-color=$color1
			text-color=$color1
			default-timeout=0
		EOF
    } | write_if_changed "$PATH_MAKO"
}

apply_ghostty() {
    write_if_changed "$PATH_GHOSTTY" <<-EOF
			## Matyas Sway — Ghostty colors
			## Overwritten by theme.sh.

			background = $background
			foreground = $foreground
			cursor-color = $foreground
			selection-background = $foreground
			selection-foreground = $background

			palette = 0=$color0
			palette = 1=$color1
			palette = 2=$color2
			palette = 3=$color3
			palette = 4=$color4
			palette = 5=$color5
			palette = 6=$color6
			palette = 7=$color7
			palette = 8=$color8
			palette = 9=$color9
			palette = 10=$color10
			palette = 11=$color11
			palette = 12=$color12
			palette = 13=$color13
			palette = 14=$color14
			palette = 15=$color15
		EOF
}

##─ Dispatch ───────────────────────────────────────────────────────

set_wallpaper_only() {
    local new_wallpaper="$1"
    if [[ ! -f "$new_wallpaper" ]]; then
        notify "Wallpaper not found: $new_wallpaper"
        exit 1
    fi
    set_bg_line "$(realpath "$new_wallpaper")"
    swaymsg reload >/dev/null 2>&1 || true
    notify "Wallpaper updated."
}

case "${1:-}" in
    --dark|--default) load_palette "$THEME_DIR/dark.bash"   dark  "Applying Dark Theme…" ;;
    --light)          load_palette "$THEME_DIR/light.bash"  light "Applying Light Theme…" ;;
    --orange)         load_palette "$THEME_DIR/orange.bash" dark  "Applying IC Orange Theme…" ;;
    --pywal)          source_pywal ;;
    --wallpaper)      set_wallpaper_only "${2:-}"; exit 0 ;;
    *)
        echo "Usage: theme.sh --dark | --light | --orange | --pywal | --wallpaper PATH" >&2
        exit 1
        ;;
esac

##─ Parallel apply phase ───────────────────────────────────────────
## Each job writes a different file, so they can run in parallel.
## A bare "wait" always returns 0, so wait on each PID and report.

declare -A jobs=()
apply_sway_theme     & jobs[$!]=sway-theme
apply_waybar         & jobs[$!]=waybar-colors
apply_waybar_modules & jobs[$!]=waybar-calendar
apply_rofi           & jobs[$!]=rofi
apply_mako           & jobs[$!]=mako
apply_ghostty        & jobs[$!]=ghostty
if [[ -n "${wallpaper:-}" && -f "$wallpaper" ]]; then
    set_bg_line "$wallpaper" & jobs[$!]=wallpaper
fi

failed=()
for pid in "${!jobs[@]}"; do
    wait "$pid" || failed+=("${jobs[$pid]}")
done
if (( ${#failed[@]} )); then
    notify "Theme: failed to update ${failed[*]}"
fi

# Reloads last. "swaymsg reload" re-runs exec_always startup, which
# restarts Waybar and mako, so they pick up the new files too.
swaymsg reload >/dev/null 2>&1 || true

exit 0
