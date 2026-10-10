---
name: windows-remote-admin
description: "Use when administering a remote Windows PC over the LAN."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [windows]
metadata:
  hermes:
    tags: [windows, ssh, openssh, lan, smb, sysadmin, remote, maintenance]
---

# Remote Windows Administration (LAN, headless)

For Windows PCs the user cannot sit in front of: setup and maintenance over the
network, driven from another Windows machine (git-bash/POSIX-flavored commands unless
marked `cmd`).

## When to Use

- A Windows PC on the LAN needs SSH enabled, maintenance, or diagnosis and nobody is
  sitting at it.
- You must move files or read logs on a machine with no RDP/WinRM open.
- You are handing the user a script to run once at that machine and it must not fail
  silently in a window that closes.

## 1. Establish what access actually exists (always first)

Probe before planning — ports, NetBIOS name, then mapped drives:

- `ping -4 -n 1 -w 2000 <ip>` (TTL 128 => Windows), then `nbtstat -A <ip>` for the
  NetBIOS name when DNS/LLMNR resolution is flaky. A `<20>` entry means file sharing runs.
- Port sweep in one pass:
  `for p in 21 22 80 135 139 445 3389 5900 5985 7681 20128; do (timeout 1 bash -c "echo > /dev/tcp/<ip>/$p" 2>/dev/null && echo "$p OPEN") ; done`
- `cmd /c "net use"` is the fastest way to learn the shares: it names every mapped
  drive and its target, and an `Unavailable` row names a host that is down.
- A shared drive is a two-way channel: files written into it here appear there, and
  files written there are readable here. Use it as the log/feedback channel whenever
  SSH or RDP is not yet open.

Access-path choice: **SSH** for work (text output, key auth, scriptable), **SMB shares**
for files, **RDP** only for GUI/driver/printer dialogs, **WinRM** only on domain-joined
hosts — in a workgroup it needs `TrustedHosts` on the client and a password on every call.

## 2. Enable OpenSSH Server on a headless Windows PC

Deliver one file the user double-clicks at that machine, and log every step to a drive
this machine can read (`D:\<name>.log` on the target shows up as `Y:\<name>.log` here).
Start from `templates/enable-openssh.bat`, set the public key and target name.

Order that works (cmd built-ins only, no PowerShell):
1. `dism /online /add-capability /capabilityname:OpenSSH.Server~~~~0.0.1.0` — pulls the
   payload from Windows Update. **Tell the user up front it takes 2-5 minutes** and that
   the `\r` progress bar repeated in the log is normal; `exit code: 0` is success, `3010`
   means a reboot is pending.
2. `sc config sshd start= auto` (space after `start=`) then `sc start sshd`. The service
   sits at `START_PENDING` for a while — normal. `sc stop` right after gives `FAILED 1052`
   and `sc start` gives `FAILED 1056`; both harmless.
3. Public key into **both** `%ProgramData%\ssh\administrators_authorized_keys` and
   `%USERPROFILE%\.ssh\authorized_keys` — which one is honored depends on whether the
   account is an administrator.
4. Firewall, scoped to the LAN: delete then add
   `netsh advfirewall firewall add rule name="OpenSSH Server (sshd)" dir=in action=allow protocol=TCP localport=22 remoteip=localsubnet`
   (the delete prints `No rules match the specified criteria.` the first time — expected).
5. `DefaultShell` (registry) — only after the pitfall below is satisfied.
6. Verify: port probe, then the SSH banner, then `ssh -v` and read for
   `Server accepts key` + `Authenticated ... using "publickey"`. Only after key login is
   proven, consider disabling password auth in `C:\ProgramData\ssh\sshd_config`.

Handoff: one double-clickable file or one line to paste — the user is standing at that
machine, so do not make them open a shell and type a sequence. Say how long the slow
step takes and what "still running" looks like on screen.

## 3. Pitfalls (each cost real time)

- **Never set `DefaultShell` to PowerShell before proving PowerShell runs on that
  machine.** A crashing shell kills every SSH session: it authenticates, then closes with
  the shell's exit status and zero output, which reads like an auth or config failure.
  Keep the default (cmd.exe) when in doubt. Exit `-1073740791` (`0xC0000409`) in a remote
  command's exit status means the *interpreter* crashed, not that auth failed.
- **An elevated process does not inherit mapped network drives.** A script elevated from
  `Y:\...` cannot see `Y:`. In the non-elevated run, copy it to a local directory
  (`%SystemDrive%\ssh-setup`) and elevate that local copy.
- **Administrators are authenticated only against `administrators_authorized_keys`**;
  their per-user `authorized_keys` is ignored. Lock its ACL with SIDs, not names, so it
  works on localized Windows:
  `icacls <file> /inheritance:r /grant *S-1-5-32-544:F /grant *S-1-5-18:F`.
- **`net view \\host` is a dead end on modern Windows** — System error 1702 ("binding
  handle is invalid") is SMB1-based share enumeration having been removed, not a
  permission problem. Read `net use` for mapped shares instead.
- **Zero output plus no log means the script never ran.** Every remote script echoes a
  step marker and each command's `%errorlevel%` into a log on a readable drive, and the
  interpreter call is redirected (`powershell ... >> "%LOG%" 2>&1`) so a crash cannot
  vanish into a window that closes.
- **Force the copy on every run — never `if not exist` a remote script into place.** A
  skipped overwrite keeps executing a stale or partial copy indefinitely.
- **Write the delivered `.bat` with CRLF line endings.** LF-only batch files mostly work
  but are fragile around labels; normalise before handing it over.
- **Run the handoff file ON the target.** A file double-clicked through a mapped drive
  runs on the local machine instead. Put a computer-name guard near the top
  (`if /i "%COMPUTERNAME%" neq "<TARGET>" goto wrongpc`) so it refuses politely.

- **Recovering from a bad `DefaultShell` cannot be done over SSH** — every session dies
  before it can run anything, so the fix has to happen at that machine: hand over a
  one-double-click `.bat` (or one line) that runs
  `reg delete "HKLM\SOFTWARE\OpenSSH" /v DefaultShell /f` in an elevated cmd.
- **A crash in the elevated context only means something is hooking elevated processes,
  not a corrupt install.** The same `powershell.exe` fail-fast (`0xC0000409`) as
  SYSTEM/elevated while running fine non-elevated (e.g. the `.bat` UAC launcher still
  works) points at a security product or WDAC/AppLocker policy. Keep `cmd.exe` as the SSH
  shell and treat the interpreter as a maintenance item of its own.
- **SFTP is off by default on Windows sshd**: the default `sshd_config` has no
  `Subsystem sftp` line, so `sftp`/`scp` close immediately ("Connection closed") while
  plain SSH works fine. Until the subsystem line is added on that machine, a shared data
  drive is the file channel.
- **Printer port registry key may not exist.** When backing up print configuration with
  `reg export 'HKLM\...\Print\Ports'`, the key may not exist on all systems and the
  command returns error code 1. This is harmless — `PrintBrm.exe -b` has already captured
  the port configuration in its backup file and will restore it fully. Do not treat the
  `reg export` failure as a backup failure.

## When the target's shell / interpreter is broken

Debloated or "Lite" Windows images often ship a Windows PowerShell 5.1 that fail-fasts
(`0xC0000409`, faulting module `ntdll.dll` — the module name is generic and never the
culprit) or exits silently with zero output. Every `powershell -Command` then looks like it
did nothing, and a `.ps1` delivered to that machine runs as a no-op. Diagnose in this
order, all read-only and all over SSH with cmd:

1. Run the **32-bit** engine: `C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -NoProfile -Command "Write-Output X86"`. If it prints and the 64-bit one prints nothing,
   the image is at fault, not your command.
2. Prove where the failure is: `powershell -NoProfile -Command "Get-Date | Out-File D:\x.txt"`
   — no file means the engine never started (a lost-stdout problem would still write it).
3. Diff the two engine folders (`dir /b` on the 64-bit and 32-bit `WindowsPowerShell\v1.0`)
   — a missing engine file shows up immediately.
4. Rule out the hijackers, in this order: IFEO `Debugger` entries for `powershell.exe`,
   `AppInit_DLLs` / `LoadAppInit_DLLs`, `AppCertDlls`, WDAC
   (`C:\Windows\System32\CodeIntegrity\CiPolicies\Active`), AppLocker blocks (event 8004 in
   `Microsoft-Windows-AppLocker/EXE and DLL` — 8001 is only "policy applied").

Do not burn time repairing the inbox engine on a custom image. Deploy portable PowerShell 7
instead — self-contained (its own runtime, so a broken .NET Framework does not matter):

```
# download PowerShell-<ver>-win-x64.zip (~100 MB) on a machine with internet,
# copy it to a drive the target reads, then on the target:
mkdir C:\pwsh
tar -xf D:\pwsh.zip -C C:\pwsh            # tar.exe ships with Windows
C:\pwsh\pwsh.exe -NoProfile -Command "$PSVersionTable.PSVersion.ToString()"
```

Call `C:\pwsh\pwsh.exe` by full path afterwards. **Keep `cmd.exe` as the SSH
`DefaultShell`** — the shell SSH depends on must never be the component you are repairing.

- **Never judge an interpreter run by `if errorlevel`.** `<cmd> & if errorlevel 1 (echo FAIL)`
  reported success for a child that had just logged a fail-fast crash. Use the interpreter's
  own output plus the Application event log; the exit code alone lies here.

## Read-only audit before any change

Default to a read-only pass: measure, report, then let the user pick the change — and offer
the candidates as a short numbered list so a single digit answers. Do not modify the target
until they say go.

Run the audit as a **script on the target**, never as a long ssh one-liner: write the `.ps1`
here, copy it to the shared drive, run it there with its output redirected back onto that
same drive, then read the report locally. Quoting stops being a problem through
bash → ssh → cmd, a long run cannot be truncated, and the evidence stays on disk.

```
cp audit.ps1 /y/audit.ps1
ssh -i <key> -o BatchMode=yes user@<ip> \
  'C:\pwsh\pwsh.exe -NoProfile -ExecutionPolicy Bypass -File D:\audit.ps1 > D:\audit.txt 2>&1'
# then read Y:\audit.txt locally and tell the user where the report lives
```

Start from `scripts/audit-slowness-readonly.ps1` (hardware age, disks + SMART, CPU sampling,
startup/tasks/services, event-log hotspots, NetBT, graphics, login session).

Reading a slowness audit:
- **Sample, do not snapshot.** `Get-Process` `CPU` is cumulative since process start —
difference two reads over ~45 s to rank *current* load. A single read only ranks whatever has
run longest, and `System` always wins it.
- **Check who is logged on and how idle they are** (`query user`): an idle console session
still holding ten browser processes, Teams and updater stubs is the usual cause of "feels
heavy" on a low-thread CPU, and a process list alone does not show it.
- **`Win32_DisplayConfiguration` is a deprecated class and reports a stale mode.** Read the
active mode from `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration\*`
(`PrimSurfSize.cx/cy`, `ActiveSize.cx/cy`). Never tell the user their resolution is wrong
based on that WMI value.
- **`Win32_PerfFormattedData_*` counters can read 0 on trimmed images** (GPU and disk
alike). Zero is not evidence of idleness — fall back to CIM classes plus CPU sampling and
say which numbers you could not measure.
- **Report free space together with drive type** (`Get-PhysicalDisk` `MediaType`): a
nearly-full 10-year-old SATA HDD explains slow file operations that CPU graphs never show.
- **SMART is one read-only command**: `Get-PhysicalDisk | Get-StorageReliabilityCounter`
(Wear, ReadErrorsTotal, PowerOnHours, Temperature) settles "is the disk dying?". Blank
counters on older drives mean *unavailable* — report them that way, not as clean.
- Group error/critical events by provider over a fixed window rather than listing them; a
provider repeating every ~30 s (e.g. NetBT event 4321 — a master-browser conflict with
another host) is background churn worth naming even when it is harmless.

## 4. Clean up autostart entries (startup programs / Run registry)

Autostart entries (registry `Run` keys + scheduled tasks) accumulate over time, especially
after uninstalls that leave stale registry entries. Before removing, back up the registry:

1. Export each key you plan to edit:
   ```
   reg export 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' hklm-run-64.reg /y
   reg export 'HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run' hklm-run-32.reg /y
   reg export 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' hkcu-run.reg /y
   ```
   Store backups on a readable drive so the user can restore if needed.

2. Use `reg delete` to remove each value:
   ```
   reg delete 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' /v EntryName /f
   ```
   Exit code 0 = success; code 1 = entry not found (harmless, already gone).

3. Verify by exporting again and comparing, or by running `Get-ItemProperty` over SSH:
   ```
   (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run').PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }
   ```

4. **Autostart takes effect at the next logon, not immediately.** Running processes that
   were launched by autostart do not auto-stop; you must kill them by hand if the user
   needs the change to take effect now.

5. **Helper/tray utilities (not the main application) are safe to disable.** Examples:
   Adobe updaters, Epson FAX Utility tray monitors (FUFAXRCV/FUFAXSTM), ACDSee InTouch
   sinkronizer (acdIDInTouch2.exe). The main application (Adobe CC, printer driver,
   ACDSee Commander) remains installed and opens on demand. The trade-off: background
   features (notifications, auto-update checks, ambient sync) vanish, but core functionality
   survives.

## 5. Clean up printer queues (duplicate antreans, offline devices)

Printer antrean cleanup (removing duplicates, shedding offline / WSD-residue entries)
requires backing up the full print configuration before deletions, because Windows print
monitor / driver binaries are tied to antreans:

1. **Backup the entire print subsystem** using `PrintBrm` (built-in):
   ```
   C:\Windows\System32\spool\tools\PrintBrm.exe -b -f <output.printerExport>
   ```
   This one file contains all antreans, drivers, ports, and monitors.

2. Also backup the registry as a safety net:
   ```
   reg export 'HKLM\SYSTEM\CurrentControlSet\Control\Print\Printers' reg-printers.reg /y
   reg export 'HKLM\SYSTEM\CurrentControlSet\Control\Print\Monitors' reg-monitors.reg /y
   ```
   (The `Ports` key may not exist on all systems; if `reg export` fails for it, that is
   expected — PrintBrm has already backed up the ports.)

3. Identify candidates for removal via `Get-Printer`, comparing port names to live antreans.
   An antrean is safe to remove if:
   - Its port is identical to another antrean's port (duplicate targeting same printer).
   - Its status is "Offline" and it has been offline for months (no driver/port repair plan).
   - The associated physical printer no longer exists (audited via site visit or
     device-discovery script).

4. Remove antreans by name:
   ```
   Remove-Printer -Name 'Printer Name'
   ```
   Exit = 0; repeat for each candidate.

5. Verify the antrean count and list (`Get-Printer | Sort-Object Name`).

6. **To restore from PrintBrm backup** (in case of accidental damage):
   ```
   C:\Windows\System32\spool\tools\PrintBrm.exe -r -f <backup.printerExport>
   ```
   Choose "Replace" when prompted.

7. **Do not remove antreans that have no proof of being orphaned.** An antrean named
   "SL-D1000 Series (Network)" that shows status Normal and has a live port (e.g. IP
   192.168.1.135) may be an indirect/fallback route to the printer and still in use even
   if logs show no recent print jobs. Audit the user's workflow first.

## Verification discipline

Claim success only from the target's own output: the port probe, the SSH banner, and
`Authenticated ... using "publickey"` in `ssh -v`. `sc start exit code: 0` on a service
still `START_PENDING`, or a log line saying a key was written, is not proof login works.

## Files

- `templates/enable-openssh.bat` — the installer to copy, adjust (public key, target
  name), and hand to the user. Pure cmd, full logging, diagnostics first.
- `references/lan-discovery-and-verification.md` — probe commands, cmd quoting traps,
  running commands/scripts on the target, what each networking/SSH failure mode looks like.
- `references/autostart-and-helpers.md` — decision table for distinguishing helper/tray
  autostart entries (safe to disable) from core application launchers. When to disable
  autostart and when to leave it alone.
- `scripts/audit-slowness-readonly.ps1` — read-only slowness/health audit to drop on a target
  and run over SSH; prints a sectioned report, changes nothing.
