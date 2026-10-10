# LAN discovery and verification recipes (Windows targets)

Run from the driving machine, git-bash on Windows unless marked `cmd`.

## Discovery

| Goal | Command |
|---|---|
| Host up? | `ping -4 -n 1 -w 2000 <ip>` — TTL 128 => Windows |
| Name without DNS | `nbtstat -A <ip>` — NetBIOS table; `<20>` entry means file sharing is on |
| Which services are open | `for p in 21 22 80 135 139 445 3389 5900 5985 7681 20128; do (timeout 1 bash -c "echo > /dev/tcp/<ip>/$p" 2>/dev/null && echo "$p OPEN") ; done` |
| Shares already mapped | `cmd /c "net use"` — Status/Local/Remote table; `Unavailable` = host down |
| Stored credentials | `cmd /c "cmdkey /list"` |
| Live neighbours | `arp -a` |
| Local Windows edition | `cmd /c "wmic os get Caption /value"` |

### cmd quoting traps from bash

- Prefer `MSYS2_ARG_CONV_EXCL='*' cmd /c "net use"` when the argument contains a UNC
  path or backslashes.
- `cmd //c` is only converted to `/c` while MSYS path conversion is **on**. Combining
  `MSYS_NO_PATHCONV=1` with `//c` makes cmd start interactively and print just its
  banner and prompt — the command silently does nothing.

## Using a share as the log/feedback channel

If `net use` shows `Y: \\TARGET\d`, then `Y:\` here *is* `D:\` there. That is how the
setup log is read without RDP, and how files are dropped for the user to double-click.
Read it with a plain file read; it grows while the remote script runs.

## SSH verification ladder

1. Port: `timeout 2 bash -c "echo > /dev/tcp/<ip>/22"` → reachable.
2. Banner: `timeout 8 bash -c 'exec 3<>/dev/tcp/<ip>/22; head -1 <&3'` → e.g.
   `SSH-2.0-OpenSSH_for_Windows_8.6` (the Windows built-in server version).
3. Auth: `ssh -v -i <key> -o BatchMode=yes user@<ip> "hostname"`, then read the tail:
   - `Server accepts key` + `Authenticated ... using "publickey"` → key auth works.
   - `Authentications that can continue: publickey,password` then `Permission denied` →
     key not honored: check both `administrators_authorized_keys` (for admin accounts)
     and the per-user file, plus `sshd_config`.
   - `Authenticated ...` followed by `Exit status -1073740791` → the *shell* crashed
     (`0xC0000409`). Fix `DefaultShell`; do not chase authentication.
   - Old Windows servers print `** WARNING: connection is not using a post-quantum key
     exchange algorithm` on every connection — noise, not the problem.
4. A remote command that returns no text but a non-zero exit status is raw data: Windows
   OpenSSH reports the child process status, so a crash code there belongs to the shell,
   not to ssh or the key.

## SFTP on Windows targets

Windows' default `sshd_config` ships without a `Subsystem sftp` line, so an sftp client
prints `Connection closed` even though the server works. Use the shared drive for file
transfer, or add the subsystem line deliberately.

## Interpreter present but crashing

`where powershell` finds the binary yet every invocation exits `-1073740791`
(`0xC0000409`), especially when elevated, usually means a security product injecting the
process or an AppLocker/WDAC policy. Drive that machine with `.bat`/`cmd` and treat the
interpreter as its own maintenance item — never make it a dependency of the setup path.
Once portable `pwsh` runs there, prefer it for everything else: a modern shell that is not
the component under repair.

## Running commands and scripts on the target (cmd)

- **The remote side is cmd, not a POSIX shell.** `... | head -40` inside a remote command
  fails with `'head' is not recognized as an internal or external command`. Filter remotely
  with `findstr` / `dir` / `find`, or leave the pipe out and bound the output locally in bash
  after ssh returns.
- **Prefer a script file to a one-liner for anything multi-step.** Copy the script to the
  shared drive, invoke it by full path with output redirected to a file on that drive
  (`C:\pwsh\pwsh.exe -NoProfile -ExecutionPolicy Bypass -File D:\x.ps1 > D:\x.txt 2>&1`),
  then read that file locally. One-liners through bash → ssh → cmd lose their quoting, and a
  failure inside one leaves nothing behind to read.
- **Never name a helper function after a built-in alias.** A function called `H` resolves to
  the alias for `Get-History`, so every call fails with
  `Cannot bind parameter 'Id'. Cannot convert value ...` while the rest of the script happily
  keeps running — the report looks complete but the section headers are errors. Use a
  distinctive name (`Section`, `Write-Section`).
- Reliable read-only primitives: `sc query <svc> | findstr /i "STATE"`,
  `reg query <key> [/v <value> | /s]`, `where <exe>`, `dir /a /b`, `wmic` (still present on
  22H2 images) for `process call create` and exit-code queries.
