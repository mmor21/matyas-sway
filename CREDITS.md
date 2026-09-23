# Credits

This configuration is based on the architecture and initial design of
**Archcraft's Sway edition** by Aditya Shakya <adi1090x@gmail.com>.

The original is licensed under the MIT License.

## Parts retained from Archcraft

- The overall file structure (master config + include fragments,
  scripts-per-action pattern)
- The `startup` / `statusbar` / `notifications` helper function pattern
- The `theme.sh` self-modifying theming engine concept
- Several script structures (screenshot, lockscreen, rofi_* mode scripts)
- The rofi `.rasi` theme structure

## Third-party code

The script `scripts/rofi_bluetooth` is adapted from
**Nick Clyde (clydedroid)'s bluetooth menu**, which in turn credits:

- firecat53 (networkmanager-dmenu)
- x70b1 (polybar-scripts bluetooth module)

## Parts rewritten or replaced

- All per-file copyright headers (removed)
- Bar layout and module selection
- Theme palettes and wallpapers
- Fonts and icon themes
- Wallpaper paths and machine-specific settings
- Package targets (light -> brightnessctl, pulsemixer -> pamixer)

### Bar (Waybar)

- Workspaces: original Nerd Font glyph icons replaced with plain
  numeric labels (`1` through `10`) — no font dependency, always
  readable
- Idle inhibitor: original placeholder glyphs replaced with text
  labels `[on]` / `[off]`
- Custom power button: original glyph replaced with the Unicode
  power symbol `⏻`
- Clock calendar tooltip: original format strings used CSS variables
  (`@foreground`, `@cyan`, etc.) that Pango does not understand and
  rendered as a solid black block — replaced with literal hex colors

### Rofi menus

- Power menu (`rofi/powermenu.rasi`): original 6-tile horizontal
  icon layout replaced with a vertical list of text labels
  (Lock / Logout / Suspend / Hibernate / Reboot / Shutdown).
  Original `element-text` used `font: "feather 20"` — an icon-only
  font that cannot render text — replaced with a text font.
- Screenshot menu (`rofi/screenshot.rasi`): same restructure.
  Vertical list with text labels
  (Capture Desktop / Capture Area / Capture Window /
  Capture in 5s / Capture in 10s)
- Launcher (`rofi/launcher.rasi`): mode-switcher buttons had empty
  `display-drun`, `display-run`, `display-filebrowser` values —
  populated with text labels (`Apps` / `Run` / `Files`)
- All rofi scripts: placeholder glyph characters that had been
  stripped during cleanup were replaced with plain text labels

### Sway output

- Wallpaper directive (`output * bg ...`) is now commented out by
  default. It is written in by `theme.sh` when a wallpaper is first
  applied. This prevents a fresh clone from failing to load the
  entire Sway config when the wallpaper file is missing.

See LICENSE for the full MIT text.
