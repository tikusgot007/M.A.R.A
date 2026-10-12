# Cara membangun M.A.R.A (gambaran bertahap)

Prinsip: bangun kecil dulu, tiap tahap harus bisa dites. M.A.R.A tidak menyentuh kode AuliaPos sampai tahap paling akhir (dan itu butuh approval, karena cross-repo).

Status (2026-10-12): urutan tahap **disetujui**. **Tahap 0 selesai**; Tahap 1 belum digarap.

## Tahap 0 — Fondasi platform (SELESAI 2026-10-12)
- Hermes Agent v0.21.7 terpasang di `aulia7` (`C:\Users\ops\AppData\Local\hermes`).
- Provider **Gemini**, model `gemini-3.6-flash`; `.env` berisi kunci Gemini + token bot Telegram M.A.R.A.
- **Telegram bot** jalan (gateway polling, auto-start Task Scheduler `Hermes_Gateway`).
- **Web dashboard** jalan: `http://192.168.1.68:9119`, user `aan` (Task Scheduler `MARA_Dashboard`).
- Catatan rinci di `MEMORY.md`.

## Prasyarat
- PC `aulia7` siap: runtime (Node/Python), kredensial **Telegram bot**, kunci **API model cloud**. — ✅ terpenuhi (Tahap 0).
- Akses **read-only** ke `aulia_inboxdb` (AuliaPos). — ⏳ belum.
- Store M.A.R.A: SQLite + folder `memories/` & `skills/` gaya Hermes. — ⏳ belum diisi.

## Tahap 1 — Fondasi baca (tanpa AI)
- Konektor read-only ke `aulia_inboxdb`.
- Salin percakapan ke store M.A.R.A secara inkremental (hanya yang baru).
- **Anonimisasi**: nomor/nama customer → kode; pemetaan disimpan lokal.
- Uji: data benar tersalin, tidak ada perubahan di AuliaPos.

## Tahap 2 — Otak + lapor Telegram
- Kirim percakapan (versi anonim) ke model cloud.
- Klasifikasi: butuh perhatian? tidak yakin? komplain?
- Kirim **alert real-time** ke AAN via Telegram sesuai kriteria "penting".
- **Ringkasan harian** otomatis.
- Uji: alert nyala pada kasus uji, tidak spam.

## Tahap 3 — Loop belajar
- M.A.R.A ajukan pelajaran ke AAN: "benar jawabnya begini?" (via Telegram).
- AAN balas ya/tidak/koreksi → baru ditulis ke `memories/` / `skills/`.
- **Bootstrap**: jalankan pembelajaran awal dari **semua** history (butuh approval karena boros token).
- Uji: ada 1 memory + 1 skill yang lahir dari proses ini.

## Tahap 4 — Tampil ke kasir di AuliaPos
- Butuh **endpoint API baru di AuliaPos** (approval; cross-repo).
- Tampilkan di halaman Inbox: **saran balasan + checklist kelengkapan order + alert**.
- Uji: kasir melihat saran tanpa mengubah alur kerja lama.

## Tahap 5 — Penyempurnaan
- Browsing internet (gaya balas, info teknis, harga).
- Follow-up otomatis-ingat, ringkasan shift, deteksi komplain/eskalasi.

## Catatan penting
- Perubahan di AuliaPos = cross-repo → **approval eksplisit** (lihat `AuliaPos/AGENTS.md` §9).
- Biaya token: memproses **semua** history awal bisa mahal; pertimbangkan bertahap.
- Rahasia (API key, token bot) disimpan lokal, jangan di repo.
