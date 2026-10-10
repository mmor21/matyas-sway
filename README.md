# matyas-sway

A personal Sway desktop configuration for CachyOS Sway Edition.
The installer assumes that base; other Arch-family systems would need
adjustments.

Modular architecture, no monolithic shell, featuring themes, a window
switcher and a dock.

Primary design principle: every tool runs as its own process — killing
one does not affect the others.

## Architecture

### Core

| Component | Role | Notes |
|---|---|---|
| **Sway** | Compositor | Wayland-native, i3-compatible |
| **Waybar** | Status bar | Custom modules and three expanding groups |
| **Rofi** | Launcher and all menus | One `.rasi` per menu |
| **Mako** | Notification daemon | — |
| **Ghostty** | Terminal | — |
| **nwg-dock** | Bottom dock | Resident, toggled with `$alt+X` |
| **swaylock** | Lock screen | Themed via `theme/current.bash` |
| **swayidle** | Idle / lock / dpms | 5-minute lock, 10-minute display-off |
| **swaybg** | Wallpaper | Set through `sway-output` |
| **cliphist** | Clipboard history | Text + images, capped at 25 entries |
| **wl-clipboard** | Clipboard backend | Powers cliphist |
| **NetworkManager** | Network | Managed via our own `rofi_network` |
| **bluetoothctl** | Bluetooth | Managed via our own `rofi_bluetooth` |

### Utilities

| Component | Role | Notes |
|---|---|---|
| **brightnessctl** | Backlight control | `XF86MonBrightness*`, bar module |
| **pamixer** | Volume control | `XF86Audio*`, bar module |
| **polkit-gnome** | Authentication agent | GUI privilege prompts |
| **hyprpicker** | Color picker | `$mod+p` |
| **grim** / **slurp** | Screenshots | Via `scripts/screenshot` |
| **thunar** | File manager | `$files` in the config |
| **mousepad** | Default text editor | `mimeapps.list` |

## Design principles

1. Every action is its own shell script
2. Every tool is its own process (no monolithic shells)
3. Killing any one tool must not affect the session
4. Autostart is idempotent (`pgrep`-guarded)
5. Monitor config is empty by default (Sway auto-detects)
6. Colors are variables, never literals in multiple places
7. Per-tool config directories
8. Attribution lives in one place (`CREDITS.md`)

## Layout

Installed layout, after the installer runs:

    ~/.config/
    ├── sway/
    │   ├── config                master dispatcher
    │   ├── config.d/             user overrides (loaded last)
    │   │   └── matyas.conf       personal bindings and preferences
    │   ├── sway-input            keyboard, touchpad, touchscreen
    │   ├── sway-output           monitors (auto-detect, no hardcoded resolution)
    │   ├── sway-theme            borders, gaps, colors, GTK
    │   ├── sway-idle             idle / lock / dpms
    │   ├── sway-modes            resize / move / gaps / opacity
    │   ├── scripts/              one script per action
    │   ├── waybar/               bar config, modules, css
    │   ├── rofi/                 per-menu .rasi files + shared/colors + shared/fonts
    │   ├── mako/                 notification daemon config
    │   ├── nwg-dock/             dock CSS
    │   └── theme/
    │       ├── theme.sh          theme engine
    │       ├── dark.bash         base16-ocean
    │       ├── light.bash        base16-measured-light
    │       ├── orange.bash       IC Orange PPL
    │       └── current.bash      active palette (generated)
    ├── ghostty/                  terminal config
    ├── nwg-dock/                 dock CSS (nwg-dock's fixed lookup path)
    ├── backgrounds/              wallpapers (empty at install)
    └── mimeapps.list             default applications

The repository mirrors this under `.config/` and `theme/`, plus
`install/` (installer and package list) and `docs/`.

## Keybindings

Keybindings are defined in the Sway config, not in this document:

- `~/.config/sway/config` — base bindings
- `~/.config/sway/config.d/matyas.conf` — personal overrides, loaded last

Anything in `config.d/` wins over the base config.

## Bar

The bar is split into three sections:

**Left:** workspaces (numeric), idle inhibitor, **AV** group
**Center:** clipboard history, clock
**Right:** **Sys** group, **Wi-BT** group, battery, tray, network and
bluetooth status indicators, power

### Expanding groups

Three groups expand on hover, revealing their children. Each child
is an independent module.

**AV** (Audio/Video):
- Backlight — scrollable (brightnessctl)
- Volume — scrollable (pamixer)

**Sys** (System):
- Temperature — CPU temperature
- Memory — RAM usage
- CPU — CPU usage
- Disk — root filesystem usage

**Wi-BT** (Wireless):
- Wi-Fi — opens the network menu
- BT — opens the bluetooth menu

## Menus

All menus are rofi-based, themed through our shared colors and fonts.

| Menu | Trigger | Contents |
|---|---|---|
| Launcher | `$mod+d` | drun + run + filebrowser modes |
| Power | `$mod+x` | Lock / Logout / Suspend / Hibernate / Reboot / Shutdown |
| Screenshot | `$mod+s` | Desktop / Area / Window / 5s / 10s |
| Network | `$mod+n` | Current status, disconnect, available networks, VPN, toggles, edit |
| Bluetooth | `$mod+b` | Pairing mode toggle, device list with status, scan |
| Window switcher | `$alt+Tab` | All windows across workspaces, with icons |
| Clipboard | `Clip` in bar | Last 25 entries (text + image thumbnails) |
| Wallpaper | Theme menu → Change Wallpaper | Thumbnails of images in `~/.config/backgrounds/` |
| Theme | `$mod+Ctrl+t` | Change Wallpaper / Dark / Light / IC Orange PPL |

## Themes

Three palettes ship with the config:

- **Dark** — base16-ocean
- **Light** — base16-measured-light (accessible contrast)
- **IC Orange PPL** — matches the Ghostty theme of the same name

### Switching

Use the theme menu (`$mod+Ctrl+t`). Or from a terminal:

    ~/.config/sway/theme/theme.sh --dark
    ~/.config/sway/theme/theme.sh --light
    ~/.config/sway/theme/theme.sh --orange
    ~/.config/sway/theme/theme.sh --wallpaper /path/to/image.jpg

Colors are variables, not literals. The theme engine (`theme.sh`)
rewrites every themed file at once: Sway borders, Waybar colors, Rofi
shared colors, Mako, Ghostty, the calendar tooltip, GTK settings — then
reloads Sway.

**Wallpaper and palette are independent.** Changing the palette
does not change the wallpaper. Changing the wallpaper does not
change the palette.

## Install

For a fresh CachyOS Sway Edition install.

Before running the script a full system upgrade is recommended
(`sudo pacman -Syu`).

Then install:

    curl -fsSL https://raw.githubusercontent.com/mmor21/matyas-sway/main/install/install.sh | bash

The installer checks that this is a fresh install, shows a summary of
what it will do, asks once, then clones the repo to `~/matyas-sway`,
installs the packages in `install/packages.txt`, and copies the config
into `~/.config/`.

It does not touch `/etc/sway/`, `ly`, or `/usr/share/wayland-sessions/`.

After installing: log out and log back in, and select **Sway** at the
login screen.

### Wallpapers

The installer creates `~/.config/backgrounds/` but leaves it empty.
Drop image files there, then use the theme menu (`$mod+Ctrl+t` →
Change Wallpaper) to pick one.

## Credits

See [CREDITS.md](CREDITS.md).

## License

MIT. See [LICENSE](LICENSE).
