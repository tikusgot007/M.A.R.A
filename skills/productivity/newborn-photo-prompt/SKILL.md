---
name: newborn-photo-prompt
description: Use when generating ChatGPT newborn photo print prompts.
---

# Newborn Photo Prompt Generator

Menghasilkan prompt ChatGPT untuk dekorasi foto bayi/anak siap cetak di toko Aulia.
Sumber template referensi: `F:\GARAPAN\bidan siti rohmah\prompt\`.

## Ukuran & Format Standar

| Kode Ukuran | Dimensi | Rasio / Orientasi | Format Teks Standar |
|---|---|---|---|
| **12RS** | 450×300 mm (45×30 cm) | Lanskap (3:2), 300 dpi | Biodata lengkap 8 baris |
| **10R** | 200×250 mm (20×25 cm) | Vertikal (4:5) | Nama + Tanggal (atau lengkap jika diminta) |
| **10R Full**| 250×300 mm (25×30 cm) | Vertikal | Nama + Tanggal (1 atau 2 anak) |

---

## Alur Kerja Saat Diminta

1. **Konfirmasi / Minta Data Bayi**
   Jika user hanya menyebut ukuran (misal: "bikinkan prompt 12RS"), minta data dengan format siap isi:
   ```text
   Silakan kirim info bayinya:
   - Jenis kelamin (Boy / Girl):
   - Nama lengkap bayi:
   - Anak ke-:
   - Tanggal lahir:
   - Jam lahir:
   - Berat lahir (gram):
   - Panjang badan (cm):
   - Nama Orang Tua (Tn. ... & Ny. ...):
   ```
   *(Untuk ukuran 10R cukup tanyakan nama dan tanggal jika hanya butuh simpel, atau tawarkan opsi lengkap).*

2. **Generate Prompt**
   Keluarkan prompt dalam code block agar mudah disalin langsung ke ChatGPT.

---

## Template Prompt Standar

### 1. Template 12RS (450×300 mm — Kolase / Multi-Foto)
Gunakan saat melampirkan beberapa foto bayi (seperti referensi kubah/arsitektur/tema bebas dengan banyak kostum):
```text
"Saya melampirkan beberapa foto. 
Bertindaklah sebagai desainer grafis profesional dan buatkan desain visual yang menggabungkan elemen dari foto-foto tersebut ke dalam satu tata letak kolase yang harmonis.
Anda WAJIB mematuhi aturan berikut tanpa pengecualian:

Integritas Objek Asli:
JANGAN mengubah wajah, ekspresi, bentuk tubuh, proporsi, maupun pose dari objek/orang yang ada di dalam foto. Pertahankan kemiripan aslinya secara absolut dan persis seperti lampiran. Foto bayi harus tetap terlihat alami dan tidak berubah menjadi karakter AI.

Tema & Gaya:
Sesuaikan latar belakang, elemen dekoratif, dan palet warna agar selaras dengan nuansa dan kostum pada foto-foto yang dilampirkan. Hiasan, ornamen, dan background bebas berkreasi secara artistik dan mewah, namun bayi tetap menjadi fokus utama.

Komposisi & Tata Letak:
Buat tata letak lanskap (rasio 450x300 mm / 3:2). Susun foto-foto bayi secara seimbang dan rapi (misal: mengelilingi panel biodata di tengah atau komposisi grid/kolase profesional) dengan transisi visual yang halus dan menyatu.

Teks Khusus: Tambahkan tulisan persis seperti ini: 

[THE BABY BOY / THE BABY GIRL]
[NAMA BAYI LENGKAP]
[ANAK KE-XX]
[TANGGAL BULAN TAHUN]
[JAM.MENIT WIB]
[BERAT GRAM]
[PANJANG CM]
[TN. AYAH & NY. IBU]

Pastikan ejaannya 100% sama. DILARANG menambahkan teks, huruf acak, watermark, atau elemen tipografi lain di luar yang saya minta.

Resolusi & Kualitas: Hasilkan gambar dengan resolusi maksimal yang bisa dicapai, detail yang sangat tajam, bebas blur, dan kualitas rendering tingkat tinggi.

Ukuran/Rasio: Buat desain ini dalam ukuran/rasio 450x300mm."
```

### 2. Template 10R (200×250 mm)
```text
Saya melampirkan sebuah foto bayi.
Edit foto ini menjadi desain newborn announcement profesional dengan mempertahankan foto bayi asli sebagai objek utama.

1. INTEGRITAS FOTO ASLI — WAJIB
Pertahankan wajah bayi, ekspresi, bentuk kepala, bentuk tubuh, proporsi tubuh, tangan, kaki, pakaian, topi, posisi tidur, pose, dan karakteristik asli bayi semirip mungkin dengan foto sumber.
Jangan mengubah atau menggambar ulang bayi.
Jangan melakukan face swap, beautification berlebihan, perubahan bentuk wajah, perubahan warna kulit, perubahan ekspresi, atau perubahan anatomi.
Bayi harus terlihat seperti foto asli yang ditempatkan ke dalam desain, bukan bayi hasil AI.
Buat bayi dan keranjang terlihat lebih besar/dominan dalam komposisi, sehingga foto bayi tetap menjadi fokus utama.

2. KOMPOSISI
Buat desain vertikal dengan rasio 200 × 250 mm (4:5).
Gunakan komposisi yang minimalis dan tidak terlalu ramai.
Bayi menempati sebagian besar area tengah gambar.
Jangan terlalu banyak dekorasi yang mengelilingi bayi.
Sisakan ruang/area negatif yang aman di bagian atas atau bawah untuk teks (jangan mepet ke tepi/pinggir, beri jarak aman untuk batas bingkai cetak).
Background hanya menjadi pendukung dan jangan mengambil perhatian dari bayi.
Pertahankan nuansa studio newborn photography yang bersih, lembut, premium, dan harmonis.

3. BACKGROUND & DEKORASI
Sesuaikan dengan tema yang sudah ada pada foto.
Jangan menambahkan terlalu banyak objek baru.
Hindari dekorasi besar yang menutupi bayi atau membuat komposisi terlihat penuh.

4. TEKS
Tambahkan hanya teks berikut, persis tanpa perubahan:

[NAMA BAYI]
[TANGGAL BULAN TAHUN]

Posisi teks: Letakkan di area kosong yang paling seimbang (bisa di bagian atas atau di bagian bawah, sesuaikan dengan ruang kosong pada komposisi foto).
Margin teks: Jaga jarak aman dari tepi gambar, JANGAN terlalu mepet ke pinggir.
Jangan menambahkan teks lain, slogan, watermark, logo, huruf acak, atau tulisan dekoratif lainnya.

5. GAYA VISUAL
Hasil akhir harus terlihat seperti: professional newborn photography announcement, clean, premium, soft, cute tetapi tidak berlebihan, photographic rather than illustrated.
Prioritas visual: Bayi dan wajah asli, Nama dan tanggal, Background dan dekorasi sebagai elemen pendukung.
Jangan membuat background lebih dominan daripada bayi.

6. KUALITAS
Hasilkan dengan resolusi setinggi mungkin, sangat tajam, detail natural, pencahayaan realistis, tanpa blur, tanpa artefak AI, tanpa distorsi anatomi.
Jangan mengubah isi foto utama. Hanya rapikan komposisi dan tambahkan elemen desain di sekeliling foto.
```
