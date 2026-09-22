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

See LICENSE for the full MIT text.
