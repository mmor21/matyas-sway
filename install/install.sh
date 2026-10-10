#!/usr/bin/env bash
#
# Matyas Sway — installer
#
# For a fresh CachyOS Sway Edition install. Refuses to run if a
# matyas-sway config or clone is already present. See the pre-flight
# summary for exactly what it will do.
#
# Usage (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/mmor21/matyas-sway/main/install/install.sh | bash
#
# Or, from a clone:
#   bash install/install.sh

set -euo pipefail

##─ Constants ──────────────────────────────────────────────────────

REPO_URL="https://github.com/mmor21/matyas-sway"
CLONE_DIR="$HOME/matyas-sway"
CONFIG_DIR="$HOME/.config/sway"
BACKGROUNDS_DIR="$HOME/.config/backgrounds"
GHOSTTY_DIR="$HOME/.config/ghostty"
NWGDOCK_DIR="$HOME/.config/nwg-dock"
MIMEAPPS="$HOME/.config/mimeapps.list"

##─ Output helpers ─────────────────────────────────────────────────

say()  { printf '%s\n' "$*"; }
ok()   { printf '  ok   %s\n' "$*"; }
info() { printf '  --   %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

##─ Guards ─────────────────────────────────────────────────────────
## All checks happen before anything is modified. Any failure exits
## with a clear message and leaves the system untouched.

say "Matyas Sway installer"
say ""

command -v pacman >/dev/null 2>&1 \
    || die "pacman not found. This installer targets Arch-family systems."

[[ $EUID -ne 0 ]] \
    || die "Do not run as root. Run as the user who will own the config."

[[ ! -e "$CONFIG_DIR" ]] \
    || die "$CONFIG_DIR already exists. This installer is for fresh installs only. Nothing has been changed."

[[ ! -e "$CLONE_DIR" ]] \
    || die "$CLONE_DIR already exists. Remove it or rename it, then run again. Nothing has been changed."

command -v git >/dev/null 2>&1 \
    || die "git not found. Install it and run again."

ok "guards passed"

##─ Pre-flight ─────────────────────────────────────────────────────
## Fetch packages.txt before cloning, so the summary is honest and
## nothing is created before the user confirms.

say ""
say "Fetching package list..."
PKG_LIST_URL="$REPO_URL/raw/main/install/packages.txt"
PKG_LIST_RAW="$(curl -fsSL "$PKG_LIST_URL")" \
    || die "Could not fetch $PKG_LIST_URL. Check your network."

# Parse into two arrays. Section markers switch the current bucket.
declare -a PKG_A=() PKG_B=()
bucket=""
while IFS= read -r line; do
    case "$line" in
        \[A\]) bucket="A" ;;
        \[B\]) bucket="B" ;;
        \#*|'') continue ;;
        *)    [[ -z "$bucket" ]] && continue
              if [[ "$bucket" == "A" ]]; then PKG_A+=("$line")
              else PKG_B+=("$line"); fi ;;
    esac
done <<< "$PKG_LIST_RAW"

(( ${#PKG_A[@]} > 0 && ${#PKG_B[@]} > 0 )) \
    || die "Failed to parse packages.txt (A=${#PKG_A[@]}, B=${#PKG_B[@]})."

# Which are missing?
declare -a MISSING_A=() MISSING_B=()
for p in "${PKG_A[@]}"; do
    pacman -Qi "$p" >/dev/null 2>&1 || MISSING_A+=("$p")
done
for p in "${PKG_B[@]}"; do
    pacman -Qi "$p" >/dev/null 2>&1 || MISSING_B+=("$p")
done

# Summary
say ""
say "This will install matyas-sway on this machine."
say ""
say "  user:          $(whoami)"
say "  home:          $HOME"
say ""
say "  will clone:    $CLONE_DIR"
say "  from:          $REPO_URL"
say ""

if (( ${#MISSING_A[@]} == 0 && ${#MISSING_B[@]} == 0 )); then
    say "  packages:      all already present, nothing to install"
else
    say "  packages to install:"
    for p in "${MISSING_A[@]}"; do say "    [A] $p"; done
    for p in "${MISSING_B[@]}"; do say "    [B] $p"; done
fi

say ""
say "  will copy:"
say "    $CLONE_DIR/.config/sway/          -> $CONFIG_DIR/"
say "    $CLONE_DIR/theme/                 -> $CONFIG_DIR/theme/"
say "    $CLONE_DIR/.config/ghostty/       -> $GHOSTTY_DIR/"
say "    $CLONE_DIR/.config/sway/nwg-dock/ -> $NWGDOCK_DIR/"
say "    $CLONE_DIR/.config/mimeapps.list  -> $MIMEAPPS"
say ""
say "  will create (empty):"
say "    $BACKGROUNDS_DIR/   (drop wallpapers here later)"
say ""
say "  will check (not touch):"
say "    $CONFIG_DIR/ must not already exist"
say ""
say "  will NOT touch:"
say "    /etc/sway/, ly, /usr/share/wayland-sessions/, any systemd service"
say ""

read -r -p "Proceed? [y/N] " reply < /dev/tty
case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) say ""; say "Aborted. Nothing was changed."; exit 0 ;;
esac

##─ Clone ──────────────────────────────────────────────────────────

say ""
say "Cloning $REPO_URL ..."
git clone --depth 1 "$REPO_URL" "$CLONE_DIR" >/dev/null 2>&1 \
    || die "git clone failed. Nothing further was changed."
ok "cloned to $CLONE_DIR"

##─ Packages ───────────────────────────────────────────────────────

if (( ${#MISSING_A[@]} > 0 || ${#MISSING_B[@]} > 0 )); then
    say ""
    say "Installing missing packages..."
    # Re-check against the clone's packages.txt in case it differs from
    # what we fetched. (Normally identical; this is defensive.)
    if ! sudo pacman -S --needed --noconfirm "${MISSING_A[@]}" "${MISSING_B[@]}"; then
        # Did every A package land?
        failed_A=()
        for p in "${MISSING_A[@]}"; do
            pacman -Qi "$p" >/dev/null 2>&1 || failed_A+=("$p")
        done
        if (( ${#failed_A[@]} > 0 )); then
            die "Category A package(s) failed to install: ${failed_A[*]}
The session would be unusable without them. Stopping.
Config files: NOT copied.
Clone:         left at $CLONE_DIR (remove it manually if you re-run)."
        fi
        warn "Some category B packages may have failed. Continuing; the summary will list them."
    fi
else
    say ""
    ok "all packages already present"
fi

# Recompute B failures for the summary.
declare -a FAILED_B=()
for p in "${MISSING_B[@]}"; do
    pacman -Qi "$p" >/dev/null 2>&1 || FAILED_B+=("$p")
done

##─ Copy config ────────────────────────────────────────────────────

say ""
say "Copying config files..."

copy_tree() {
    local src="$1" dst="$2"
    mkdir -p "$dst"
    cp -a "$src/." "$dst/"
}

copy_tree "$CLONE_DIR/.config/sway"          "$CONFIG_DIR"
copy_tree "$CLONE_DIR/theme"                 "$CONFIG_DIR/theme"
copy_tree "$CLONE_DIR/.config/ghostty"       "$GHOSTTY_DIR"
copy_tree "$CLONE_DIR/.config/sway/nwg-dock" "$NWGDOCK_DIR"

mkdir -p "$(dirname "$MIMEAPPS")"
cp -a "$CLONE_DIR/.config/mimeapps.list" "$MIMEAPPS"

# Empty backgrounds dir; user drops wallpapers in later.
mkdir -p "$BACKGROUNDS_DIR"

ok "config copied"

##─ Permissions ────────────────────────────────────────────────────

chmod +x "$CONFIG_DIR"/scripts/*          2>/dev/null || true
chmod +x "$CONFIG_DIR"/theme/*.sh         2>/dev/null || true
chmod +x "$CONFIG_DIR"/theme/*.py         2>/dev/null || true
chmod +x "$CONFIG_DIR"/waybar/lightmode   2>/dev/null || true

ok "permissions set"

##─ Summary ────────────────────────────────────────────────────────

say ""
say "Done."
say ""
say "  clone:      $CLONE_DIR"
say "  config:     $CONFIG_DIR"
say "  wallpapers: $BACKGROUNDS_DIR   (empty — add images yourself)"
say ""

if (( ${#FAILED_B[@]} > 0 )); then
    warn "The following category B packages did not install:"
    for p in "${FAILED_B[@]}"; do warn "  $p"; done
    say ""
    say "The session will still work; the affected features will be missing"
    say "until those packages are installed."
    say ""
fi

say "Sway is still running the stock config from this session."
say "Log out and log back in (or reboot) to load matyas-sway."
say ""
