# Project Backlog

Living document. Last updated: 2026-09-26.

Order of work: **MVP 2 → Phase 4 (installer) → MVP 3**.
The installer is deliberately built last, against a frozen config,
so its dependency list doesn't need to be maintained incrementally.

---

## Active — Phase 3.x

Fixes and small enhancements discovered during integration testing.

| ID | Item | Category | Priority |
|----|------|----------|----------|
| 3.1 | Calendar tooltip colors — make `theme.sh` rewrite the literal hex values | Bug | P1 |
| 3.2 | Bind `theme.sh --default`, `--light`, `--pywal` to keybinds | Enhancement | P2 |
| 3.3 | Waybar modules — strip remaining Nerd Font glyphs, replace with text labels | Bug | P2 |

---

## MVP 2

Enhancements and polish, after Phase 3.x closes.

| ID | Item | Priority |
|----|------|----------|
| 2.6 | Overview tool (SOV / exposway / "windows") | High |
| 2.7 | Dock for Sway (nwg-dock, sfwbar, etc.) | High |
| 2.9 | Letter workspace labels (`A B C ... J`) — coupled with 2.6 | High |
| 2.4 | Wallpaper picker menu | Medium-High |
| 2.5 | `pywal` install path (`python-pywal16` AUR / pip / alternative) | Medium-High |
| 2.1 | Waybar modules review (wifi redundancy, `Super+N` network keybind) | Low |
| 2.2 | `Fil...` truncation on launcher mode-switcher button | Low |
| 2.10 | Network + Bluetooth menu styling consistency | Low |

### Recommended MVP 2 sequence

1. **2.6 and 2.7 first** — the big functional additions; new dependencies that must be known before the installer is built
2. **2.4 and 2.5 next** — user-facing features
3. **2.1, 2.2, 2.10 after** — cleanup and polish
4. **2.9 last** — depends on 2.6 landing first

---

## Phase 4 — Installer

Built last, against the frozen config.

- Installer script for CachyOS (Arch-family)
- Package list derived from the finished config
- Config backup before overwrite
- Reversible uninstall path

---

## MVP 3

Post-v1.0 projects.

| ID | Item |
|----|------|
| 3.MVP.1 | Sway → Swirl port assessment |
| 3.MVP.2 | Tumbleweed support (zypper) |
| 3.MVP.3 | Plain Arch support |

---

## Watch-only

Items to monitor; no active work.

| Item | Notes |
|------|-------|
| Bluetooth tray icon reliability | Suspected transient SNI registration issue; not observed since first occurrence |

---

## Recently completed

| Commit | Content |
|--------|---------|
| 3.7 | Personal Waybar tweaks (backlight to left, text labels, fonts) |
| 3.6 | `config.d` override mechanism (`matyas.conf`) |
| 3.5 | README + CREDITS documentation |
| 3.4 | Launcher mode-switcher labels (Apps / Run / Files) |
| 3.3 | Calendar tooltip colors (literal hex, Pango-compatible) |
| 3.2 | Readable menus and bar (workspaces, idle, power, rofi labels) |
| 3.1 | Wallpaper trap fix + placeholder glyph cleanup |

> **Note on historical commit labels:** Commits labelled `2.7` through
> `2.11` were integration-test fixes and should be read as `3.1`
> through `3.5`. Numbering was corrected from `3.6` onward. See
> project discussion for context.

---

## Closed / dropped

Items considered and rejected, with rationale.

| Item | Reason dropped |
|------|----------------|
| Bar height 32 → 34 | Warning is cosmetic; current height fine |
| Icon reintroduction via Nerd Font | Going text-only by design |
| Formal testing documentation (`TESTING.md`) | Conversation is the record |
| `Super+F` single-window view (stacking/tabbed) | Kept as-is; revisit at MVP 3 port |
| Fuzzel as launcher | No dmenu mode; can't replace 10+ rofi modes |
| `hyprlock` / `current_lock` | `swaylock` chosen for theme integration |
| `mpd` module in bar | No media module wanted |
| `custom/spotify` module | Same |
| `sway/mode` module | User knows modal state |
| `sway/window` module | Title visible in window itself |
| `custom/themes` bar module | Theme toggles moved to keybinds (3.2) |
| `custom/lightmode` bar module | Same |
| Feather icons in menus | Replaced with text labels |
| `-no-click-to-exit` removal | Attempt broke menu theme; reverted |

---

## Design principles (reference)

1. Every action is its own shell script
2. Every tool is its own process (no monolithic shells)
3. Killing any one tool must not affect the session
4. Autostart is idempotent (`pgrep`-guarded)
5. Monitor config is empty by default (Sway auto-detects)
6. Colors are variables, never literals in multiple places
7. Per-tool config directories
8. Attribution lives in one place (`CREDITS.md`)
