# IDEAS.md — kumpulan ide

Fase: **pengumpulan ide**, belum digarap. Prinsip: AI sebagai **pengingat + pemberi rekomendasi**, tetap ada tangan manusia (kasir) yang eksekusi. Bukan bot otonom.

## Konsep M.A.R.A (ringkasan keputusan 2026-10-12)
- M.A.R.A = agent/asisten yang **memantau WA Inbox AuliaPos**. Belum lahir; saat ini gagasan.
- Agent terpisah dari Hermes di PC ini (tidak nyambung).
- Cara kerja: pantau **semua** percakapan terus-menerus; **belajar dari history chat** customer↔kasir, konfirmasi ke AAN, juga boleh browsing internet; acuan harga dari daftar harga resmi; SOP tumbuh dari pembelajaran.
- Lapor ke AAN via **Telegram**: real-time untuk hal penting + ringkasan harian.
- Di dalam AuliaPos, M.A.R.A menampilkan ke kasir: **saran balasan + checklist kelengkapan order + pengingat/alert**.
- Akses baca: **read-only `aulia_inboxdb`** (v1). Tulis/tampil ke AuliaPos nanti lewat API AuliaPos.
- Dijalankan di **`aulia7`**. Store hasil analisis: SQLite M.A.R.A sendiri.

### Teknis (keputusan 2026-10-12)
- **Otak AI**: model **cloud via API**.
- **Pengetahuan**: pola Hermes — `memories` (fakta/kasus) + `skills` (prosedur reusable), diperbaiki sendiri saat belajar.
- **Loop belajar**: usul ke AAN via Telegram dulu → **setelah disetujui** baru ditulis.
- **Bootstrap**: belajar dari **semua** history chat customer↔kasir.
- **Privasi**: chat **dianonymkan** dulu (nomor/nama → kode) sebelum dikirim ke cloud; pemetaan disimpan lokal.
- **Alert real-time** kalau: M.A.R.A tidak yakin, chat lama belum dibalas, komplain/perintah khusus.
- **Browsing** internet: gaya merespons customer, info teknis percetakan/foto, referensi harga.

## Konteks masalah
Kasir manusia sering: (1) lupa tanya info order lengkap, (2) lambat balas, (3) lupa kabari order selesai. Prioritas awal: ketiganya sekaligus.

## Cluster A — Kelengkapan info order
- A1 Checklist dinamis per jenis layanan cetak: AI tandai field yang belum didapat (file, ukuran, bahan, jumlah, finishing, deadline).
- A2 Deteksi file/desain belum terkirim padahal customer bilang "saya kirim file".
- A3 Ekstraksi otomatis data order dari chat (ukuran, jumlah, bahan, deadline) → kasir tinggal konfirmasi.
- A4 Riwayat order customer ditampilkan (repeat customer) + usul "sama seperti order lalu?".
- A5 Memori preferensi customer (mis. selalu laminating).

## Cluster B — Kecepatan & kualitas balas
- B1 Reminder SLA: chat belum dibalas > X menit.
- B2 Deteksi pertanyaan customer yang belum dijawab.
- B3 Draft balasan siap-edit (kasir yang klik kirim).
- B4 Quick-reply pintar sesuai konteks (bukan template kaku).
- B5 Rekomendasi estimasi harga dari daftar harga (kasir konfirmasi).
- B6 QC pesan keluar: cek typo/harga/format sebelum kirim.
- B7 Deteksi nada mendesak/kesal → tandai prioritas.

## Cluster C — Kabar & follow-up
- C1 Notifikasi order selesai dari status AuliaPos → ingatkan kasir kabari customer.
- C2 Draft pesan "order selesai" siap kirim.
- C3 Follow-up: customer belum balas setelah kasir kirim harga/penawaran.
- C4 Deteksi janji kasir ("nanti saya cek") → jadikan pengingat.
- C5 Ringkasan harian: chat belum ditangani, order selesai belum dikabari.

## Cluster D — Lintas/umum
- D1 Ringkasan percakapan (thread) agar kasir baru paham konteks cepat.
- D2 Cegah dobel balas (kasir A & B balas customer sama).
- D3 Handover/shift: ringkasan chat yang masih menggantung.
- D4 Deteksi komplain → eskalasi ke pemilik.
- D5 Deteksi spam/penipuan.
