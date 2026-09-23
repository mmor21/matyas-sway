# matyas-sway

A personal Sway desktop configuration for CachyOS (and other Arch-family
distros). Modular architecture, theme-switchable, no monolithic shells.

## Architecture

- **Sway** — the compositor
- **Waybar** — the status bar
- **Rofi** — the application launcher / menus
- **Mako** — the notification daemon
- **Kitty** — the terminal
- **swaylock** / **swayidle** — lock / idle
- **swaybg** — wallpaper

Every tool runs as its own process. Killing one doesn't affect the others.
Colors are variables, not literals — `theme/theme.sh` rewrites every themed
config file at once when a palette is selected.

## Design principles

1. Every action is its own shell script
2. Every tool is its own process (no monolithic shells)
3. Killing any one tool must not affect the session
4. Autostart is idempotent (`pgrep`-guarded)
5. Monitor config is empty by default (Sway auto-detects)
6. Colors are variables, never literals in multiple places
7. Per-tool config directories
8. Attribution lives in one place (`CREDITS.md`)

## Install

Not yet packaged as an installer. To use this config manually:

    git clone https://github.com/mmor21/matyas-sway.git ~/matyas-sway
    # Back up any existing configs, then:
    cp -a ~/matyas-sway/.config/sway  ~/.config/
    cp -a ~/matyas-sway/theme        ~/.config/sway/theme
    chmod +x ~/.config/sway/scripts/*

Then log out and select the **Sway** session.

## Theme switching

    ~/.config/sway/theme/theme.sh --default   # base16-ocean (dark)
    ~/.config/sway/theme/theme.sh --light     # light palette
    ~/.config/sway/theme/theme.sh --pywal     # generate from a random wallpaper

Requires `pywal` for the pywal mode.

## Layout

    .config/sway/
    ├── config                master dispatcher
    ├── sway-input            keyboard, touchpad
    ├── sway-output           monitors (no hardcoded resolution)
    ├── sway-theme            borders, gaps, colors, GTK
    ├── sway-idle             idle / lock / dpms
    ├── sway-modes            resize / move / gaps / opacity
    ├── scripts/              one script per action
    ├── waybar/               bar config, modules, css, lightmode
    ├── rofi/                 launcher, shared colors, .rasi files
    ├── mako/                 notification daemon
    └── kitty/                terminal

    theme/
    ├── theme.sh              theme engine
    ├── default.bash          base16-ocean
    ├── light.bash            light palette
    └── current.bash          active palette (generated)


## Bar and menu design (MVP 1)

The bar and menus ship with **plain text labels** rather than icon
glyphs. This is deliberate — it means no font dependency, no missing
characters, no black boxes. Icons can be reintroduced in later
versions once a text+icon Nerd Font is confirmed working.

### Waybar

- **Workspaces:** numeric labels `1` through `10`
- **Idle inhibitor:** `[on]` / `[off]`
- **Clock:** time + date, hover shows a Monday-first month calendar,
  scroll to move between months
- **Power button:** `⏻` (Unicode power symbol)
- **Right side:** pulseaudio, backlight, network (SSID + click to
  expand transfer stats), bluetooth, battery, tray

### Rofi

- **Launcher (`Super+D`):** drun mode by default, with mode-switcher
  buttons for Apps / Run / Files
- **Power menu (`Super+X`):** vertical list with text labels —
  Lock / Logout / Suspend / Hibernate / Reboot / Shutdown
- **Screenshot menu (`Super+S`):** vertical list —
  Capture Desktop / Capture Area / Capture Window / Capture in 5s /
  Capture in 10s
- **Bluetooth menu (`Super+B`):** device management via rofi
- **Network menu (`Super+N`):** requires `networkmanager-dmenu`
  (AUR) — not installed by default

### Wallpaper behavior

`sway-output` ships with the wallpaper directive **commented out**.
On first run there is no wallpaper — Sway starts cleanly with a
black background.

To enable a wallpaper:

    cp /path/to/image.jpg ~/.config/backgrounds/wallpaper.jpg
    ~/.config/sway/theme/theme.sh --default

The second command writes the wallpaper line into `sway-output`
and reloads Sway. If the wallpaper file is missing, this step is
simply skipped — it will never break the session.

## Credits

See [CREDITS.md](CREDITS.md).

## License

MIT. See [LICENSE](LICENSE).
