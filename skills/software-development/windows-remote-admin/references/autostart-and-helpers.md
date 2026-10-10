# Autostart Entries: Separating Helpers from Core

When auditing Windows startup, distinguish **helper/service processes** (which can be safely
nonactivated) from **core application installers** (which should not be).

## Pattern: Helper Entry

These are secondary processes — notification handlers, background syncs, tray icons, update
checks, and monitor services — that launch from `Run` registry keys but are NOT the main
application:

**Adobe Suite:**
- `AdobeAAMUpdater-1.0` — update checker; disabling it skips automatic update prompts but
  the application suite still runs. Core app (`Adobe Reader`, `Photoshop`, etc.) unaffected.
- `SwitchBoard` — Adobe CS6 helper that was launched on login. Can be disabled; disables
  only the helper, not the apps.
- `AdobeBridge` — Adobe Creative Cloud shared library utility, often a stale/empty entry
  after uninstall (command field blank = safe to delete).

**Epson Printers:**
- `FUFAXRCV` (`FUFAXRCV.exe`) — FAX Utility receiver daemon, monitors for incoming fax
  notifications. Disabling it stops *notifications* but does NOT break the FAX driver or the
  ability to send faxes through the printer antrean. Printing and faxing over the driver still
  work.
- `FUFAXSTM` (`FUFAXSTM.exe`) — FAX Utility status monitor. Disabling it removes the tray
  icon and status window, but fax device remains operational.

**Photo Library & Media Management:**
- `ACDSeeCommanderUltimate8` — application launcher; disabling autostart means the app
  will not open on logon, but opening it manually from the Start Menu works perfectly.
- `ACUW08EN` (`acdIDInTouch2.exe`) — ACDSee InTouch background sync/listener. Disables
  cloud sync notifications and background features, but the local ACDSee application still
  launches and operates normally when invoked.

**Microsoft Services:**
- `MicrosoftEdgeAutoLaunch_<GUID>` — Edge background auto-start flag. Disabling prevents
  Edge from launching at logon, but clicking Edge still opens it. User perception: "Edge
  no longer slow-starts in the background."

**Logitech/HP:**
- `Logitech Download Assistant` — driver updater for USB Logitech devices. Safe to disable;
  drivers already loaded at boot time, and new hardware detection is manual or deferred.
- `RunPUMonitor` — HP DesignJet Utility background monitor. Disabling the monitor removes
  the tray app, but the printer driver and spooler remain functional.

## Pattern: Core Installer (Do NOT disable)

These should NOT be removed from autostart without explicit evidence that they are unneeded:

- **Antivirus UI / System Protection** (`AvastUI.exe`, Windows Defender helpers) — disabling
  them can create a false sense of protection or leave security gaps.
- **Driver-Level Monitors for Active Hardware** — if a printer, scanner, or device monitor
  is still in the antrean/device list and operational, its monitor service is likely still
  needed for status/alerts.
- **VPN, Disk Encryption, or Hardware Identification** — disabling these autostart entries
  can break security policies or hardware detection.

## Decision Framework

Before disabling a helper from autostart:

1. **Is the main application still installed?** (Check `Program Files`, `Program Files (x86)`,
   and `Get-Package` for the publisher.)
2. **Is the main application still in use?** (Check file modification dates in its AppData
   folders, and ask the user.)
3. **Does the helper do something the user wants, or something only the main application
   needs?**
   - Update notifications → helper is okay to disable if user does manual updates.
   - Tray icon / status window → helper is okay to disable if user does not need real-time
     feedback.
   - Background sync / cloud integration → helper is okay to disable if user does not use
     that feature.
   - Driver monitor for active hardware → helper is necessary if the device is still
     connected/in-use; request proof from the user first.

4. **Make a backup and give the user a restore path.** All `Run` registry keys should be
   exported before deletion so the user can `reg import` if needed.

5. **Set expectations:** The change takes effect at the next logon, not immediately. Running
   instances of the helper do not auto-stop.
