#!/usr/bin/env bash
## Matyas Sway — Theme engine
##
## Applies a color palette across every themed component and reloads
## Sway. Called by waybar/lightmode and by theme/current.bash.
##
## Modes:
##   --default   apply theme/default.bash
##   --light     apply theme/light.bash
##   --pywal     generate a palette from a random wallpaper via pywal
##
## The pywal mode requires the "wal" command to be installed.

set -euo pipefail

##─ Paths ──────────────────────────────────────────────────────────
SWAY_DIR="$HOME/.config/sway"
THEME_DIR="$SWAY_DIR/theme"
PATH_SWAY_THEME="$SWAY_DIR/sway-theme"
PATH_SWAY_OUTPUT="$SWAY_DIR/sway-output"
PATH_WAYBAR_COLORS="$SWAY_DIR/waybar/colors.css"
PATH_ROFI_COLORS="$SWAY_DIR/rofi/shared/colors.rasi"
PATH_MAKO="$SWAY_DIR/mako/config"
PATH_KITTY="$SWAY_DIR/kitty/colors.conf"

CURRENT="$THEME_DIR/current.bash"
DEFAULT="$THEME_DIR/default.bash"
LIGHT="$THEME_DIR/light.bash"
PYWAL="$HOME/.cache/wal/colors.sh"

##─ Helpers ────────────────────────────────────────────────────────

# write_if_changed <file>   (reads new content from stdin)
# Only writes if the new content differs from the current file.
write_if_changed() {
    local file="$1"
    local tmp
    tmp="$(mktemp)"

    cat > "$tmp"

    if ! cmp -s "$tmp" "$file" 2>/dev/null; then
        mv "$tmp" "$file"
    else
        rm -f "$tmp"
    fi
}

# Lighten a hex color by ~8% (rough approximation, no dependencies).
lighten() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    r=$(( r + (255 - r) * 8 / 100 ))
    g=$(( g + (255 - g) * 8 / 100 ))
    b=$(( b + (255 - b) * 8 / 100 ))
    printf '#%02x%02x%02x' "$r" "$g" "$b"
}

# Darken a hex color by ~30%.
darken() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    r=$(( r * 70 / 100 ))
    g=$(( g * 70 / 100 ))
    b=$(( b * 70 / 100 ))
    printf '#%02x%02x%02x' "$r" "$g" "$b"
}

notify() {
    notify-send \
        -h string:x-canonical-private-synchronous:sys-notify-theme \
        -u normal \
        -i "$SWAY_DIR/mako/icons/palette.png" \
        "$1" 2>/dev/null || true
}

##─ Palette loaders ────────────────────────────────────────────────

source_default() {
    cp "$DEFAULT" "$CURRENT"
    # shellcheck disable=SC1090
    source "$CURRENT"
    altbackground="$(lighten "$background")"
    altforeground="$(darken "$foreground")"
    accent="$color4"
    notify "Applying Default Theme…"
}

source_light() {
    cp "$LIGHT" "$CURRENT"
    # shellcheck disable=SC1090
    source "$CURRENT"
    altbackground="$(darken "$background")"
    altforeground="$(lighten "$foreground")"
    accent="$color4"
    notify "Applying Light Theme…"
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
    shopt -s nullglob
    wallpapers=( "$wall_dir"/*.{jpg,jpeg,png,webp,bmp} )
    shopt -u nullglob

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

    cp "$PYWAL" "$CURRENT"
    # Trim FZF color block (some wal versions append it and it breaks source)
    sed -i '/# FZF colors/Q' "$CURRENT"
    # shellcheck disable=SC1090
    source "$CURRENT"
    altbackground="$(lighten "$background")"
    altforeground="$(darken "$foreground")"
    accent="$color4"
}

##─ Per-component appliers ─────────────────────────────────────────

apply_wallpaper() {
    if grep -q "^output \* bg" "$PATH_SWAY_OUTPUT"; then
        # An active wallpaper line exists — replace it.
        sed -i "s|^output \* bg.*|output * bg $wallpaper fill|" "$PATH_SWAY_OUTPUT"
    else
        # No active line — append one.
        printf '\noutput * bg %s fill\n' "$wallpaper" >> "$PATH_SWAY_OUTPUT"
    fi
}

apply_sway_theme() {
    sed -i "$PATH_SWAY_THEME" \
        -e "s|^set \$sway_cl_col_bg.*|set \$sway_cl_col_bg   $background|" \
        -e "s|^set \$sway_cl_col_fg.*|set \$sway_cl_col_fg   $foreground|" \
        -e "s|^set \$sway_cl_col_in.*|set \$sway_cl_col_in   $color3|" \
        -e "s|^set \$sway_cl_col_afoc.*|set \$sway_cl_col_afoc $accent|" \
        -e "s|^set \$sway_cl_col_ifoc.*|set \$sway_cl_col_ifoc $color2|" \
        -e "s|^set \$sway_cl_col_ufoc.*|set \$sway_cl_col_ufoc $altbackground|" \
        -e "s|^set \$sway_cl_col_urgt.*|set \$sway_cl_col_urgt $color1|" \
        -e "s|^set \$sway_cl_col_phol.*|set \$sway_cl_col_phol $background|"
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
    # Truncate the file at the Mako_Colors marker, then append new colors
    sed -i '/# Mako_Colors/Q' "$PATH_MAKO"

    cat >> "$PATH_MAKO" <<-EOF
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

    makoctl reload 2>/dev/null || true
}

apply_kitty() {
    write_if_changed "$PATH_KITTY" <<-EOF
		## Matyas Sway — Kitty colors
		## Overwritten by theme.sh.

		background $background
		foreground $foreground
		selection_background $foreground
		selection_foreground $background
		cursor $foreground

		color0  $color0
		color8  $color8
		color1  $color1
		color9  $color9
		color2  $color2
		color10 $color10
		color3  $color3
		color11 $color11
		color4  $color4
		color12 $color12
		color5  $color5
		color13 $color13
		color6  $color6
		color14 $color14
		color7  $color7
		color15 $color15
	EOF

    # Ask any running kitty to reload its config
    pkill -USR1 kitty 2>/dev/null || true
}

apply_gtk() {
    sed -i "$PATH_SWAY_THEME" \
        -e "s|^set \$sway_gtk_theme.*|set \$sway_gtk_theme    $gtk_theme|" \
        -e "s|^set \$sway_icon_theme.*|set \$sway_icon_theme   $gtk_icons|" \
        -e "s|^set \$sway_cursor_theme.*|set \$sway_cursor_theme $cursor_theme|" \
        -e "s|^set \$sway_fonts.*|set \$sway_fonts        $gtk_font|"

    gsettings set org.gnome.desktop.interface color-scheme "'$gtk_colors'" 2>/dev/null || true
}

##─ Dispatch ───────────────────────────────────────────────────────

case "${1:-}" in
    --default) source_default ;;
    --light)   source_light ;;
    --pywal)   source_pywal ;;
    *)
        echo "Usage: theme.sh --default | --light | --pywal" >&2
        exit 1
        ;;
esac

##─ Parallel apply phase ───────────────────────────────────────────
## Everything that just writes files runs in parallel, then we wait.
## UI reloads (mako, waybar) run last to avoid flicker.

apply_wallpaper &
apply_sway_theme &
apply_waybar &
apply_rofi &
apply_kitty &
apply_gtk &
wait

# Reload Sway so the new sway-theme colors take effect
swaymsg reload 2>/dev/null || true

exit 0
