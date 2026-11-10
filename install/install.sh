#!/usr/bin/env bash
# Matyas Sway installer. Existing files are backed up, never deleted.
set -Eeuo pipefail
REPO_URL=https://github.com/mmor21/matyas-sway
CLONE_DIR="$HOME/matyas-sway"
CONFIG_DIR="$HOME/.config/sway"
WORK=""
BACKUP=""
say() { printf '%s\n' "$*"; }
die() { say "ERROR: $*" >&2; exit 1; }
cleanup() { if [[ -n "$WORK" && -d "$WORK" ]]; then rm -rf -- "$WORK"; fi; }
trap cleanup EXIT
trap 'printf "ERROR: installer stopped at line %s (status %s). Existing backups, if created, remain at %s\n" "$LINENO" "$?" "${BACKUP:-not yet created}" >&2' ERR
[[ $EUID -ne 0 ]] || die 'Run as your normal user, not root.'
for cmd in pacman git sudo mktemp cp mv; do
    command -v "$cmd" >/dev/null || die "Required command missing: $cmd"
done
[[ -r /dev/tty && -w /dev/tty ]] || die 'Run this from an interactive terminal.'
say 'Matyas Sway installer'
say 'This will download main, install required packages, and try optional packages individually.'
say 'Before copying configs, existing sway, ghostty, nwg-dock, mimeapps.list and ~/matyas-sway will be moved into a timestamped backup in your home.'
say 'Backgrounds are preserved. No services, /etc/sway or session definitions are changed.'
say 'Package installation may ask you to resolve conflicts; no automatic system upgrade is performed.'
read -r -p 'Proceed? [y/N] ' reply < /dev/tty
case "$reply" in y|Y|yes|YES|Yes) ;; *) say 'Aborted. Nothing changed.'; exit 0 ;; esac
WORK=$(mktemp -d "$HOME/.matyas-sway-install.XXXXXXXX")
git clone --depth 1 --branch main "$REPO_URL" "$WORK/repo"
SRC="$WORK/repo"
for path in .config/sway theme .config/ghostty .config/sway/nwg-dock; do
    [[ -d "$SRC/$path" ]] || die "Repository directory missing: $path"
done
for path in install/packages.txt .config/mimeapps.list .config/sway/config; do
    [[ -f "$SRC/$path" ]] || die "Repository file missing: $path"
done
declare -a PKG_A=() PKG_B=() FAILED_B=()
bucket=''
while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    case "$line" in
        '[A]') bucket=A ;;
        '[B]') bucket=B ;;
        \#*|'') continue ;;
        *) [[ "$line" =~ ^[a-zA-Z0-9@._+-]+$ ]] || die "Invalid package entry: $line"
           case "$bucket" in
               A) PKG_A+=("$line") ;;
               B) PKG_B+=("$line") ;;
               *) die 'Package listed before section marker.' ;;
           esac ;;
    esac
done < "$SRC/install/packages.txt"
(( ${#PKG_A[@]} > 0 )) || die 'Required package list is empty.'
sudo -v < /dev/tty
say 'Installing required packages...'
if ! sudo pacman -S --needed "${PKG_A[@]}" < /dev/tty; then
    die 'Required package transaction failed. Existing configs and previous clone have NOT been touched. Correct the displayed pacman error, then rerun this installer.'
fi
for p in "${PKG_A[@]}"; do
    pacman -Q "$p" >/dev/null 2>&1 || die "Required package missing after installation: $p. Existing configs have NOT been touched."
done
for p in "${PKG_B[@]}"; do
    if ! pacman -Q "$p" >/dev/null 2>&1; then
        say "Installing optional package: $p"
        if ! sudo pacman -S --needed "$p" < /dev/tty; then
            say "WARNING: optional package failed: $p; continuing." >&2
        fi
    fi
    pacman -Q "$p" >/dev/null 2>&1 || FAILED_B+=("$p")
done
# Stage the complete Sway tree before replacing any existing configuration.
mkdir -p "$WORK/sway"
cp -a "$SRC/.config/sway/." "$WORK/sway/"
mkdir -p "$WORK/sway/theme"
cp -a "$SRC/theme/." "$WORK/sway/theme/"
BACKUP=$(mktemp -d "$HOME/matyas-sway-backup-$(date +%Y%m%d-%H%M%S).XXXXXXXX")
backup_path() {
    local path="$1" name="$2"
    if [[ -e "$path" || -L "$path" ]]; then
        mv -- "$path" "$BACKUP/$name"
        say "Backed up $path to $BACKUP/$name"
    fi
}
mkdir -p "$HOME/.config"
backup_path "$CONFIG_DIR" sway
backup_path "$HOME/.config/ghostty" ghostty
backup_path "$HOME/.config/nwg-dock" nwg-dock
backup_path "$HOME/.config/mimeapps.list" mimeapps.list
backup_path "$CLONE_DIR" previous-clone
mv -- "$WORK/sway" "$CONFIG_DIR"
mkdir -p "$HOME/.config/ghostty" "$HOME/.config/nwg-dock" "$HOME/.config/backgrounds"
cp -a "$SRC/.config/ghostty/." "$HOME/.config/ghostty/"
cp -a "$SRC/.config/sway/nwg-dock/." "$HOME/.config/nwg-dock/"
cp -a "$SRC/.config/mimeapps.list" "$HOME/.config/mimeapps.list"
mv -- "$SRC" "$CLONE_DIR"
chmod +x "$CONFIG_DIR"/scripts/* 2>/dev/null || true
chmod +x "$CONFIG_DIR"/theme/*.sh "$CONFIG_DIR"/theme/*.py 2>/dev/null || true
chmod +x "$CONFIG_DIR"/waybar/lightmode 2>/dev/null || true
say 'Installation complete.'
say "Existing files preserved at: $BACKUP"
if (( ${#FAILED_B[@]} > 0 )); then
    say "Optional packages still missing: ${FAILED_B[*]}"
    say 'Their associated features may not work.'
fi
say 'Log out and back in to load the new configuration. Keep your backup until you have verified the session.'
