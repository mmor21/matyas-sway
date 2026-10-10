# matyas-sway

A personal Sway desktop configuration for CachyOS and other Arch-family
distributions. Modular architecture, theme-switchable, no monolithic
shells. Every tool runs as its own process — killing one does not
affect the others.

## Architecture

| Component | Role | Notes |
|---|---|---|
| **Sway** | Compositor | Wayland-native, i3-compatible |
| **Waybar** | Status bar | Custom modules and three expanding groups |
| **Rofi** | Launcher and all menus | One `.rasi` per menu |
| **Mako** | Notification daemon | — |
| **Kitty** | Terminal | Ghostty migration pending |
| **nwg-dock** | Bottom dock | Resident, toggled with `$mod+Alt+X` |
| **swaylock** | Lock screen | Themed via `theme/current.bash` |
| **swayidle** | Idle / lock / dpms | 5-minute lock, 10-minute display-off |
| **swaybg** | Wallpaper | Set through `sway-output` |
| **cliphist** | Clipboard history | Text + images, capped at 25 entries |
| **NetworkManager** | Network | Managed via our own `rofi_network` |
| **bluetoothctl** | Bluetooth | Managed via our own `rofi_bluetooth` |

Colors are variables, not literals. `theme/theme.sh` rewrites every
themed config file at once when a palette is selected.

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

    .config/sway/
    ├── config                master dispatcher
    ├── config.d/             user overrides (loaded last)
    │   └── matyas.conf       personal bindings and preferences
    ├── sway-input            keyboard, touchpad, touchscreen
    ├── sway-output           monitors (auto-detect, no hardcoded resolution)
    ├── sway-theme            borders, gaps, colors, GTK
    ├── sway-idle             idle / lock / dpms
    ├── sway-modes            resize / move / gaps / opacity
    ├── scripts/              one script per action
    ├── waybar/               bar config, modules, css
    ├── rofi/                 per-menu .rasi files + shared/colors + shared/fonts
    ├── mako/                 notification daemon + icons
    ├── kitty/                terminal
    └── nwg-dock/             dock CSS

    theme/
    ├── theme.sh              theme engine
    ├── dark.bash             base16-ocean
    ├── light.bash            base16-measured-light
    ├── orange.bash           IC Orange PPL
    └── current.bash          active palette (generated)

## Keybindings

`$mod` = Super.

### Applications

| Binding | Action |
|---|---|
| `$mod+Return` | Ghostty |
| `$mod+Shift+Return` | Kitty floating |
| `$mod+$alt+Return` | Kitty fullscreen |
| `$mod+d` / `$alt+F1` | Rofi launcher |
| `$alt+F2` | Rofi runner |
| `$mod+Shift+w` | Browser |
| `$mod+p` | Color picker |
| `$mod+q` / `$mod+c` | Kill focused window |

### Menus and dialogs

| Binding | Action |
|---|---|
| `$mod+x` | Power menu |
| `$mod+s` | Screenshot menu |
| `$mod+n` | Network menu |
| `$mod+b` | Bluetooth menu |
| `$alt+Tab` | Window switcher |
| `$mod+Ctrl+t` | Theme menu |
| `$alt+Space` | Launcher (alternative) |
| `$mod+Shift+v` | Clipboard history (base config) |

### System

| Binding | Action |
|---|---|
| `$alt+X` | Toggle dock |
| `$alt+Control+l` | Lock screen |
| `$mod+Shift+c` | Reload config |
| `$mod+Shift+q` | Exit Sway |
| `XF86MonBrightnessUp/Down` | Brightness |
| `XF86AudioRaiseVolume/LowerVolume/Mute/MicMute` | Volume |
| `Print` / `$alt+Print` / `Shift+Print` / `Control+Print` / `$mod+Print` | Screenshots (now / in 5s / in 10s / window / area) |

### Window management

| Binding | Action |
|---|---|
| `$mod+f` | Toggle single-window view (stacking) |
| `$mod+Shift+f` | True fullscreen |
| `$mod+space` | Toggle floating |
| `$mod+h` / `$mod+v` / `$mod+g` | Split horizontal / vertical / toggle |
| `$mod+Shift+s/t/d/l` | Layout stacking / tabbed / default / cycling |
| `$mod+Shift+v` | Layout horizontal/vertical toggle |
| `$mod+arrow` | Focus direction |
| `$mod+Shift+arrow` | Move window |
| `$mod+$alt+arrow` | Resize |
| `$mod+a` / `$mod+z` | Focus parent / child |
| `$mod+o` | Sticky toggle |
| `$mod+y` | Border toggle |
| `$mod+minus` / `$mod+Shift+minus` | Scratchpad move / show |

### Workspaces

| Binding | Action |
|---|---|
| `$mod+1..0` | Switch to workspace |
| `$mod+Shift+1..0` | Move window to workspace |

### Modes

| Binding | Action |
|---|---|
| `$mod+r` | Resize mode |
| `$mod+Shift+r` | Resize mode (alternative) |
| `$mod+Shift+g` | Gaps mode |
| `$mod+Shift+o` | Opacity mode |

## Bar

The bar is split into three sections:

**Left:** workspaces (numeric), idle inhibitor, **AV** group
**Center:** clipboard history, clock
**Right:** **Sys** group, **Wi-BT** group, battery, tray, power

### Expanding groups

Three groups expand on hover, revealing their children. Each child
is an independent module with its own color and behavior.

**AV** (Audio/Video):
- Backlight — scrollable (brightnessctl), yellow
- Volume — scrollable (pamixer), magenta

**Sys** (System):
- Temperature — CPU temp via hwmon (k10temp), teal-adjacent
- Memory — RAM %
- CPU — CPU %
- Disk — root filesystem %

**Wi-BT** (Wireless):
- Wi-Fi — opens the network menu, yellow
- BT — opens the bluetooth menu, magenta

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

Four palettes ship with the config:

- **Dark** — base16-ocean
- **Light** — base16-measured-light (accessible contrast)
- **IC Orange PPL** — matches the Ghostty theme of the same name
- **Wallpaper** — independent of palette; selectable separately

### Switching

Use the theme menu (`$mod+Ctrl+t`). Or from a terminal:

    ~/.config/sway/theme/theme.sh --dark
    ~/.config/sway/theme/theme.sh --light
    ~/.config/sway/theme/theme.sh --orange
    ~/.config/sway/theme/theme.sh --wallpaper /path/to/image.jpg

The theme engine (`theme.sh`) rewrites every themed file at once:
Sway borders, Waybar colors, Rofi shared colors, Mako, Kitty,
the calendar tooltip, GTK settings — then reloads Sway.

**Wallpaper and palette are independent.** Changing the palette
does not change the wallpaper. Changing the wallpaper does not
change the palette.

## Install

For a fresh CachyOS Sway Edition install.

**Before you install:** run a full system upgrade.

    sudo pacman -Syu

Recommended on a clean install. Freshly-installed apps can fail to
launch if the base system's libraries are out of date — for example,
ghostty will not start if libadwaita and gtk4 are out of sync.

**Then install:**

    curl -fsSL https://raw.githubusercontent.com/mmor21/matyas-sway/main/install/install.sh | bash

The installer checks that this is a fresh install, shows a summary of
what it will do, asks once, then clones the repo to `~/matyas-sway`,
installs the packages in `install/packages.txt`, and copies the config
into `~/.config/`.

It creates `~/.config/backgrounds/` (empty — add your wallpapers) and
does not touch `/etc/sway/`, `ly`, or `/usr/share/wayland-sessions/`.

**After installing:** log out and log back in, and select **Sway** at
the login screen.

### Wallpapers

The installer creates `~/.config/backgrounds/` but leaves it empty.
Drop image files there, then use the theme menu (`$mod+Ctrl+t` →
Change Wallpaper) to pick one.

## Known limitations

- **Ghostty migration pending.** Kitty is still the base terminal;
  Ghostty is bound via `matyas.conf` but the base config has not
  been migrated yet. Planned just before the installer phase.
- **Network and Bluetooth editors use GTK apps.** Advanced editing
  (IP, DNS, MAC, VPN settings) opens `nm-connection-editor` or
  similar. A rofi-based editor is a possible MVP 3 project.
- **No Nerd Font.** The bar and menus use plain text labels to
  avoid font dependencies. Icons may be introduced later if needed.
- **Pywal is not supported.** It was evaluated and rejected —
  pywal regenerates the same palette from the same wallpaper, so
  it does not fit the workflow of "keep wallpaper, switch palette."

## Credits

See [CREDITS.md](CREDITS.md).

## License

MIT. See [LICENSE](LICENSE).
