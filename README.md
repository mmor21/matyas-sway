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

## Credits

See [CREDITS.md](CREDITS.md).

## License

MIT. See [LICENSE](LICENSE).
