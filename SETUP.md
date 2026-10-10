# M.A.R.A Setup — Sync Hermes Config & Skills Antar 3 PC

**Status:** AAN-PC (PC Toko #1) ✓ Sudah setup

---

## Apa itu M.A.R.A?

M.A.R.A = **Multi-PC Hermes Agent Repository Architeture**

Satu repository GitHub private untuk share:
- **skills/** — workflow & tools Hermes (sama di semua PC)
- **memories/** — persistent notes & user profile (sama di semua PC)
- **config.yaml** — Hermes configuration (opsi: sama atau per-PC)
- **SOUL.md** — personality & guidelines (sama di semua PC)

**Lokal per PC (tidak di-sync):**
- `.env` — API keys, secrets
- `auth.json` — authentication tokens
- `sessions/`, `cache/`, `logs/` — state & temporary files
- Database & lock files

---

## Setup untuk PC Toko #1 (AAN-PC) — SELESAI ✓

1. ✓ Cloned `tikusgot007/M.A.R.A` dari GitHub
2. ✓ Moved ke `C:\Users\AAN\Projects\M.A.R.A`
3. ✓ Symlinked `skills/` dan `memories/` ke Hermes lokal
4. ✓ Backed up `.env`, `auth.json`, `config.yaml` → `.backup-pc1/`

**Struktur sekarang:**
```
C:\Users\AAN\Projects\M.A.R.A/
├── .git/
├── config.yaml
├── SOUL.md
├── skills/           (master copy)
├── memories/         (master copy)
├── .backup-pc1/      (local state backup)
└── [repo files]

C:\Users\AAN\AppData\Local\hermes/
├── skills/           → symlink ke M.A.R.A/skills
├── memories/         → symlink ke M.A.R.A/memories
├── .env              (lokal, tidak di-sync)
├── auth.json         (lokal, tidak di-sync)
└── [hermes files]
```

---

## Setup untuk PC Toko #2 & PC Rumah

### Prerequisites
- GitHub Desktop atau Git CLI sudah install
- Hermes Desktop sudah install
- Akses ke `tikusgot007/M.A.R.A` repo (private)

### Langkah-langkah

**1. Clone M.A.R.A ke Projects folder**
```bash
cd C:\Users\<USERNAME>
mkdir Projects
cd Projects
gh repo clone tikusgot007/M.A.R.A
# atau pakai GitHub Desktop: File > Clone > tikusgot007/M.A.R.A > C:\Users\<USERNAME>\Projects\M.A.R.A
```

**2. Setup Hermes Folder**
```bash
# Buka AppData\Local\hermes
cd C:\Users\<USERNAME>\AppData\Local\hermes

# Remove local skills & memories
rm -r skills
rm -r memories

# Create symlinks ke M.A.R.A
ln -s C:\Users\<USERNAME>\Projects\M.A.R.A\skills skills
ln -s C:\Users\<USERNAME>\Projects\M.A.R.A\memories memories
```

Atau pakai Windows CMD:
```cmd
cd C:\Users\<USERNAME>\AppData\Local\hermes
rmdir /s skills
rmdir /s memories
mklink /d skills C:\Users\<USERNAME>\Projects\M.A.R.A\skills
mklink /d memories C:\Users\<USERNAME>\Projects\M.A.R.A\memories
```

**3. Backup Lokal**
```bash
mkdir C:\Users\<USERNAME>\Projects\M.A.R.A\.backup-pc2
cp C:\Users\<USERNAME>\AppData\Local\hermes\.env .backup-pc2/
cp C:\Users\<USERNAME>\AppData\Local\hermes\auth.json .backup-pc2/
cp C:\Users\<USERNAME>\AppData\Local\hermes\config.yaml .backup-pc2/config.yaml.bak
```

**4. Open Hermes Desktop**
- Hermes akan auto-detect symlinks & load skills/memories dari M.A.R.A
- Verify di Settings > Skills — seharusnya load dari `C:\...\M.A.R.A\skills`

---

## Workflow Harian

### Pull Changes (Sebelum Kerja)
```bash
cd C:\Users\<USERNAME>\Projects\M.A.R.A
git pull origin master
```

**GitHub Desktop:** Klik **Pull origin**

### Commit & Push Changes (Setelah Kerja)
Setiap kali edit skill, memory, atau config:
```bash
cd C:\Users\<USERNAME>\Projects\M.A.R.A
git add -A
git commit -m "Update: [deskripsi singkat]"
git push origin master
```

**GitHub Desktop:**
1. Klik **Fetch origin**
2. Edit & save files
3. Files otomatis muncul di "Changes" tab
4. Type commit message
5. Klik **Commit to master**
6. Klik **Push origin**

### Conflict Resolution
Kalau 2 PC ubah file yang sama:
1. Git akan flag "conflict" saat pull
2. Manual resolve di editor (GitHub Desktop atau VS Code)
3. Pilih versi mana (latest-wins, atau merge manual)
4. Commit & push hasil merge

---

## Important Notes

⚠️ **JANGAN push ke GitHub:**
- `.env` — API keys & secrets (di .gitignore)
- `auth.json` — tokens (di .gitignore)
- Local session/cache files (di .gitignore)
- Per-PC backups di `.backup-pc*`

✓ **BOLEH push:**
- `skills/**` — shared workflows
- `memories/**` — shared notes & profile
- `config.yaml` — shared config (atau backup lokal jika berbeda per-PC)
- `SOUL.md` — personality guidelines

---

## Troubleshooting

### Symlinks tidak bekerja di Windows
Windows memerlukan permission atau pakai `mklink /d` (admin):
```cmd
cd C:\Users\<USERNAME>\AppData\Local\hermes
mklink /d skills C:\Users\<USERNAME>\Projects\M.A.R.A\skills
mklink /d memories C:\Users\<USERNAME>\Projects\M.A.R.A\memories
```

### Pull conflict
```bash
cd C:\Users\<USERNAME>\Projects\M.A.R.A
git status
# Lihat file mana yang conflict
# Edit file, resolve conflict manually
git add [conflict files]
git commit -m "Resolve conflict: [deskripsi]"
git push origin master
```

### Hermes tidak load skills dari symlink
- Restart Hermes Desktop
- Verify symlink: `ls -la C:\Users\<USERNAME>\AppData\Local\hermes\skills`
- Check Hermes logs di `AppData\Local\hermes\logs\`

### Kalau perlu revert ke backup
```bash
cp .backup-pc1/.env C:\Users\<USERNAME>\AppData\Local\hermes\.env
cp .backup-pc1/auth.json C:\Users\<USERNAME>\AppData\Local\hermes\auth.json
```

---

## Checklist Setup (untuk PC baru)

- [ ] Clone M.A.R.A ke `C:\Users\<USERNAME>\Projects\M.A.R.A`
- [ ] Remove lokal `skills/` dan `memories/` folder
- [ ] Create symlink `skills/` → M.A.R.A
- [ ] Create symlink `memories/` → M.A.R.A
- [ ] Backup `.env`, `auth.json`, `config.yaml`
- [ ] Restart Hermes Desktop
- [ ] Verify skills load dari M.A.R.A
- [ ] Test: Pull origin, edit skill, push origin

---

**Last updated:** Oct 10, 2024
**Repo:** `github.com/tikusgot007/M.A.R.A` (private)
