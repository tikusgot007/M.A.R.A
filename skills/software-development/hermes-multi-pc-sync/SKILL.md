---
name: hermes-multi-pc-sync
description: "Sync Hermes config & skills across multiple PCs via Git."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [windows]
metadata:
  hermes:
    tags: [hermes, multi-pc, config, sync, git, windows, skills, memories]
---

# Hermes Multi-PC Sync (Git-based)

When a user has Hermes Desktop on multiple Windows PCs and wants a single source of truth for skills, memories, and config — use Git (GitHub, GitLab, local server) as the master, clone to each PC, and symlink Hermes folders to the repo.

## Architecture

**Master:** Git repository (private, e.g. `github.com/<user>/M.A.R.A`) containing:
- `skills/` — shared Hermes skills (bundled + custom)
- `memories/` — persistent memory and user profile (`MEMORY.md`, `USER.md`)
- `config.yaml` — shared Hermes configuration
- `SOUL.md` — personality guidelines

**Per-PC (lokal, not synced):**
- `.env` — API keys, secrets
- `auth.json` — authentication tokens
- `sessions/`, `cache/`, `logs/` — state and temporary files
- Per-PC backup folder (e.g., `.backup-pc1/`)

**Hermes lokal folder structure:**
```
C:\Users\<USER>\AppData\Local\hermes
├── skills/           → symlink to .../M.A.R.A/skills
├── memories/         → symlink to .../M.A.R.A/memories
├── config.yaml       (copy from M.A.R.A/config.yaml on each pull)
├── SOUL.md           (copy from M.A.R.A/SOUL.md on each pull)
├── .env              (lokal, not synced)
├── auth.json         (lokal, not synced)
└── [other Hermes files]
```

## Workflow

### 1. Setup on First PC (Master)

1. **Clone repo to a sibling folder** (not inside Hermes itself):
   ```bash
   cd C:\Users\<USER>
   mkdir Projects
   cd Projects
   gh repo clone <owner>/<repo-name>   # or git clone https://...
   ```
   Example: `C:\Users\AAN\Projects\M.A.R.A`

2. **Backup lokal Hermes state** (before symlinks):
   ```bash
   mkdir C:\Users\<USER>\Projects\M.A.R.A\.backup-pc1
   cp C:\Users\<USER>\AppData\Local\hermes\.env .backup-pc1/
   cp C:\Users\<USER>\AppData\Local\hermes\auth.json .backup-pc1/
   cp C:\Users\<USER>\AppData\Local\hermes\config.yaml .backup-pc1/config.yaml.bak
   ```

3. **Remove lokal skills & memories folders:**
   ```bash
   rm -rf C:\Users\<USER>\AppData\Local\hermes\skills
   rm -rf C:\Users\<USER>\AppData\Local\hermes\memories
   ```

4. **Create symlinks** (bash with MSYS, or use `mklink /d` in cmd/PowerShell):
   ```bash
   # Bash (git-bash / MSYS):
   ln -s C:\Users\<USER>\Projects\M.A.R.A\skills C:\Users\<USER>\AppData\Local\hermes\skills
   ln -s C:\Users\<USER>\Projects\M.A.R.A\memories C:\Users\<USER>\AppData\Local\hermes\memories
   ```
   Or in cmd (admin):
   ```cmd
   mklink /d C:\Users\<USER>\AppData\Local\hermes\skills C:\Users\<USER>\Projects\M.A.R.A\skills
   mklink /d C:\Users\<USER>\AppData\Local\hermes\memories C:\Users\<USER>\Projects\M.A.R.A\memories
   ```

5. **Copy config files from repo:**
   ```bash
   cp C:\Users\<USER>\Projects\M.A.R.A\config.yaml C:\Users\<USER>\AppData\Local\hermes\config.yaml
   cp C:\Users\<USER>\Projects\M.A.R.A\SOUL.md C:\Users\<USER>\AppData\Local\hermes\SOUL.md
   ```

6. **Restart Hermes Desktop** to load skills & config from symlinks.

7. **Verify:** Settings > Skills — skills should load from `C:\...\M.A.R.A\skills`.

### 2. Setup on Subsequent PCs

Repeat steps 1–7 above, replacing `pc1` with the PC's identifier (e.g., `PC2-TOKO`, `PC-RUMAH`).

Automate with a script: start from `templates/setup-mara-pc.sh` and modify the username / PC name.

### 3. Daily Workflow (Pull & Push)

**Before work (pull latest):**
```bash
cd C:\Users\<USER>\Projects\M.A.R.A
git pull origin master
```
Or via GitHub Desktop: **Pull origin**.

**After work (push changes):**
Every time you create or edit a skill, memory, or config:
```bash
cd C:\Users\<USER>\Projects\M.A.R.A
git add -A
git commit -m "Update: [brief description]"
git push origin master
```
Or via GitHub Desktop:
1. **Fetch origin**
2. Edit & save files (they appear in "Changes" tab)
3. Type commit message
4. **Commit to master**
5. **Push origin**

## Conflict Resolution

When two PCs edit the same file simultaneously:
1. One PC's push succeeds; the other's push is rejected ("your branch is behind").
2. Pull to get the upstream change: `git pull origin master`
3. Git flags the conflict in the file (`<<<<< HEAD` ... `>>>>> origin/master`).
4. Open the file in an editor (VS Code, GitHub Desktop conflict resolver) and choose:
   - **Ours** (keep this PC's version)
   - **Theirs** (accept the other PC's version)
   - **Manual merge** (blend the two)
5. Resolve the conflict, remove the conflict markers.
6. Commit & push: `git add [file] && git commit -m "Resolve conflict: ..." && git push`

**Strategy:** Latest-wins is simplest for auto-generated files (skills pulled from Nous). For hand-edited files (memories, custom config), prefer manual merge or a per-PC conversation with the other operator.

## Pitfalls

- **Do not instruct git add/commit when branch is already ahead.** Check `git status` before guiding the user; if local commits are already staged or unpushed (`Your branch is ahead of 'origin/master' by N commits`), instruct only `git push origin <branch>` to prevent confusion and empty commit errors.

- **Windows PowerShell path and multi-line paste errors.** In standard Windows PowerShell (system32 default), Unix home syntax (`~/`) fails and pasting multi-line blocks often executes subcommands before `cd` completes, resulting in `fatal: not a git repository`. Provide full native paths (`C:\Users\<USER>\...`) and avoid pasting multi-line command stacks; give directory change first or chain commands with `;`.

- **GitHub as master, lokal PC config changes must be ephemeral.** Edit Hermes settings on a PC, but do not commit `config.yaml` per-PC changes to the repo unless all PCs need them. To reset: `git checkout -- config.yaml` in the repo folder, then re-copy to Hermes lokal.

- **Symlinks on Windows require the exact case and path format.** `ln -s` in bash works, but `mklink /d` requires full paths and admin. If symlinks fail, verify:
  - Path exists: `ls -la C:\Users\<USER>\Projects\M.A.R.A\skills`
  - Directory, not file: target must be a folder
  - Admin privileges (for `mklink`)
  - Run from the Hermes folder when creating (or use absolute paths)

- **Never push `.env` or `auth.json` to GitHub.** The `.gitignore` in the repo excludes them by default. Verify: `git status` should not list these files. If they appear, they may already be tracked from an earlier commit — remove them:
  ```bash
  git rm --cached .env auth.json
  git commit -m "Remove secrets from tracking"
  ```
  This does not delete them lokal, only stops tracking.

- **Elevated process does not inherit symlinks or mapped drives.** If a Hermes background task runs elevated (rare), it cannot see skills via symlink. Keep Hermes lokal read/write normal (non-elevated). If elevation is needed elsewhere, copy files to a non-symlinked temp folder first.

- **Restart Hermes after symlink creation or config copy.** Hermes caches the skills list and does not hot-reload symlinks. Close the Hermes app entirely and re-open it.

- **Git on Windows is LF/CRLF sensitive.** Ensure the repo is configured correctly:
  ```bash
  git config core.autocrlf input  # on Windows, keep LF in repo
  ```
  Or set it once in the global config: `git config --global core.autocrlf input`.

- **A stale repo folder still pulling from GitHub is a footgun.** Always verify the repo folder path before pulling. If a PC is set up with the repo in the wrong location (e.g., nested inside another `M.A.R.A` folder), symlinks will point to the wrong place silently. Check:
  ```bash
  ls -la C:\Users\<USER>\AppData\Local\hermes\skills
  # Output should show: skills -> /c/Users/<USER>/Projects/M.A.R.A/skills
  # (the symlink target, not the contents)
  ```

- **Per-PC customization requires discipline.** If PC A's config differs from PC B's intentionally (e.g., different model provider), do not commit the change to the repo; keep it lokal only. The workflow is: pull master config, edit lokal, do not commit. If all PCs need the change, make it in the master repo and pull to all PCs.

## Windows OpenSSH Server Setup (optional, related)

After syncing Hermes across PCs via Git, you may want SSH access to each PC for remote maintenance. See `windows-remote-admin` skill. OpenSSH Server is installed separately from Hermes sync and uses a different transport.

## Files

- `templates/setup-mara-pc.sh` — automated setup script (clone, symlink, backup) for a new PC.
- `references/git-conflict-strategies.md` — decision table for conflict resolution on shared files.
- `references/windows-symlink-troubleshooting.md` — debugging symlinks, mklink vs ln -s, ACL issues.
