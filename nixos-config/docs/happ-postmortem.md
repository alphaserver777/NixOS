# Happ Postmortem

## Summary

`Happ` was removed from this NixOS configuration because the system integration layer was made to work, but the desktop UI remained broken on Linux in a way that did not look fixable from packaging alone.

The failure point was not TUN, not `happd`, and not `polkit`. Those parts were brought to a working state. The blocking issue was the upstream Qt/QML GUI: it launched, but the connection UI rendered incorrectly and key dialogs were unavailable.

## What Worked

- The package was unpacked and made runnable on NixOS.
- `happd` was installed as a real system service and started successfully.
- `polkit` actions were installed and registered correctly.
- TUN startup via the daemon worked.
- The app could start without the original daemon-start error.
- The stale single-instance lock issue was identified and handled.

Example of the working lower layer:

- `happd.service` started and stayed active.
- `sing-box` TUN startup succeeded.
- The log showed `Tunnel interface created successfully`.

## What Did Not Work

The GUI remained broken. The relevant runtime errors were consistently:

- `Cannot assign to non-existent property "iconName"`
- `Cannot assign to non-existent property "onButtonClicked"`
- `Cannot assign to non-existent property "isDark"`
- `Type StartDialog unavailable`

Those errors blocked the normal connection/import flow in the desktop interface.

## What Was Tried

### 1. Basic Debian package repackaging

The `.deb` was unpacked into a custom derivation.

Result:

- The app binary launched.
- Privileged helper/service parts still did not fit NixOS.

### 2. Full NixOS integration

A dedicated system module was added for:

- `happd.service`
- `polkit` policy files
- compatibility links in `/opt/happ` and `/usr/local/bin`

Result:

- fixed the original daemon/service errors
- fixed `polkit` visibility
- fixed privileged TUN startup

### 3. TUN/routing fixes

`sing-box` wrapper logic was added to rewrite the hardcoded TUN subnet because it collided with a Docker-style local range on this machine.

Result:

- TUN creation succeeded
- this was not the cause of the broken UI

### 4. Crash mitigation

The app sometimes crashed or failed to relaunch because of:

- stale lock files in `/tmp` and `/dev/shm`
- Qt style stack issues in the desktop session

Result:

- stale lock cleanup helped relaunch reliability
- a minimal Qt style workaround reduced crashes
- but the visual/UI defect remained

### 5. Qt environment isolation

The wrapper was changed to isolate `Happ` from session-wide Qt variables coming from Home Manager and desktop theming:

- `QT_PLUGIN_PATH`
- `QML2_IMPORT_PATH`
- `QT_QPA_PLATFORMTHEME`
- `QT_STYLE_OVERRIDE`
- related `QT_*` / `QML_*` variables

Why:

- `Happ` ships its own Qt
- the desktop session exported `qt6ct` / `kvantum` plugin paths from a different Qt build
- traces showed plugin version mismatch between bundled Qt and system Qt

Result:

- the environment became cleaner
- but the same QML UI errors remained

### 6. Version check against newer upstream release

The package was also tested against upstream `Happ 2.5.2` released on March 13, 2026.

Result:

- the same UI/QML errors remained
- so the newer upstream Linux build did not solve this configuration's GUI issue

## Likely Root Cause

The most likely root cause is an upstream Linux GUI/runtime issue in `Happ` itself, specifically around its Qt/QML resource loading or Linux desktop runtime assumptions.

Why this conclusion was reached:

- the service layer was working
- the privilege layer was working
- TUN startup was working
- the same GUI failure reproduced even after isolating the app from local Qt theme/plugin contamination
- the same GUI failure reproduced on a newer upstream release

In short:

- the NixOS-specific integration problems were mostly solvable
- the remaining blocker was the upstream desktop UI behavior

## Final State

`Happ` was removed from this repository to return the configuration to a clean and maintainable state.

If it is revisited later, the next sensible approaches would be:

- test the upstream Arch package instead of the `.deb`
- try a tightly controlled FHS runtime
- or build/run from upstream source if they publish a Linux desktop build path that matches the shipped binaries
