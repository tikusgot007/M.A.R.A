# Cara membangun M.A.R.A (gambaran bertahap)

Prinsip: bangun kecil dulu, tiap tahap harus bisa dites. M.A.R.A tidak menyentuh kode AuliaPos sampai tahap paling akhir (dan itu butuh approval, karena cross-repo).

Status: urutan tahap **disetujui** (2026-10-12). Belum digarap.

## Prasyarat
- PC `aulia7` siap: runtime (Node/Python), kredensial **Telegram bot**, kunci **API model cloud**.
- Akses **read-only** ke `aulia_inboxdb` (AuliaPos).
- Store M.A.R.A: SQLite + folder `memories/` & `skills/` gaya Hermes.

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
