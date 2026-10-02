# CachyOS Sway Edition — Target Base Analysis

Reference notes on what a clean CachyOS Sway edition install contains, captured from a VM on 2026-10-02. Used to scope the installer: what to add, what to leave alone.

Login manager
ly — a TUI-based display manager. Configured at /etc/ly/config.ini.

Reads Wayland sessions from /usr/share/wayland-sessions/

sway.desktop is present (created at install time), Exec=sway, DesktopNames=sway;wlroots

No Sway-specific configuration in ly itself

Login screen lets you pick the session; Sway starts via the session file

Session stdout/stderr goes to ~/.local/state/ly-session.log

Installer implication: ly does not need to be touched. No changes to /usr/share/wayland-sessions/sway.desktop. Our config in ~/.config/sway/ takes precedence over /etc/sway/config automatically.

What ships in the base install
Sway stack
sway, wlroots0.20, swaybg, swayidle, swaylock (via sway package)

waybar — NOT installed

wofi — installed (Wayland launcher, not bound by default)

wmenu — installed, bound as default $menu in /etc/sway/config

foot — installed, bound as default $term

alacritty — installed, but NOT bound in the default config

No kitty, no ghostty

Default /etc/sway/config
Stock Arch/Sway default config, minimally customized

set $term foot

set $menu wmenu-run

bar { } uses the built-in swaybar, not Waybar

include /etc/sway/config.d/* at the end

/etc/sway/config.d/ contains exactly one file: 50-systemd-user.conf

Audio
pipewire, pipewire-pulse, pipewire-audio, wireplumber

pavucontrol installed

pamixer — NOT installed

Network
networkmanager, networkmanager-openvpn, networkmanager-vpn-plugin-openvpn

NetworkManager.service enabled

NetworkManager-dispatcher.service enabled

NetworkManager-wait-online.service enabled

iwd present but NetworkManager is the active manager

wpa_supplicant installed

dnsmasq installed

Bluetooth
bluez, bluez-utils, bluez-libs, bluez-hid2hci, bluez-obex

bluetooth.service enabled

Input / display
libinput, libwacom, libei, seatd

xorg-xwayland (XWayland enabled)

brightnessctl installed

grim, slurp installed

wl-clipboard installed

Portals
xdg-desktop-portal

xdg-desktop-portal-wlr

xdg-desktop-portal-gtk

xdg-user-dirs, xdg-utils

Fonts
noto-fonts, noto-fonts-cjk, noto-fonts-emoji

ttf-dejavu, ttf-liberation, ttf-bitstream-vera

ttf-fantasque-nerd, ttf-meslo-nerd — Nerd Fonts already present

powerline-fonts, awesome-terminal-fonts

Shell
zsh is default (with oh-my-zsh-git, zsh-autosuggestions, zsh-syntax-highlighting, zsh-theme-powerlevel10k, zsh-completions, zsh-history-substring-search)

fish also installed (with fish-autopair, fish-pure-prompt, fisher)

bash is present but not the default

Editors / terminals
nano, nano-syntax-highlighting, micro, vim

vlc (fully installed with all plugins)

CachyOS-specific
limine bootloader + limine-snapper-sync (snapshots tied to bootloader)

cachyos-hello, cachyos-kernel-manager, cachyos-packageinstaller (Shelly)

cachyos-ananicy-rules, ananicy-cpp

scx-scheds, scx-manager (sched_ext)

cachyos-rate-mirrors, rate-mirrors, reflector

cachyos-settings, cachyos-hooks

Other notable
firefox — default browser

thunar — NOT installed

mako — NOT installed

rofi — NOT installed

cliphist — NOT installed

nwg-dock — NOT installed

hyprpicker — NOT installed

polkit-gnome — NOT installed (only polkit itself)

networkmanager-dmenu — NOT installed

spice-vdagent — installed (VM-specific; not present on bare metal)

Systemd services enabled by default
Relevant to our stack:

NetworkManager.service

NetworkManager-dispatcher.service

NetworkManager-wait-online.service

bluetooth.service

avahi-daemon.service

avahi-daemon.socket

ufw.service

systemd-resolved.service

Non-stack but present:

ananicy-cpp.service

limine-snapper-sync.service

cachyos-rate-mirrors.timer

snapper-cleanup.timer

fstrim.timer

systemd-oomd.service

cachyos-iw-set-regdomain.path

Not present as system services:

No pipewire.service (it's user-level, not system-level)

No graphical login manager service (ly starts before graphical target)

What the installer must provide
Packages not present in the base install that our config needs:

waybar — status bar

rofi — launcher and menus

mako — notification daemon

nwg-dock — bottom dock

cliphist — clipboard history

ghostty — terminal

pamixer — volume control (used by scripts/volume)

polkit-gnome — polkit authentication agent

hyprpicker — color picker

thunar — file manager

mousepad — default text editor (mimeapps.list)

feather-font — for rofi power menu icons (source install)

bc — used by some scripts; verify not present

jq — already present, no action

python — already present, no action

Config locations outside ~/.config/sway/:

~/.config/ghostty/ (from repo .config/ghostty/)

~/.config/nwg-dock/ (from repo .config/sway/nwg-dock/)

~/.config/networkmanager-dmenu/ (unused now, no install needed)

~/.config/mimeapps.list (from repo .config/mimeapps.list)

What the installer must NOT touch
ly and its config

/usr/share/wayland-sessions/sway.desktop

/etc/sway/config and /etc/sway/config.d/*

System-wide package selection for tools CachyOS ships (sway, foot, wofi, wmenu, firefox, vlc, etc.)

Notes
wmenu and wofi are the base launchers. If both remain installed after our config lands, they don't interfere (nothing in our config invokes them), but they can be removed for cleanliness if desired.

foot remains the base terminal. Our config overrides this by using ghostty, but foot stays installed. Leaving it is harmless.

alacritty is installed but unbound. Same situation — harmless.

Verification date
2026-10-02, captured from a fresh CachyOS Sway edition VM. Package list and defaults may drift with future CachyOS releases.