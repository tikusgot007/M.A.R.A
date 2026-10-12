# MEMORY.md

Memory konteks kerja. Update setiap ada fakta/keputusan baru.

## User
- Sebutan: AAN. Bahasa: Indonesia.

## Repo
### AuliaPos — `tikusgot007/AuliaPos` (public) — lokal `D:\02\repos\AuliaPos`
- POS (Point of Sale) / Aulia Kasir. **CodeIgniter 4**, PHP `^8.2`.
- Modul: transaksi, kasir, produk, pelanggan, jadwal, pembayaran, laporan kas.
- Punya fitur **WhatsApp Shared Inbox** (DB terpisah `aulia_inboxdb`).
- Dependensi: `dompdf/dompdf` (PDF), `mike42/escpos-php` (printer struk). Dev: PHPUnit 10.
- Struktur `app/`: Commands, Config, Controllers, Database, Filters, Helpers, Language, Libraries, Models, Services, ThirdParty, Views.
- DB utama: `aulia_kasirdb` (MySQL/MariaDB, MySQLi). DB inbox: `aulia_inboxdb`.
- Aturan ketat di `AGENTS.md` (spec-first, approval gate sebelum ubah kode, YAGNI, minimum diff).
- Backlog terpusat: `docs/TODO.md` (wajib dibaca awal sesi). Changelog: `docs/CHANGELOG.md`.
- Docs: `docs/sesi/`, `docs/design/`, `docs/requirements/`, `docs/deploy.md`.
- `.kilo/`: `rules/sdlc.md` + agent `sdlc-requirements`, `sdlc-reviewer`, `sdlc-qa`.

### WA-Gateway — `tikusgot007/WA-Gateway` (public) — lokal `D:\02\repos\WA-Gateway`
- Package: `evolution-gateway`, **Node.js** (`>=20`), CommonJS. Deps: express, better-sqlite3, pino, dotenv.
- Fungsi: adapter yang menghubungkan AuliaPos ke WhatsApp lewat **Evolution API** (open-source, self-hosted), **mempertahankan kontrak HTTP "WA-Gateway"** → kode AuliaPos tidak perlu diubah.
- Mesin durability di-reuse dari spike `spike/fonnte`: buffer SQLite, retry, dead-letter, idempotensi `operation_id`, heartbeat.
- Backend WA: Evolution API (mode `WHATSAPP-BAILEYS`, unofficial → risiko ban tetap ada).

### AuliaPrompter — `tikusgot007/AuliaPrompter` (public). Belum dipelajari.

## Kontrak AuliaPos <-> WA-Gateway (tidak berubah)
- AuliaPos → adapter: `POST /send`, `/send-media`, `/media/download` (Bearer = `inbox.gatewayToken`).
- Adapter → AuliaPos: `POST /api/inbox/gateway/messages`, `/api/inbox/gateway/status` (heartbeat).
- Evolution → adapter: webhook `POST /evolution/webhook`.
- Adapter → Evolution: `POST /message/sendText|sendMedia|sendSticker/{instance}` (header `apikey`).
- Perubahan menyentuh kontrak ini = **cross-repository**, butuh approval eksplisit.

## Infra / deployment
- AuliaPos jalan di host **`server-aulia2`**.
- WA-Gateway: **dulu di `aulia3`** (dijalankan lewat **Windows Task Scheduler**), **sekarang pindah ke `aulia7`** dengan **Windows Service**.
  - Jadi docs lama yang menyebut `aulia3` (`\\aulia3\D\kilo\logs`) sudah **usang** untuk gateway.
  - Path lama `C:\Projects\evolution-gateway` juga perlu dianggap usang sampai dikonfirmasi lokasi baru di aulia7.
- Config gateway (.env): `CI4_BASE_URL`, `CI4_GATEWAY_TOKEN`, `EVOLUTION_BASE_URL` (default `127.0.0.1:8080`), `EVOLUTION_API_KEY`, `EVOLUTION_INSTANCE`; adapter listen `PORT=3000`.
- Evolution API butuh **PostgreSQL** (v2.3.7 pakai raw SQL PostgreSQL); MariaDB/MySQL gagal → pesan masuk hilang.
- **Cek akses dari PC ini (2026-10-12)**: `aulia7` **hidup di LAN** (ping OK). WinRM **port 5985 terbuka**, `Test-WSMan` OK, `TrustedHosts = aulia7`, tapi `Invoke-Command` **Access denied** → sesi butuh **kredensial akun aulia7**. Belum ada cara masuk yang bisa dipakai dari sini.
- Kebijakan: **jangan simpan kredensial aulia7** di repo/`MEMORY.md`.

### Lingkungan aulia7 (hasil discovery 2026-10-12, via WinRM `aulia7\ops` admin)
- Windows 11 Pro. Disk: C: free ~93 GB / 237 GB, D: free ~319 GB / 465 GB.
- Node **v22.23.2**, npm 10.9.8, git 2.47. **Tidak ada** Python/uv/pwsh/winget/choco/scoop.
- Service jalan: `AuliaPosGatewayAdapter`, `AuliaPosGatewayEvolution` (Evolution API), `postgresql-aulia7` (Auto). Gateway terpasang di **`C:\AuliaPosGateway\`** (service .exe di `C:\AuliaPosGateway\services\`).
- Internet OK (Telegram reachable 200). Tidak ada folder M.A.R.A.
- Implikasi: M.A.R.A lebih praktis dibangun dengan **Node.js** di aulia7 (tidak perlu Python), kecuali mau pasang Python untuk Hermes asli.
- Catatan: `aulia_inboxdb` ada di sisi AuliaPos (`server-aulia2`), **bukan** di aulia7 → M.A.R.A perlu akses jaringan ke DB/API AuliaPos.

### Keputusan pemasangan (2026-10-12)
- User memilih **pasang Hermes Agent asli di aulia7** sebagai fondasi M.A.R.A (bukan bikin scaffold Node). Butuh install Python dulu (aulia7 belum ada).
- **Sumber & cara pasang Hermes**: repo `github.com/NousResearch/hermes-agent` (MIT). Windows: `iex (irm https://hermes-agent.nousresearch.com/install.ps1)` — installer menarik Python 3.14 + Node + ripgrep + FFmpeg via PM, pasang ke `%LOCALAPPDATA%\hermes` (di aulia7 = `C:\Users\ops\AppData\Local\hermes`).
- Helper setup alternatif: `setup-hermes.ps1` (stage uv pinned → bootstrap Python → pm install).
- Provider LLM didukung banyak (Fireworks, OpenRouter, Gemini, GLM/z.ai, Kimi, dll) diatur via `.env` + `~/.hermes/config.yaml`. Messaging via `TELEGRAM_BOT_TOKEN` dll.
- Rencana v0: install → exclusion AV (riwayat Avast karantina `uv.exe`) → `hermes setup` → bot Telegram M.A.R.A → uji → auto-start Task Scheduler `AuliaMARA`. **Butuh**: API key provider + token bot Telegram baru.
- **Kendala akses fisik**: aulia7 di lantai berbeda → semua langkah **harus remote** (WinRM dari PC ini). Konfigurasi lewat **file** (`config.yaml` + `.env`), bukan TUI interaktif; proses hidup via Task Scheduler.

### Status pemasangan Hermes di aulia7 (2026-10-12)
- **SUKSES**: Hermes Agent **v0.21.7** di `C:\Users\ops\AppData\Local\hermes` (`bin\hermes.exe`, `config.yaml`, `.env`, `skills`, `memories`, `SOUL.md`). Python 3.14.7, uv 0.12.3, node, npm, ffmpeg, ripgrep terpasang.
- Dijalankan via Scheduled Task `MARA-HermesInstall` + log `C:\Users\ops\hermes-install.log` (installer online ~15 menit).
- **Catatan**: langkah akhir installer `hermes setup` (TUI) gagal `NoConsoleScreenBufferError` karena dijalankan tanpa konsol. → Konfigurasi harus via file, bukan TUI.
- Belum dikonfigurasi: provider/model LLM, `TELEGRAM_BOT_TOKEN`, allowlist user. Belum ada gateway jalan, belum auto-start.
- Sisa: (1) isi `.env`/`config.yaml`, (2) jalankan gateway headless, (3) auto-start Task Scheduler `AuliaMARA`.
- **Provider AI M.A.R.A**: **Google Gemini** (AI Studio). Butuh `GEMINI_API_KEY`/`GOOGLE_API_KEY`.

### M.A.R.A v0 JALAN di aulia7 (2026-10-12)
- Provider Hermes = **gemini** (plugin `plugins/model-providers/gemini`, alias google/google-ai-studio; env `GEMINI_API_KEY`/`GOOGLE_API_KEY`; base_url `https://generativelanguage.googleapis.com/v1beta`).
- Model default = **`gemini-3.6-flash`** (konteks 1.048.576 token).
- `.env` di aulia7 (`C:\Users\ops\AppData\Local\hermes\.env`) berisi `GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN` (bot baru khusus M.A.R.A), `TELEGRAM_ALLOWED_USERS`.
- **Uji model** (headless): `hermes chat -q "..." --oneshot -Q` → balas `HALO-MARA-OK`. ✅
- **Uji kirim Telegram**: `hermes send -t telegram:<uid> "..."` → `sent`. ✅
- **Gateway Telegram**: jalan mode polling, log `✓ telegram connected`, `Gateway running with 1 platform(s)`. ✅
- **Persistensi**: Scheduled Task **`Hermes_Gateway`**, LogonType=**Password** (jalan tanpa perlu login ops), trigger **At startup + At logon**, RestartCount 999. Proses gateway = `python.exe` dari `C:\Users\ops\AppData\Local\hermes\tools\`.
  - Catatan: `hermes gateway install` default bikin LogonType=Interactive → tidak hidup tanpa sesi login; sudah diganti manual.
  - Warning kosmetik: task "predates current template (missing LogonTrigger Delay, v1.3 vs 1.4)".
- **Belum**: isi `memories/`/`skills/` M.A.R.A, akses read-only `aulia_inboxdb`, loop belajar via Telegram, dsb (lihat `ideas/mara-cara-membangun.md`).
- Rahasia tidak ditulis ke repo. File `aulia7.secrets.txt` (Gemini key + token bot) sudah **dihapus** setelah dipakai.

### Akses web (opsi, belum dipasang)
- Hermes punya **web dashboard**: `hermes dashboard --port 9119 --host <HOST>` (default host `127.0.0.1`; ada `--status`, `--stop`, `--skip-build`, `register` untuk OAuth Portal).
- Bind non-loopback **wajib auth** (password atau OAuth); `--insecure` sudah no-op.
- IP aulia7 = **192.168.1.68** (Ethernet).

### Web dashboard M.A.R.A (JALAN, 2026-10-12)
- URL dari LAN: **http://192.168.1.68:9119** (halaman "Sign in — Hermes Agent", HTTP 200 dari PC AAN).
- Username: **`aan`**. Password: ditetapkan AAN (hash scrypt di `dashboard.basic_auth.password_hash`; **plaintext sengaja TIDAK disimpan di repo**). File `aulia7.webpass.txt` sudah dihapus.
- **Insiden 2026-10-12**: login gagal karena isi file password berbeda dari yang diketik (log `dashboard-auth.log` → `invalid_credentials`). Diverifikasi ulang lewat POST `/auth/password-login` (butuh field `provider`,`username`,`password`) → 200 OK.
- Log auth: `C:\Users\ops\AppData\Local\hermes\logs\dashboard-auth.log`.
- Auth = plugin `plugins/dashboard_auth/basic` (`dashboard.basic_auth.{username,password_hash|password,secret,session_ttl_seconds}` atau env `HERMES_DASHBOARD_BASIC_AUTH_*`).
- UI dibangun: `hermes-agent\web` → `npm run build` → `hermes_cli\web_dist`.
- Persistensi: Scheduled Task **`MARA_Dashboard`** (`hermes dashboard --host 192.168.1.68 --port 9119 --skip-build --no-open`), LogonType Password, trigger boot+logon, restart 999.
- Firewall: rule **`MARA Dashboard 9119`** (TCP 9119 inbound, profil Domain+Private).
- Catatan: bind non-loopback wajib auth; `--insecure` no-op. Hash dihitung dengan venv Hermes (`installs\...\venv\Scripts\python.exe`, butuh PYTHONPATH=hermes-agent).
- Risiko: `aulia7` menjalankan WA-Gateway produksi + pernah ada insiden Avast mengarantina script gateway. Jangan ganggu service WA-Gateway.

## Status WA-Gateway (per README)
- Tahap 1-4 selesai/terverifikasi (teks, media, quote, forward, grup dua arah, sambung AuliaPos tanpa ubah kode). Tahap 5 (dokumentasi operasional final) pending.
- Utang teknis: `PATCH-ADAPTER` Evolution harus diterapkan ulang tiap upgrade; retensi media 180 hari.

## Status operasional (per user, 2026-10-12)
- Setup sudah jalan setelah gateway pindah ke `aulia7` (Windows Service). Terlihat aman.
- **Kasir sudah bisa melayani WA customer** (alur inbox berjalan end-to-end).

## Hubungan repo ini (M.A.R.A) dengan AuliaPos/WA-Gateway
- M.A.R.A = catatan ide + memory. Bukan kode produksi AuliaPos/WA-Gateway.

## Hermes Agent
- User sedang **eksperimen Hermes Agent** — agent terpisah (Hermes Desktop app), bisa berkomunikasi dengan user via **Telegram**.
- **Klarifikasi penting (2026-10-12)**: Hermes di PC ini **BUKAN M.A.R.A**, dan **tidak nyambung** ke Hermes yang ada di PC ini. Jadi jangan campur Hermes lokal PC ini dengan M.A.R.A.
- M.A.R.A = agent yang akan memantau AuliaPos. **M.A.R.A belum lahir** (masih gagasan, belum ada implementasi).
- **Klarifikasi (2026-10-12)**: Hermes yang dieksperimen user jalan di **PC user sendiri** (bukan `aulia7`, bukan PC kerja ini). M.A.R.A belum ada.
- Rencana: M.A.R.A nanti dijalankan di `aulia7` (lihat keputusan arsitektur).
- Punya konsep: `skills/`, `memories/` (`MEMORY.md`, `USER.md`), `config.yaml`, `SOUL.md`; folder lokal di `C:\Users\<USER>\AppData\Local\hermes`.
- Ada pola **hermes-multi-pc-sync**: repo Git jadi master skills/memories/config, di-symlink ke tiap PC.
- **Catatan**: dulu `M.A.R.A` dipakai sebagai master sync Hermes (ada skill `hermes-multi-pc-sync`, `hermes-agent-skill-authoring`, `inspecting-hermes-desktop-dom`), lalu **isi dihapus** (commit "Reset repo") untuk mulai ide baru. Perlu konfirmasi: apakah M.A.R.A masih dipakai untuk sync Hermes atau sudah dipindah.

## Lokasi lain yang ditemukan
- `C:\Projects\` berisi `AuliaPos`, `WA-Gateway`, `WA-Gateway-m1w2`, `_backup-m1-ticket01`, `ecosystem.config.js` (indikasi PM2).
- `D:\02\repos\` berisi `AuliaPos`, `WA-Gateway`.

## Riset Hermes (2026-10-12)
- Hermes = **"Hermes Agent" by Nous Research**, open-source, self-hosted. Ada desktop app (Electron), gateway, CLI/TUI, cron, kanban, sandbox, plugins.
- Terpasang di PC user: `C:\Users\AAN\AppData\Local\hermes` (config, `hermes-agent/` = source repo, `state.db`, `skills/`, `memories/`).
- **Cara Hermes "berkembang"** (relevan untuk M.A.R.A):
  - `memories/MEMORY.md` + `memories/USER.md` — catatan fakta & profil user, **di-append/di-update sendiri** tiap ada info baru.
  - `skills/<kategori>/<nama>/SKILL.md` — kemampuan reusable, ditulis sebagai markdown berfrontmatter; bisa dibuat/diperbaiki sendiri.
  - `SOUL.md` — kepribadian/gaya (mis. "be direct, no filler").
  - Cron & gateway: bisa jalan terjadwal + komunikasi via Telegram.
- Multi-PC: 3 Windows 11 (A, B, C), sinkron skills/memories/SOUL.md via **Syncthing**; config.yaml per-PC. Telegram dual-bot multi-profile.
- Konteks bisnis (dari USER.md Hermes): **toko Aulia = cetak foto** (newborn 12RS/10R/10R Full, foto umrah AURA Travel) + **POS terintegrasi WA gateway**. User = Aan (GitHub `tikusgot007`).
- **Implikasi desain**: model tumbuh ala Hermes = **memories (teks bebas) + skills (prosedur reusable)**, bukan cuma aturan terstruktur. Ini kandidat bentuk pengetahuan M.A.R.A.

## Ide: bantu kasir melayani WA customer
Masalah (diutarakan user 2026-10-12): kasir manusia, sering keliru:
- Lupa menanyakan info lengkap yang dibutuhkan customer (data order tidak lengkap).
- Lambat membalas chat customer.
- Lupa memberi kabar saat order customer sudah selesai.
- Masalah lain menyusul.

Status: baru problem statement. Arah solusi belum diputuskan. Pertanyaan terbuka ada di chat.

Keputusan sejauh ini:
- **Bukan bot otonom.** User ingin tetap ada tangan manusia (kasir) yang mengirim balasan.
- AI berperan sebagai **pengingat** + **pemberi rekomendasi** (solusi/balasan). Human-in-the-loop.
- Arah = asisten + reminder, bukan auto-reply.
- Prioritas: **ketiganya sekaligus** (lupa tanya info, lambat balas, lupa kabari).
- Fase saat ini: **pengumpulan ide**, belum digarap. Ide lengkap di `IDEAS.md`.
- Fokus awal: **cluster A (kelengkapan order), B (kecepatan & mutu balas), C (kabar & follow-up)**. Terbuka untuk berkembang lebih luas (D/produksi/pembayaran) nanti.
- Bahasan berikutnya: **aspek teknis M.A.R.A** (otak AI, penyimpanan pengetahuan, loop belajar & konfirmasi ke AAN).
- **Rencana membangun bertahap** (5 tahap) ada di `ideas/mara-cara-membangun.md`. Urutan tahap **disetujui** (1→2→3→4→5).
- **Tahap 0 (fondasi platform) SELESAI 2026-10-12**: Hermes + Gemini + Telegram + dashboard jalan di aulia7. Tahap 1 (baca `aulia_inboxdb`) belum digarap.

### Konsep inti: AI yang belajar dari pengalaman
- Info wajib antar jenis layanan **tidak uniform** → jangan hardcode di awal.
- AI harus **belajar**, bukan diprogram penuh di awal.
- Cold start: AI **bertanya ke AAN (pemilik)** — "kalau customer WA bilang gini, enaknya bagaimana?" — lalu jawaban disimpan jadi pengetahuan (mirip cara user menyuruh saya mencatat ke memory).
- Semakin lama, AI makin sedikit bertanya karena pengetahuan sudah terkumpul.
- **Sumber belajar awal**: history percakapan customer↔kasir yang sudah ada di inbox AuliaPos.
- AI mempelajari pola itu lalu **konfirmasi ke owner** ("benar jawabnya seperti ini?") untuk validasi.
- AI juga **boleh menjelajah internet** untuk belajar cara merespons customer yang baik.
- **Daftar harga resmi sudah ada** → bisa jadi acuan AI soal harga.
- **SOP belum ada**; akan tumbuh dari proses pembelajaran (bukan dokumen jadi).

### Arsitektur (keputusan 2026-10-12)
- Agent = **M.A.R.A** (sebelumnya disebut "Hermes"; user akan menyebutnya M.A.R.A).
- M.A.R.A **memantau AuliaPos** (WA Inbox).
- M.A.R.A **lapor ke AAN via Telegram** kalau ada yang perlu ditanyakan/diputuskan.
- Nanti M.A.R.A juga **berinteraksi dengan kasir lewat AuliaPos** (mis. tampilkan saran/rekomendasi).
- Jadi: M.A.R.A = otak/asisten; AuliaPos = tempat tampil untuk kasir; Telegram = kanal ke pemilik.
- **Tampilan ke kasir di AuliaPos**: ketiganya — saran balasan + checklist kelengkapan order + pengingat/alert.
- **Kadensi lapor ke Telegram**: real-time untuk hal penting **+** ringkasan harian.
- **Cakupan pantauan**: semua percakapan WA, terus-menerus (bukan hanya yang ditandai).
- **Akses baca**: baca DB inbox (`aulia_inboxdb`) + data Inbox yang ada. User minta rekomendasi teknis dari saya.

### Rekomendasi teknis saya (DISETUJUI 2026-10-12)
- **v1 (baca)**: koneksi **read-only** ke `aulia_inboxdb`. Cepat, tanpa mengubah kode AuliaPos, tanpa risiko cross-repo contract.
  - Risiko: kopel ke skema DB. Mitigasi: bungkus di lapisan repository M.A.R.A sendiri.
- **Tulis balik ke AuliaPos (nanti)**: lewat **API AuliaPos** (endpoint khusus M.A.R.A), bukan tulis DB langsung — supaya aturan bisnis & validasi AuliaPos tetap berlaku.
- Hasil analisis M.A.R.A disimpan di store M.A.R.A sendiri (SQLite), bukan di DB AuliaPos.
- **Otak AI**: model cloud via API (provider/model spesifik belum ditentukan).
- **Bentuk pengetahuan**: ikut **pola Hermes** — `memories` (fakta/kasus) + `skills` (prosedur reusable); M.A.R.A memperbaiki keduanya sendiri saat belajar.
- **Loop belajar**: M.A.R.A **usul dulu** ke AAN via Telegram; **setelah disetujui** baru ditulis ke memory/skill. (Human-in-the-loop, sejalan dengan bukan-bot.)
- **Bootstrap**: belajar awal dari **semua** history percakapan customer↔kasir di inbox.
- **Hal "penting" → lapor real-time**: (1) M.A.R.A tidak yakin, (2) chat lama belum dibalas, (3) komplain/perintah khusus customer. Ketiganya.
- **Tujuan browsing**: belajar gaya merespons customer, info teknis percetakan/foto, dan referensi harga pasar. Ketiganya.
- **Lokasi jalan M.A.R.A**: host **`aulia7`** (bareng WA-Gateway).
