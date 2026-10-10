# Backlog

Open items only. Completed work lives in the git log.

## Open

### Config

- **Bar height.** `waybar/config` declares `"height": 32`, but Waybar's
  modules require a minimum of 42 and Waybar silently uses 42. Either
  raise the configured height to 42 or shrink the glyphs so 32 works.

- **Temperature module path.** `waybar/modules` points the temperature
  module at `/sys/class/hwmon/hwmon5/temp1_input`. The hwmon number is
  not stable across hardware, kernels, or boots. Consider a more robust
  path or a discovery mechanism.

- **Unverified on real hardware.** Backlight, temperature, and the
  network/bluetooth status indicators could not be verified in a VM
  (no backlight device, no thermal zone, no wireless hardware). Confirm
  on the laptop.

- **`nm-connection-editor`.** `rofi_network`'s "Edit Connections…"
  entry launches `nm-connection-editor`, which is not in
  `install/packages.txt`. Either verify it ships with the base, add it
  to category B, or drop the menu entry.

### Installer

- **Edge cases untested.** The installer has been tested end-to-end on
  a fresh VM. Not yet tested: partial mirror failures (the pacman
  transaction aborting mid-download), an existing clone alongside a
  missing config, or non-interactive invocation.

## MVP 3 candidates

Deferred. No commitment, revisit when relevant.

- Sway → Swirl port assessment
- Tumbleweed support (zypper)
- Plain Arch support
