# PDDikti Mobile: Dokumen Desain

Versi 1.0, 31 Oktober 2026. Aplikasi Flutter (nama paket `pddikti_mobile`, Android sebagai target uji utama) untuk membaca data publik Pangkalan Data Pendidikan Tinggi di HP.

Semua angka di dokumen ini berasal dari hasil pengamatan API (`openapi.json` dan `paths/*.json`, contoh lengkap ada di berkas asli hasil tangkapan). Kemdiktisaintek tidak menerbitkan dokumentasi untuk API ini, jadi setiap skema adalah tebakan terdidik dari contoh respons. Bagian 17 mendaftar semua yang masih harus diuji sebelum dianggap benar.

## 0. Cara memakai dokumen ini

Kalau ada konflik, urutan kewenangannya begini: data nyata dari API, lalu dokumen ini, lalu kebiasaan atau selera pengembang, termasuk selera AI agent. Setiap angka punya asal-usul yang bisa dicek di bagian 2. Kalau kenyataan bertentangan dengan dokumen, ubah dokumennya dulu, baru kodenya.

Dokumen ini ditulis supaya agent tidak perlu menebak. Kalau sebuah keputusan tidak ada di sini, jangan isi dengan default Material atau kebiasaan umum. Ambil keputusan paling sempit yang masih jalan, lalu catat di bagian 17.

Bagian 13 berisi kode acuan yang bisa langsung disalin: token, tema, normalisasi koordinat, pencarian, dan painter peta. Bagian 15 adalah daftar larangan. Baca bagian 15 sebelum menulis widget pertama.

## 1. Produk

PDDikti Mobile adalah klien tidak resmi untuk membaca data publik PDDikti: apakah sebuah kampus terdaftar, di mana lokasinya, berapa angka kelulusannya, dan kabar terbaru dari PDDikti.

Penggunanya ada tiga kelompok. Calon mahasiswa dan orang tua yang ingin memastikan sebuah kampus terdaftar. Mahasiswa, dosen, dan staf kampus yang butuh kode PT atau nama pembina (LLDIKTI) dengan cepat. Siapa pun yang membuka pengumuman pelaporan data. Tugas utamanya satu: dari mengetik beberapa huruf sampai melihat halaman satu kampus, di bawah 10 detik, termasuk saat sinyal jelek.

Yang bukan tujuan versi 1: peringkat atau rekomendasi kampus, akun dan login, notifikasi, bahasa Inggris, mode terang. Alasannya ada di bagian 3 dan bagian 16.

Aplikasi ini tidak resmi dan tidak berafiliasi dengan Kemdiktisaintek. Konsekuensi desainnya: warna dan ikon tidak meniru identitas resmi (situs resmi memakai tema ungu `#5B2C8B` menurut `manifest.json`, dan logo resminya tidak dipakai di mana pun), dan layar Tentang menyatakan status itu dengan kalimat yang jelas.

## 2. Fakta API yang mengikat desain

### 2.1 Endpoint yang terbukti ada

| Endpoint | Isi | Dipakai di |
|---|---|---|
| `GET /api/beranda?content_limit` | jumlah dosen, mahasiswa, prodi, PT; 10 bidang ilmu (`total_mahasiswa`, `persentase_kelulusan`); `publications`; `activities` | Beranda: ledger dan tabel bidang ilmu. `publications` dan `activities` diabaikan |
| `GET /api/pt/locations` | 4.342 kampus: `kelompok`, `pembina`, `id_sp`, `kode`, `nama`, `kab_kota`, `lintang`, `bujur`. Satu respons sekitar 1,2 MB | Peta, pencarian, filter, detail |
| `GET /api/pt/logo/{id_sp}` | gambar logo | Detail dan baris hasil |
| `GET /api/pt/graduation-rate/{id_sp}` | `{id_sp, graduation_rate}` | Detail |
| `GET /api/content/announcements?page&page_size&search` | `id`, `title`, `slug`, `link`, `description` (HTML), `created_at`, plus `pagination` | Kabar: Pengumuman |
| `GET /api/content/publications?page&page_size&search` | `id`, `title`, `thumbnail`, `link`, `created_at`, plus `pagination` | Kabar: Publikasi |
| `GET /manifest.json` | manifest PWA | Tidak dipakai |

### 2.2 Temuan data dan akibatnya pada desain

| Temuan | Bukti | Akibat pada desain |
|---|---|---|
| Kunci stabil kampus adalah `kode`, bukan `id_sp` | `id_sp` tidak stabil: publikasi yang sama punya id berbeda di `/api/beranda` dan `/api/content/publications`, dan 0 dari 15 id di path logo muncul di `locations`. `kode` berisi 6 digit, unik di 4.342 baris, tapi dipad dua spasi (panjang 8) | Selalu `kode.trim()`. Rute, cache, dan pencarian memakai `kode`. `id_sp` diperlakukan sebagai token buram yang hanya dipakai untuk memanggil logo dan kelulusan |
| 847 dari 4.342 kampus (19,5%) tanpa koordinat lengkap | PTA 408 dari 1.395 kosong, PTS 389 dari 2.645, PTN hanya 3 dari 127 | Peta bukan sensus dan tidak boleh tampil seolah sensus. Teks di bawah peta selalu menyebut "N dari 4.342". Persebaran PTA di peta pasti kurang |
| 65 koordinat di luar kotak Indonesia | Kotak: lintang -11,5 sampai 6,5, bujur 94,5 sampai 141,5. 17 tertukar dan bisa dibetulkan, 48 tidak. Contoh: Akademi Kepolisian (AKPOL) berisi lintang 110,41 dan bujur -7,01 | Aturan normalisasi di bagian 6.2. Hasil akhirnya 3.447 titik layak digambar |
| `kab_kota` "Tidak Diisi" | 41 baris. 447 nilai unik termasuk nilai itu | Dipetakan ke `null`, tidak masuk daftar filter kota |
| Kelompok dan pembina | PTS 2.645, PTA 1.395, PTK 166, PTN 127, PTLN Cabang Indonesia 6, N/A 3 (pembina "Semua Unit"). 56 pembina berbeda, 17 di antaranya LLDIKTI I sampai XVII | Filter dua tingkat: kelompok, lalu pembina. "N/A" ditampilkan sebagai "Lainnya" |
| Dua ukuran "mahasiswa" yang tidak sebanding | Jumlah `total_mahasiswa` di 10 bidang ilmu adalah 47.512.492. `jumlah_mahasiswa` di beranda adalah 9.967.487 (selisih 4,77 kali). Definisi keduanya tidak dijelaskan | Tidak pernah menghitung persen bidang terhadap angka beranda. Panjang batang relatif terhadap bidang terbesar. Keduanya diberi label berbeda dan penjelasan |
| Jumlah kampus berbeda | `pt.jumlah` di beranda 4.416, panjang daftar `locations` 4.342 (selisih 74) | Jangan menurunkan satu angka dari yang lain. Ledger memakai angka beranda, header daftar memakai panjang daftar yang sebenarnya dimuat |
| Format angka kelulusan | `persentase_kelulusan` berupa string dengan koma desimal ("52,88"). `graduation_rate` berupa angka 0 sampai 100 (misalnya 74,11764...). Dua dari 15 sampel bernilai 0, dan `id_sp` pada respons itu jauh lebih pendek dari yang lain | Parse string dengan mengganti koma jadi titik. Nilai 0 ditampilkan "Belum ada data", bukan "0%" (asumsi, lihat bagian 17) |
| Isi pengumuman berupa HTML kotor | `<p style="text-align: justify;">`, penomoran lewat `<br>`, tautan Instagram di dalam `<a>` | Lewat sanitizer, style inline dibuang, semua teks rata kiri |
| Tanggal | ISO 8601 dengan offset `+07:00`, beberapa tepat pukul 07:00:00 | Tampilkan tanggal saja. Tidak ada jam dan tidak ada "3 hari lalu" |
| Gambar dan tautan publikasi | `thumbnail` berupa path relatif (`/publication/xxx.jpeg`). `link` mengarah ke Google Drive atau Dropbox | Butuh base URL gambar (asumsi, bagian 17). Tautan dibuka di luar aplikasi dengan konfirmasi |

### 2.3 Yang tidak ada

Pengamatan hanya menangkap lalu lintas halaman beranda, jadi yang berikut belum ditemukan, bukan berarti tidak ada: pencarian server-side untuk kampus, prodi, dosen, dan mahasiswa; akreditasi; detail kampus di luar delapan field `locations`; endpoint kegiatan (`activities` hanya muncul di dalam `/api/beranda`, satu item pada pengamatan).

Keputusan: versi 1 hanya membangun yang terbukti ada. Fitur lain dimodelkan sebagai `Capabilities` bernilai `false` (bagian 11.4). UI untuk fitur itu tidak ditampilkan sama sekali. Tidak ada tombol abu-abu, tidak ada label "Segera hadir".

## 3. Prinsip

**Aplikasi menyajikan, tidak menilai.** Tidak ada peringkat, skor, kata "terbaik", atau warna hijau dan merah pada angka kelulusan. Definisi angkanya tidak diketahui (bagian 2.2) dan nol bisa berarti kosong. Menyusun peringkat dari angka yang artinya belum jelas adalah cara tercepat menyesatkan orang tua yang sedang memilih kampus.

**Kosong adalah informasi.** Data yang tidak diisi tampil sebagai kosong beserta alasannya ("Lokasi belum diisi oleh kampus"). Tidak disembunyikan, tidak diganti 0 atau tanda hubung. Peta selalu menyebut berapa kampus yang tidak bisa digambar.

**Satu hal yang diingat: peta titik.** Sisanya sengaja tenang: baris datar, teks, garis tipis. Tidak ada kartu bertumpuk, tidak ada gradien, tidak ada bayangan. Kemewahan satu-satunya dipakai di peta.

**Peta dan daftar adalah satu query.** Filter yang dipasang di tab Kampus langsung menyalakan titik yang cocok di peta Beranda. Hanya ada satu sistem filter, dan ia punya satu sumber kebenaran.

**Hidup di HP biasa dan sinyal jelek.** Setelah unduhan pertama (sekitar 1,2 MB), semua fitur inti jalan tanpa internet. Target uji: Android RAM 3 GB.

**Jujur soal asal-usul.** Tidak resmi, sumber data selalu disebut, dan tanggal terakhir data diunduh selalu bisa dilihat.

## 4. Identitas visual

### 4.1 Arah

Gelap profesional berbasis indigo tinta, dengan satu warna sorot kunyit. Alasannya tiga. Pengguna datang untuk memastikan fakta tentang kampus, jadi nadanya harus tenang dan layak dipercaya, bukan gaya terminal. Bedanya dari situs resmi yang ungu harus jelas, supaya tidak ada yang mengira ini aplikasi pemerintah. Dan indigo dengan kunyit akrab dalam tradisi tekstil Indonesia, serta di layar gelap memberi kontras tinggi tanpa neon.

Hanya mode gelap di versi 1. Paksa dengan `themeMode: ThemeMode.dark`. Semua warna lewat token (bagian 13.2), jadi mode terang bisa ditambahkan nanti tanpa menyentuh widget.

### 4.2 Warna

Tidak ada hitam murni dan tidak ada putih murni.

| Token | Hex | Peran | Kontras |
|---|---|---|---|
| `tinta` | `#1A1F33` | Latar semua layar | |
| `tintaAngkat` | `#242A44` | Permukaan terangkat: field input, bottom sheet, baris yang sedang ditekan | |
| `garis` | `#3A4266` | Pemisah baris data. Dekoratif, tidak boleh membawa makna | 1,67 pada `tinta` |
| `garisTegas` | `#6F79A3` | Batas kontrol interaktif: field, chip | 3,84 pada `tinta`, 3,32 pada `tintaAngkat` |
| `kapur` | `#ECE7DA` | Teks utama | 13,21 pada `tinta`, 11,42 pada `tintaAngkat` |
| `kapurRedup` | `#A9AEC4` | Teks sekunder dan label | 7,41 pada `tinta`, 6,40 pada `tintaAngkat` |
| `kunyit` | `#F0B429` | Hal yang bisa ditekan atau sedang dipilih: tombol utama, tab aktif, titik yang cocok, cincin fokus | 8,75 pada `tinta`, 7,56 pada `tintaAngkat` |
| `laut` | `#5CC8B8` | Isi batang data (bidang ilmu, kelulusan) | 8,08 pada `tinta`, 6,99 pada `tintaAngkat` |
| `karang` | `#E8826B` | Hanya untuk galat jaringan dan aksi merusak. Dilarang menandai angka "jelek" | 6,09 pada `tinta`, 5,26 pada `tintaAngkat` |

Aturan pemakaian:

Kunyit hanya untuk elemen yang bisa ditekan atau yang sedang terpilih atau cocok. Kalau elemen tidak bisa ditekan dan bukan hasil pencocokan, ia tidak boleh kunyit. Laut hanya untuk isi batang data. Tidak ada gradien. Tidak ada teks berwarna dengan opasitas, pakai `kapurRedup`.

Titik peta memakai tiga keadaan. Tanpa filter, semua titik `kapur` dengan alfa 0,38 (setara `#6A6B72` di atas `tinta`, kontras 3,07). Dengan filter aktif, titik yang cocok `kunyit` penuh dan sisanya turun ke `kapur` alfa 0,18. Titik tidak diberi warna per kelompok: pelangi di peta membuat orang membaca warna, bukan bentuk persebaran.

Status bar dan navigation bar sistem transparan dengan ikon terang di atas latar `tinta`.

### 4.3 Tipografi

Dua keluarga yang jelas berbeda. **Archivo** (grotesk dengan sumbu lebar) untuk seluruh antarmuka, nama kampus, dan angka. **Source Serif 4** hanya untuk teks bacaan panjang, yaitu isi pengumuman. Keduanya berlisensi OFL dan dibundel sebagai aset, bukan lewat paket `google_fonts`, supaya jalan tanpa internet dan tanpa permintaan ke pihak ketiga. Sertakan berkas lisensi di `assets/fonts/`.

Alasan Archivo: nama kampus panjang (terpanjang 92 karakter, persentil 95 sekitar 58 karakter, misalnya "Sekolah Tinggi Agama Kristen Reformed Remnant Internasional Minahasa Provinsi Sulawesi Utara"). Sumbu lebar (`wdth`) membuat nama bisa dipadatkan tanpa memuat font condensed terpisah. Tidak ada font monospace di aplikasi ini. Kolom kode dan angka memakai angka tabular dari Archivo.

| Peran | Keluarga | Ukuran / tinggi baris | Bobot | `wdth` | Dipakai untuk |
|---|---|---|---|---|---|
| `judulLayar` | Archivo | 24 / 30 | 600 | 100 | Judul top bar, rata kiri |
| `namaDetail` | Archivo | 22 / 28 | 600 | 87 | Nama kampus di halaman detail |
| `namaBaris` | Archivo | 16 / 21 | 600 | 90 | Nama kampus di daftar |
| `isi` | Archivo | 15 / 22 | 400 | 100 | Teks antarmuka umum |
| `tombol` | Archivo | 15 / 20 | 600 | 100 | Teks tombol |
| `label` | Archivo | 13 / 18 | 500 | 100 | Label dan nilai sekunder |
| `angka` | Archivo | 17 / 22 | 500 | 100 | Ledger dan kode, angka tabular |
| `catatan` | Archivo | 12 / 16 | 400 | 100 | Catatan kecil. Ukuran minimum aplikasi |
| `bacaan` | Source Serif 4 | 16 / 26 | 400 | | Isi pengumuman |

Aturan teks:

Sentence case di mana-mana. Tidak ada teks huruf kapital semua, tidak ada label berjarak lebar. Nama kampus ditulis persis seperti dari API: kapitalisasinya tidak diubah, dan tidak dipotong dengan elipsis di halaman detail (di daftar maksimal 3 baris). Semua teks rata kiri. Tidak ada teks rata kanan-kiri, walaupun API mengirim `text-align: justify`: di layar sesempit HP itu menghasilkan celah antarkata. Satu-satunya yang rata kanan adalah kolom angka di ledger.

Format angka memakai locale `id_ID`: titik untuk ribuan, koma untuk desimal (9.967.487; 74,1%). `graduation_rate` dibulatkan satu desimal. `persentase_kelulusan` dua desimal, sesuai sumber ("52,88"). Tanggal seperti "30 Maret 2026". Satu pengecualian: koordinat memakai titik desimal dan ditulis di dua baris terpisah (`Lintang -6.18320`, `Bujur 106.91202`), karena dua angka berkoma desimal yang dipisah koma tidak terbaca.

### 4.4 Bentuk, jarak, kedalaman

Jarak memakai kelipatan 4dp: 4, 8, 12, 16, 20, 24, 32. Padding horizontal layar 20dp.

Radius hanya tiga, masing-masing ada artinya. 0 untuk baris data dan batang, karena data tidak membulat. 8 untuk kontrol (input, chip, tombol). 16 hanya untuk sudut atas bottom sheet. Titik peta bulat penuh. Tidak ada radius lain.

Tidak ada bayangan. Kedalaman dibuat dengan selisih warna permukaan (`tinta`, `tintaAngkat`). Scrim di belakang sheet `Colors.black54`.

Daftar adalah baris datar dipisah garis 1dp `garis` dari tepi ke tepi, bukan kartu. Ledger (pasangan label dan nilai) memakai garis titik-titik penghubung seperti daftar isi buku. Garis itu menyatakan "label ini milik angka ini", dan di layar sempit ia juga yang menjaga mata tidak tersesat dari kiri ke kanan. Garis titik digambar dengan painter dan dikeluarkan dari semantics.

Tinggi sentuh minimal 48dp. Tidak ada ripple: `splashFactory: NoSplash.splashFactory`. Umpan balik tekan adalah latar baris yang berubah menjadi `tintaAngkat` selama ditekan.

### 4.5 Ikon

Ikon antarmuka memakai `phosphor_flutter`, gaya regular, 22dp, hanya untuk navigasi, tombol, dan penanda info. Ikon tidak dibungkus lingkaran atau kotak berwarna. Tab aktif memakai varian fill.

Ikon aplikasi dibuat dari data yang sama dengan petanya: render sekali 3.447 titik terproyeksi sebagai PNG 1024px di atas latar `tinta`, titik `kapur`, dan satu titik `kunyit` yang diperbesar. Bukan logo buku, bukan topi toga, bukan ikon pendidikan generik. Buat skripnya di `tool/buat_ikon.dart` supaya ikon bisa dibuat ulang saat data berubah.

## 5. Struktur layar

### 5.1 Navigasi

Tiga tab: **Beranda**, **Kampus**, **Kabar**. Tentang dibuka dari ikon info di top bar Beranda, bukan sebagai tab. Navigasi memakai `go_router` dengan `StatefulShellRoute.indexedStack`.

| Rute | Layar |
|---|---|
| `/beranda` | Beranda |
| `/peta` | Peta layar penuh (pan dan zoom) |
| `/kampus?q=&kelompok=&pembina=&kota=&fokus=1` | Daftar kampus. Filter hidup di query URL |
| `/kampus/:kode` | Detail kampus. Parameter adalah `kode`, bukan `id_sp` |
| `/kabar` | Kabar (tab Pengumuman dan Publikasi) |
| `/kabar/pengumuman/:slug` | Detail pengumuman |
| `/tentang` | Tentang |

Publikasi tidak punya halaman dalam: ketukan langsung membuka tautan (setelah konfirmasi).

Navigation bar: tanpa indikator berbentuk pil. Tab aktif memakai ikon fill dan label `kunyit`, tab lain `kapurRedup`. Latar `tinta` dengan garis atas 1dp `garis`. Tinggi 64dp ditambah inset sistem.

### 5.2 Beranda

```text
+------------------------------------------+
| PDDikti Mobile                       (i) |  top bar 56dp, judul rata kiri
|                                          |
| [ Cari nama, kode, atau kota           ] |  tombol berbentuk field, ketuk
|                                          |  membuka tab Kampus dengan fokus
|   . ..:::.:.          . .                |
|    ..:::::::::..   ..:. .    .           |  peta titik, lebar penuh
|   ...::::::::::::.....:    ..  .         |  tinggi = lebar x 0,383 + 16dp
|                                          |  ketuk membuka /peta
| 3.447 dari 4.342 kampus di daftar punya  |
| koordinat yang bisa digambar.            |  catatan 12sp, kapurRedup
|                                          |
| Kampus ........................ 4.416    |
| Program studi ................ 33.741    |
| Dosen ....................... 303.067    |
| Mahasiswa ................ 9.967.487     |  ledger, bukan kartu
|                                          |
| Bidang ilmu (i)                          |
|                    Total mhs.  Persen lulus|
| Pendidikan  ########  12.188.570   60,78% |
| Ekonomi     ######     8.908.902   52,88% |
| Teknik      ######     7.990.889   50,98% |
| ...                                      |
+------------------------------------------+
|   Beranda       Kampus        Kabar      |
+------------------------------------------+
```

Peta adalah hal pertama yang terlihat, dan bukan angka statistik. Angka statistik sengaja diperkecil menjadi ledger empat baris supaya tidak menjadi "empat kotak angka besar di bawah hero", yang merupakan tampilan paling umum di aplikasi data mana pun.

Tabel bidang ilmu: urut default berdasarkan total mahasiswa menurun. Ketuk judul kolom untuk mengurutkan menurut kolom itu. Panjang batang relatif terhadap bidang terbesar. Ikon info di judul membuka sheet penjelasan (teks di bagian 9). Header kolom ditulis "Total mhs." hanya bila lebar tidak cukup untuk "Total mahasiswa".

Saat offline dan data berasal dari cache, muncul baris tipis di bawah top bar: "Offline. Data diunduh 28 Oktober 2026." Tidak ada banner besar.

### 5.3 Kampus

```text
+------------------------------------------+
| Kampus                                   |
| [ pamulang                            x ]|  autofokus bila datang dari Beranda
| [PTS x] [LLDIKTI IV x]          Filter 2 |  chip hanya muncul bila filter aktif
| 312 dari 4.342 kampus                    |
|------------------------------------------|
| [lg] {nama, maks 3 baris}                |
|      {kab_kota}, {kelompok}       {kode} |  kode rata kanan, angka tabular
|------------------------------------------|
| [lg] {nama}                              |
|      Kota belum diisi, PTS        {kode} |
|------------------------------------------|
```

Logo 40dp di kiri, dimuat malas hanya untuk baris yang terlihat. Bila logo gagal, tampil monogram (bagian 8.4 untuk aturannya) di kotak `tintaAngkat`.

Tombol Filter membuka bottom sheet setinggi 90% layar berisi tiga bagian:

1. Kelompok: pilihan ganda, enam nilai.
2. Pembina: pilihan ganda dengan kolom cari di dalamnya, dikelompokkan menurut kelompok (LLDIKTI I sampai XVII di bawah PTS, 11 pembina PTA, 25 pembina PTK).
3. Kota atau kabupaten: daftar 446 nilai dengan kolom cari (447 nilai unik dikurangi "Tidak Diisi").

Tombol utama sheet berbunyi "Tampilkan 312 kampus" dan angkanya ikut berubah saat filter diubah. Logika gabungan: AND antar jenis filter, OR di dalam satu jenis.

### 5.4 Detail kampus

```text
+------------------------------------------+
| <                                        |
|                                          |
| [logo 56]  {nama, semua baris}           |  namaDetail, tidak dipotong
|            Kode PT {kode}                |
|                                          |
| Kelompok ....................... PTS     |
| Pembina .................. LLDIKTI IV    |
| Kota atau kabupaten ........ {kab_kota}  |
|                                          |
| Tingkat kelulusan (i)           74,1%    |
| [##########################-----------]  |  batang laut, skala 0 sampai 100
|                                          |
| Lokasi                                   |
| +--------------------------------------+ |
| |  . . :::. .      (o)                 | |  peta mini 120dp, tidak interaktif
| +--------------------------------------+ |  kampus ini kunyit dengan cincin
| Lintang -6.18320                         |
| Bujur 106.91202                          |
|                                          |
| [ Buka di aplikasi peta ] [ Salin kode ] |
+------------------------------------------+
```

Bila nilai ledger tidak muat sebaris dengan labelnya (misalnya pembina "Kementerian Agraria dan Tata Ruang/Badan Pertanahan Nasional"), ledger berpindah ke susunan bertumpuk: label di atas, nilai di bawah, keduanya rata kiri. Tidak ada elipsis pada nilai ledger.

Kampus tanpa koordinat: bagian Lokasi diganti satu kalimat "Lokasi belum diisi oleh kampus." tanpa peta mini. Kampus dengan koordinat dikoreksi: tampilkan peta dan tambahkan catatan "Lintang dan bujur di sumber tertukar. Sudah dibetulkan." Tombol "Buka di aplikasi peta" membuka URI `geo:` lewat `url_launcher`.

Tidak ada bagian prodi, dosen, atau mahasiswa selama `Capabilities` bernilai `false`.

### 5.5 Kabar

```text
+------------------------------------------+
| Kabar                                    |
| Pengumuman    Publikasi                  |  teks, garis bawah kunyit 2dp
| ===========                              |  pada yang aktif. Bukan pil
| [ Cari pengumuman                      ] |
|                                          |
| {judul, maks 3 baris}                    |
| 30 Maret 2026                            |
| {dua baris awal isi, kapurRedup}         |
|------------------------------------------|
```

Publikasi:

```text
|------------------------------------------|
| [sampul 3:4]  {judul}                    |
| [  72dp    ]  30 Maret 2026              |
|------------------------------------------|
```

### 5.6 Tentang

Isi dari atas ke bawah: pernyataan tidak resmi, nama situs sumber data, tanggal unduhan terakhir untuk daftar kampus dan beranda, tombol "Perbarui data", versi aplikasi, daftar istilah (PTN, PTS, PTA, PTK, PTLN, LLDIKTI, kode PT), catatan bahwa aplikasi bergantung pada endpoint yang tidak didokumentasikan sehingga bisa berhenti bekerja tanpa pemberitahuan, dan lisensi font. Tidak ada tombol beri bintang, tidak ada ajakan berbagi.

## 6. Peta titik

### 6.1 Konsep

Peta ini tidak punya basemap. Tidak ada garis pantai, tidak ada tile, tidak ada label provinsi. Yang ada hanya 3.447 titik lokasi kampus, dan karena kampus menumpuk di tempat orang tinggal, titik-titik itu sendiri membentuk siluet Nusantara: padat di Jawa, tipis di Kalimantan dan Papua, dan kosong di laut. Bentuk itu adalah datanya. Ini juga membuat peta jalan tanpa internet dan tanpa biaya tile server.

### 6.2 Normalisasi koordinat

Aturan ini wajib dijalankan di lapisan model, sekali, saat parsing. Kode acuannya di bagian 13.3.

1. `trim` kedua string. Kosong menjadi `null`.
2. `double.tryParse`. Gagal menjadi `null`.
3. Valid bila lintang di antara -11,5 dan 6,5 dan bujur di antara 94,5 dan 141,5.
4. Bila tidak valid tetapi valid setelah ditukar, tukar dan tandai `dikoreksi = true`.
5. Selain itu `null`. Kampus tetap ada di daftar dan pencarian, hanya tidak digambar.

Hasil pada data pengamatan: 3.495 baris berkoordinat, 17 dikoreksi, 48 dibuang, 3.447 digambar. Kotak ini hanya menangkap kesalahan kasar. Titik yang salah tetapi masih di dalam kotak tidak bisa dideteksi, dan itu sebabnya catatan "dari kampus" selalu menyertai koordinat.

### 6.3 Proyeksi

Equirectangular sederhana. Ruang kerja berlebar 1 dan bertinggi 18/47 (sekitar 0,383):

```text
x = (bujur - 94,5) / 47
y = (6,5 - lintang) / 18
```

Mercator tidak dipakai: rentang lintangnya hanya 18 derajat di sekitar khatulistiwa, jadi bedanya tidak terlihat dan hitungannya sia-sia. Titik diurutkan menurut `x` naik, karena animasi sapuan (bagian 10) menampilkan titik dari barat ke timur.

### 6.4 Render

`CustomPainter` dengan `canvas.drawRawPoints(PointMode.points, Float32List, paint)` dan `strokeCap = StrokeCap.round`. Dua `Float32List`, dua panggilan gambar:

| Lapisan | Isi | Warna |
|---|---|---|
| `redup` | Semua titik (atau yang tidak cocok bila ada filter) | `kapur` alfa 0,38, atau 0,18 bila ada filter |
| `sorot` | Titik yang cocok filter | `kunyit` penuh, diameter 1,4 kali |

Kedua daftar dihitung ulang hanya saat query berubah, bukan di setiap `paint`. Painter menerima `TransformationController` dan menerapkan matriksnya sendiri, supaya titik tetap tajam saat di-zoom dan ukurannya terkendali. Diameter titik di layar: `1,8dp * sqrt(skala)`, dibatasi 1,8 sampai 6dp. Tanpa aturan ini, zoom 8 kali membuat titik sebesar kancing.

`InteractiveViewer` dipasang transparan di atas `CustomPaint` (anaknya `SizedBox.expand()`), hanya sebagai penangkap gestur dan pemegang `TransformationController`. Jangan membungkus painter dengan `RepaintBoundary` di dalam yang di-transform: hasilnya raster yang diperbesar dan menjadi buram. Rotasi dimatikan. Zoom 1x sampai 12x.

### 6.5 Interaksi

Ketuk pada peta mencari titik terdekat lewat indeks grid seragam (sel 0,01 satuan ternormalisasi, dibangun sekali). Ambang ketuk 16dp. Di Jawa banyak titik bertumpuk, jadi hasilnya bukan satu kampus melainkan sheet "8 kampus terdekat dari titik ini", diurutkan menurut jarak. Ketuk salah satu membuka detailnya. Bila hanya satu kampus dalam ambang, langsung ke detail.

Bila filter menghasilkan tepat satu kampus berkoordinat, peta menggambar cincin `kunyit` 1,5dp di sekeliling titik itu.

### 6.6 Dua ukuran tampil

Tertanam di Beranda: lebar penuh, tinggi `lebar * 0,383 + 16dp`, hanya menerima ketukan (membuka `/peta`), tanpa pan dan zoom supaya tidak berebut gestur dengan scroll halaman.

Layar penuh `/peta`: pan dan zoom aktif. Pada layar portrait, tampilan awal berskala 2,4 berpusat di Jawa (lintang -7, bujur 110). Di bawahnya selalu ada satu baris teks hitungan ("312 dari 4.342 kampus") dan tombol "Hapus filter" bila filter aktif.

### 6.7 Aksesibilitas peta

Peta diberi `Semantics(label: "Peta persebaran 3.447 kampus. Buka tab Kampus untuk mencari.", button: true)`. Pembaca layar tidak diberi akses ke titik individual, karena itu tidak berguna. Daftar di tab Kampus adalah padanannya, dan keduanya berbagi query yang sama.

## 7. Pencarian dan filter

Tidak ada endpoint pencarian, jadi pencarian dilakukan di perangkat atas 4.342 entri. Itu murah: tidak perlu isolate untuk pencarian, hanya untuk parsing.

**Indeks** dibangun sekali setelah parsing: nama ternormalisasi (huruf kecil, selain huruf dan angka diganti spasi, spasi ganda dilipat, jadi "(AKPOL)" menjadi "akpol"), daftar kata, kota ternormalisasi, dan inisial (huruf pertama tiap kata, kecuali kata sambung "dan", "di", "of", "the", "untuk").

**Skor** menentukan urutan hasil bila ada query:

| Kondisi | Skor |
|---|---|
| `kode` sama persis dengan query | 1000 |
| Query semua angka dan `kode` diawali query | 900 |
| Nama sama persis | 850 |
| Nama diawali query | 800 |
| Inisial sama persis dengan query (misalnya "ui", "ugm", "itb") | 700 |
| Setiap kata query adalah awalan salah satu kata nama | 600 dikurangi jumlah kata nama (nama pendek lebih dulu) |
| Nama memuat query | 400 |
| Kota memuat query | 200 |

Urut menurun menurut skor, lalu nama. Tanpa query, urut nama A sampai Z.

**Singkatan.** API tidak punya field singkatan. Inisial menutup UI, UGM, dan ITB, tetapi singkatan tidak baku seperti "UNPAM" tidak bisa ditebak dari nama. Sediakan `assets/alias.json` dengan bentuk `{"unpam": "<kode>"}`. Isinya hanya boleh diisi pengembang dengan `kode` yang diambil dari data, tidak boleh ditebak. Alias dicek lebih dulu dan menghasilkan skor 1000.

**Debounce** 150ms.

**Filter** hidup di satu provider `KampusQuery` (q, kelompok, pembina, kota). Peta Beranda, peta penuh, dan daftar membaca provider turunan yang sama. State dicerminkan ke query URL supaya tombol kembali dan tautan dalam aplikasi bekerja.

**Tidak ada indeks A sampai Z di tepi daftar.** Sebagian besar nama diawali jenis institusi (Universitas, Sekolah Tinggi, Politeknik, Akademi, Institut), jadi huruf awal tidak membedakan apa pun. Menjelajah dilakukan lewat filter, bukan lewat gulir panjang.

## 8. Kabar

### 8.1 Pengumuman

Dimuat 10 per halaman (`page_size=10`). Halaman berikutnya dimuat saat baris ke-3 dari bawah terlihat. Kolom cari memakai parameter `search` di server dengan debounce 400ms. Parameter `page`, `page_size`, dan `search` dikirim sebagai string.

### 8.2 Detail pengumuman

Judul `namaDetail`, tanggal `label`, tombol "Buka lampiran" bila `link` ada, lalu isi dengan gaya `bacaan` (Source Serif 4, 16 / 26). Lebar bacaan dibatasi 560dp di layar lebar.

Sanitizer memakai daftar putih. Tag yang diizinkan: `p`, `br`, `a`, `strong`, `b`, `em`, `i`, `u`, `ul`, `ol`, `li`, `h1` sampai `h4`. Semua atribut `style`, `class`, dan `align` dibuang, hanya `href` yang dipertahankan pada `a`. Gambar tidak dirender. Render dengan `flutter_widget_from_html_core` dengan gaya yang ditimpa agar semua rata kiri dan memakai token warna.

### 8.3 Tautan keluar

Setiap tautan ke luar aplikasi (lampiran, tautan di dalam isi, publikasi) membuka sheet konfirmasi yang menyebut host-nya: "Buka dropbox.com di peramban?" dengan tombol "Buka" dan "Batal". Ini bukan formalitas: sebagian besar tautan di data menuju Google Drive, Dropbox, dan Instagram, bukan situs pemerintah, dan pengguna berhak tahu sebelum keluar.

### 8.4 Publikasi dan monogram

Baris publikasi: sampul rasio 3:4 lebar 72dp, judul, tanggal. Bila sampul gagal dimuat, tampil kotak `tintaAngkat` dengan ikon dokumen. Ketuk membuka konfirmasi tautan.

Monogram kampus (pengganti logo yang gagal): satu atau dua huruf kapital dari kata pertama dan kedua nama yang bukan jenis institusi (abaikan "Universitas", "Institut", "Sekolah", "Tinggi", "Politeknik", "Akademi", "Akademik", "Sekolah"). Bila tak ada kata tersisa, pakai huruf pertama nama. Huruf Archivo 600 pada kotak `tintaAngkat`, tanpa lingkaran warna.

## 9. Tulisan di antarmuka

Indonesia baku sehari-hari, kalimat pendek, kata kerja aktif, sentence case. Tanpa tanda seru, tanpa emoji, tanpa "Oops", tanpa permintaan maaf, tanpa tanda pisah panjang. Satu istilah satu makna di seluruh aplikasi:

- "Kampus" dipakai untuk semua perguruan tinggi di antarmuka. Satu-satunya pengecualian adalah label "Kode PT", yang mengikuti istilah sumber.
- "Coba lagi" berarti mengulang permintaan yang gagal. "Perbarui data" berarti mengunduh ulang daftar kampus secara manual. Keduanya tidak dipertukarkan.
- "Tingkat kelulusan" untuk satu kampus, "Persen lulus" untuk satu bidang ilmu.

| Konteks | Teks |
|---|---|
| Placeholder pencarian | Cari nama, kode, atau kota |
| Hitungan hasil | 312 dari 4.342 kampus |
| Hasil kosong, tanpa filter | Tidak ada kampus yang cocok dengan “xyz”. Coba kode 6 digit atau satu kata dari nama. |
| Hasil kosong, dengan filter | Tidak ada kampus yang cocok dengan filter ini. (tombol: Hapus filter) |
| Unduhan pertama | Mengunduh daftar kampus. 0,4 dari 1,2 MB. Bila total tidak diketahui: Mengunduh daftar kampus (sekitar 1,2 MB). |
| Setelah unduhan | Menyiapkan peta |
| Offline dengan cache | Offline. Data diunduh 28 Oktober 2026. |
| Offline tanpa cache | Daftar kampus belum pernah diunduh dan tidak ada sambungan internet. (tombol: Coba lagi) |
| Server galat | PDDikti tidak merespons (kode 503). (tombol: Coba lagi) |
| Waktu habis | Sambungan terlalu lambat. Coba lagi. |
| Koordinat kosong | Lokasi belum diisi oleh kampus. |
| Koordinat tidak valid | Koordinat dari kampus berada di luar Indonesia, jadi tidak digambar. |
| Koordinat dikoreksi | Lintang dan bujur di sumber tertukar. Sudah dibetulkan. |
| Kota kosong | Kota belum diisi |
| Kelulusan bernilai 0 | Belum ada data |
| Kelulusan gagal dimuat | Tingkat kelulusan belum bisa dimuat. (tombol: Coba lagi) |
| Info tingkat kelulusan | Angka dari PDDikti. Periode dan cara menghitungnya tidak dijelaskan di API, jadi jangan dipakai untuk membandingkan kampus. |
| Info bidang ilmu | Jumlah semua baris tabel ini ({jumlah}) berbeda dengan angka Mahasiswa di atas ({angka}). PDDikti tidak menjelaskan perbedaannya. Persen lulus mengikuti angka dari PDDikti. |
| Tautan keluar | Buka dropbox.com di peramban? (tombol: Buka, Batal) |
| Tentang | Aplikasi ini tidak resmi dan tidak berafiliasi dengan Kemdiktisaintek. Data berasal dari pddikti.kemdiktisaintek.go.id. |

Galat tidak pernah samar. Pesan menyebut apa yang terjadi dan apa yang bisa dilakukan, dengan suara antarmuka, bukan suara orang.

## 10. Gerak

Hanya ada satu gerak yang berjalan sendiri, dan itu disengaja: **sapuan titik**. Saat Beranda pertama kali menampilkan peta setelah aplikasi dibuka, titik muncul dari barat ke timur (urut `x` naik) selama 1.100ms dengan `Curves.easeInOut`, sebanyak fraksi titik, bukan fraksi jarak. Sumatera menyala duluan, lalu Jawa menumpuk, lalu Papua. Hanya sekali per peluncuran aplikasi. Tidak diulang saat berpindah tab atau saat filter berubah.

Selain itu gerak hanya sebagai jawaban atas tindakan pengguna: bottom sheet naik 240ms `Curves.easeOutCubic`; perubahan nyala titik saat filter berubah 200ms; transisi halaman bawaan platform. Tidak ada animasi masuk pada baris daftar, tidak ada angka ledger yang menghitung naik dari nol (itu penanda tampilan buatan generator), dan tidak ada efek hover.

Bila `MediaQuery.disableAnimationsOf(context)` bernilai `true`, titik langsung tampil penuh dan semua durasi menjadi nol.

## 11. Arsitektur

MVVM dengan Riverpod, Dio, dan go_router, sesuai stack proyek. Tanpa code generation: model ditulis tangan (enam model kecil), provider ditulis manual tanpa `riverpod_generator`. Versi paket: pakai versi stabil terbaru saat dikerjakan lewat `flutter pub add`. Flutter 3.27 atau lebih baru (butuh `Color.withValues` dan `WidgetStateProperty`).

### 11.1 Paket

```text
flutter pub add flutter_riverpod dio go_router intl url_launcher path_provider cached_network_image flutter_widget_from_html_core phosphor_flutter collection
```

Tidak memakai `flutter_map`, `fl_chart`, `google_fonts`, dan paket shimmer. Alasannya di bagian 16. Panggil `initializeDateFormatting('id_ID')` di `main()` sebelum `runApp`.

Bagian font di `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/alias.json
  fonts:
    - family: Archivo
      fonts:
        - asset: assets/fonts/Archivo-Variable.ttf
    - family: SourceSerif4
      fonts:
        - asset: assets/fonts/SourceSerif4-Variable.ttf
```

### 11.2 Struktur folder

```text
lib/
  main.dart
  app.dart                      MaterialApp.router, tema, themeMode dark
  router.dart                   rute dan StatefulShellRoute
  core/
    theme/tokens.dart           Warna, Gaya, jarak (bagian 13.2)
    theme/tema.dart             buatTema()
    net/dio_klien.dart          konfigurasi Dio, retry, user-agent
    net/galat.dart              sealed class Galat
    format/angka.dart           NumberFormat id_ID
    format/tanggal.dart         DateFormat id_ID
    html/html_bersih.dart       sanitizer daftar putih
  data/
    model/koordinat.dart        + normalisasiKoordinat
    model/kampus.dart
    model/beranda.dart          Statistik, BidangIlmu
    model/pengumuman.dart
    model/publikasi.dart
    model/halaman.dart          Halaman<T> dengan pagination
    sumber/api_sumber.dart      semua panggilan Dio
    sumber/cache_berkas.dart    baca dan tulis berkas JSON + meta waktu
    repo/kampus_repo.dart
    repo/beranda_repo.dart
    repo/kabar_repo.dart
    repo/kelulusan_repo.dart
  fitur/
    beranda/
      beranda_layar.dart
      beranda_vm.dart
      peta/peta_painter.dart
      peta/peta_tertanam.dart
      peta/peta_penuh_layar.dart
      peta/grid_ketuk.dart
      bidang_ilmu_tabel.dart
      ledger.dart               widget ledger bersama (dipakai juga di detail)
    kampus/
      kampus_layar.dart
      kampus_vm.dart
      filter_sheet.dart
      indeks_pencarian.dart     bagian 13.4
      detail_layar.dart
      detail_vm.dart
      logo_kampus.dart          logo + monogram
    kabar/
      kabar_layar.dart
      pengumuman_vm.dart
      publikasi_vm.dart
      pengumuman_detail_layar.dart
      tautan_keluar_sheet.dart
    tentang/tentang_layar.dart
assets/
  alias.json
  fonts/                        berkas variabel + lisensi OFL
tool/buat_ikon.dart
test/fixtures/locations_full.json   salinan penuh dari berkas tangkapan asli
```

Perhatian: contoh respons `/api/pt/locations` di `paths/pt-locations.json` sudah dipotong menjadi 5 record. Fixture uji harus berasal dari berkas tangkapan asli yang berisi 4.342 record.

### 11.3 Provider

| Provider | Tipe | Tanggung jawab |
|---|---|---|
| `dioProvider` | `Provider<Dio>` | Klien HTTP tunggal |
| `daftarKampusProvider` | `AsyncNotifierProvider` | Memuat cache atau unduh, parse di isolate (`Isolate.run`), bangun indeks pencarian, proyeksikan dan urutkan titik. State: daftar `Kampus`, indeks, `Float32List` titik, waktu unduh |
| `kampusQueryProvider` | `NotifierProvider<KampusQuery>` | q, kelompok, pembina, kota. Satu sumber kebenaran |
| `hasilKampusProvider` | `Provider` (turunan) | Daftar hasil terurut, himpunan `kode` yang cocok, dua `Float32List` peta (`redup`, `sorot`) |
| `berandaProvider` | `FutureProvider` | Statistik dan bidang ilmu |
| `detailKampusProvider` | `Provider.family<Kampus?, String>` | Cari menurut `kode` |
| `kelulusanProvider` | `FutureProvider.family<Kelulusan, String>` | Ambil `idSp` dari daftar menurut `kode`, panggil API, cache |
| `pengumumanProvider` | `AsyncNotifierProvider` | Halaman, pencarian, pagination |
| `publikasiProvider` | `AsyncNotifierProvider` | Sama |
| `capabilitiesProvider` | `Provider<Capabilities>` | Konstanta |

Alur: View (widget) membaca ViewModel (Notifier) yang memanggil Repository, yang memanggil sumber data (Dio atau berkas). Widget tidak pernah memanggil Dio langsung.

### 11.4 Capabilities

```dart
class Capabilities {
  const Capabilities({
    this.cariProdi = false,
    this.cariDosen = false,
    this.cariMahasiswa = false,
    this.akreditasi = false,
  });
  final bool cariProdi, cariDosen, cariMahasiswa, akreditasi;
}
```

Semua `false` di versi 1. Ketika endpoint ditemukan dan didokumentasikan di `paths/`, ubah ke `true`, tambahkan repositori dan layarnya, dan perbarui dokumen ini. UI untuk fitur ber-flag `false` tidak dirender.

## 12. Jaringan dan cache

### 12.1 Dio

Base URL `https://pddikti.kemdiktisaintek.go.id`. Timeout sambung 10 detik. Timeout terima 15 detik, kecuali `locations` 60 detik. Hanya permintaan GET. Ulangi maksimal dua kali dengan jeda 400ms lalu 1.200ms, hanya untuk waktu habis, gagal sambung, dan 5xx. Tidak mengulang 4xx. Maksimal 4 permintaan paralel (logo di daftar dimuat malas dan dibatalkan lewat `CancelToken` saat baris keluar layar).

`User-Agent`: `PDDiktiMobile/<versi> (tidak resmi)`. Aplikasi mengaku apa adanya dan tidak menyamar sebagai peramban. Bila server menolak karena itu, jangan menyamar: itu tanda untuk menghubungi pengelola PDDikti.

`onReceiveProgress` dipakai untuk unduhan `locations`. Bila `total` bernilai -1 (respons chunked atau terkompresi), tampilkan versi teks tanpa angka kemajuan (bagian 9).

Galat dipetakan ke satu `sealed class Galat`: `TanpaJaringan`, `WaktuHabis`, `Server(int kode)` untuk 5xx, `Ditolak(int kode)` untuk 4xx, `FormatTakTerduga`. Parsing harus toleran: field yang hilang atau berubah tipe tidak boleh membuat aplikasi crash. Model memakai tipe nullable dan nilai bawaan yang aman, karena skema ini bisa berubah tanpa pemberitahuan.

### 12.2 Cache

| Data | Tempat | Kunci | TTL | Perilaku |
|---|---|---|---|---|
| `locations` | Berkas `locations.json` dan `locations.meta.json` di application support | Tetap | 7 hari | Tampilkan cache seketika. Bila lewat TTL, unduh ulang di latar. Bila gagal, tetap pakai cache |
| `beranda` | Berkas | Tetap | 24 jam | Sama |
| Pengumuman dan publikasi, halaman 1 | Memori | `search` dan `page` | 6 jam | Muat ulang saat tarik layar |
| Logo | Cache gambar di disk | `logo_<kode>` | 30 hari | Gagal 4xx: monogram, jangan ulangi sampai `locations` diperbarui |
| Kelulusan | Berkas `kelulusan.json`, peta `kode` ke `{nilai, waktu}` | `kode` | 24 jam | Gagal: pesan dengan tombol "Coba lagi" |

Setiap kali `locations` diperbarui, `id_sp` baru menggantikan yang lama, dan catatan "logo gagal" dihapus.

Aplikasi hanya membaca. Tidak ada data pribadi yang disimpan, tidak ada analytics pihak ketiga, dan tidak ada pelaporan crash di versi 1.

## 13. Kode acuan

Kode di bagian ini adalah implementasi acuan. Boleh disesuaikan agar compile di versi Flutter yang dipakai, tetapi nilai dan perilakunya tidak boleh berubah tanpa mengubah dokumen ini.

### 13.1 Berkas yang dibutuhkan

Unduh Archivo dan Source Serif 4 (versi variabel, OFL) dari sumber resmi masing-masing, ganti namanya menjadi `Archivo-Variable.ttf` dan `SourceSerif4-Variable.ttf`, dan taruh di `assets/fonts/`.

### 13.2 Token dan tema (`core/theme/tokens.dart`, `tema.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class Warna {
  static const tinta = Color(0xFF1A1F33);
  static const tintaAngkat = Color(0xFF242A44);
  static const garis = Color(0xFF3A4266);
  static const garisTegas = Color(0xFF6F79A3);
  static const kapur = Color(0xFFECE7DA);
  static const kapurRedup = Color(0xFFA9AEC4);
  static const kunyit = Color(0xFFF0B429);
  static const laut = Color(0xFF5CC8B8);
  static const karang = Color(0xFFE8826B);

  static Color get titikBiasa => kapur.withValues(alpha: 0.38);
  static Color get titikRedup => kapur.withValues(alpha: 0.18);
}

abstract final class Jarak {
  static const double s4 = 4, s8 = 8, s12 = 12, s16 = 16, s20 = 20, s24 = 24, s32 = 32;
}

abstract final class Gaya {
  static TextStyle _archivo(
    double ukuran,
    double tinggiBaris,
    int bobot, {
    double lebar = 100,
    bool tabular = false,
    Color warna = Warna.kapur,
  }) =>
      TextStyle(
        fontFamily: 'Archivo',
        fontSize: ukuran,
        height: tinggiBaris / ukuran,
        fontWeight: FontWeight.values[(bobot ~/ 100) - 1],
        fontVariations: [
          FontVariation('wght', bobot.toDouble()),
          FontVariation('wdth', lebar),
        ],
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
        letterSpacing: 0,
        color: warna,
      );

  static final judulLayar = _archivo(24, 30, 600);
  static final namaDetail = _archivo(22, 28, 600, lebar: 87);
  static final namaBaris = _archivo(16, 21, 600, lebar: 90);
  static final isi = _archivo(15, 22, 400);
  static final tombol = _archivo(15, 20, 600);
  static final label = _archivo(13, 18, 500, warna: Warna.kapurRedup);
  static final angka = _archivo(17, 22, 500, tabular: true);
  static final catatan = _archivo(12, 16, 400, warna: Warna.kapurRedup);

  static const bacaan = TextStyle(
    fontFamily: 'SourceSerif4',
    fontSize: 16,
    height: 26 / 16,
    color: Warna.kapur,
  );
}
```

```dart
ThemeData buatTema() {
  const skema = ColorScheme(
    brightness: Brightness.dark,
    primary: Warna.kunyit,
    onPrimary: Warna.tinta,
    secondary: Warna.laut,
    onSecondary: Warna.tinta,
    error: Warna.karang,
    onError: Warna.tinta,
    surface: Warna.tinta,
    onSurface: Warna.kapur,
    onSurfaceVariant: Warna.kapurRedup,
    outline: Warna.garisTegas,
    outlineVariant: Warna.garis,
    surfaceContainerLowest: Warna.tinta,
    surfaceContainerLow: Warna.tinta,
    surfaceContainer: Warna.tintaAngkat,
    surfaceContainerHigh: Warna.tintaAngkat,
    surfaceContainerHighest: Warna.tintaAngkat,
  );

  OutlineInputBorder batas(Color warna, double tebal) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: warna, width: tebal),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: skema,
    scaffoldBackgroundColor: Warna.tinta,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Warna.tintaAngkat,
    hoverColor: Colors.transparent,
    fontFamily: 'Archivo',
    appBarTheme: AppBarTheme(
      backgroundColor: Warna.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: Gaya.judulLayar,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Warna.tinta,
      ),
    ),
    dividerTheme: const DividerThemeData(color: Warna.garis, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Warna.tintaAngkat,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: Gaya.isi.copyWith(color: Warna.kapurRedup),
      border: batas(Warna.garisTegas, 1),
      enabledBorder: batas(Warna.garisTegas, 1),
      focusedBorder: batas(Warna.kunyit, 2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Warna.tinta,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => Gaya.label.copyWith(
          color: s.contains(WidgetState.selected) ? Warna.kunyit : Warna.kapurRedup,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 22,
          color: s.contains(WidgetState.selected) ? Warna.kunyit : Warna.kapurRedup,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Warna.tintaAngkat,
      modalBarrierColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Warna.kunyit,
        foregroundColor: Warna.tinta,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Gaya.tombol,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Warna.kapur,
        side: const BorderSide(color: Warna.garisTegas),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: Gaya.tombol,
      ),
    ),
  );
}
```

Dilarang memakai `ColorScheme.fromSeed` atau `colorSchemeSeed`. Skema ditulis penuh, seperti di atas.

### 13.3 Model kampus dan normalisasi koordinat

```dart
class Koordinat {
  const Koordinat(this.lintang, this.bujur, {this.dikoreksi = false});
  final double lintang, bujur;
  final bool dikoreksi;
}

bool _dalamIndonesia(double lintang, double bujur) =>
    lintang >= -11.5 && lintang <= 6.5 && bujur >= 94.5 && bujur <= 141.5;

Koordinat? normalisasiKoordinat(String lintang, String bujur) {
  final a = double.tryParse(lintang.trim());
  final b = double.tryParse(bujur.trim());
  if (a == null || b == null) return null;
  if (_dalamIndonesia(a, b)) return Koordinat(a, b);
  if (_dalamIndonesia(b, a)) return Koordinat(b, a, dikoreksi: true);
  return null;
}

class Kampus {
  const Kampus({
    required this.kode,
    required this.nama,
    required this.kelompok,
    required this.pembina,
    required this.idSp,
    this.kota,
    this.koordinat,
  });

  final String kode; // sudah di-trim, kunci stabil
  final String nama;
  final String kelompok; // "N/A" dipetakan ke "Lainnya"
  final String pembina;
  final String? kota; // null bila kosong atau "Tidak Diisi"
  final String idSp; // token buram, jangan dipakai sebagai kunci
  final Koordinat? koordinat;

  factory Kampus.fromJson(Map<String, dynamic> j) {
    String teks(String k) => ((j[k] as String?) ?? '').trim();
    final kota = teks('kab_kota');
    final kelompok = teks('kelompok');
    return Kampus(
      kode: teks('kode'),
      nama: teks('nama'),
      kelompok: kelompok == 'N/A' ? 'Lainnya' : kelompok,
      pembina: teks('pembina'),
      idSp: (j['id_sp'] as String?) ?? '',
      kota: (kota.isEmpty || kota == 'Tidak Diisi') ? null : kota,
      koordinat: normalisasiKoordinat(teks('lintang'), teks('bujur')),
    );
  }
}
```

### 13.4 Indeks dan skor pencarian

```dart
String normalisasi(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class EntriIndeks {
  EntriIndeks(this.kampus)
      : nama = normalisasi(kampus.nama),
        kota = normalisasi(kampus.kota ?? ''),
        kata = normalisasi(kampus.nama).split(' ') {
    inisial = kata
        .where((w) => w.isNotEmpty && !_sambung.contains(w))
        .map((w) => w[0])
        .join();
  }

  final Kampus kampus;
  final String nama, kota;
  final List<String> kata;
  late final String inisial;

  static const _sambung = {'dan', 'di', 'of', 'the', 'untuk'};
}

final _semuaAngka = RegExp(r'^\d+$');

int skor(EntriIndeks e, String q, List<String> kataQ) {
  if (e.kampus.kode == q) return 1000;
  if (_semuaAngka.hasMatch(q)) return e.kampus.kode.startsWith(q) ? 900 : 0;
  if (e.nama == q) return 850;
  if (e.nama.startsWith(q)) return 800;
  if (e.inisial == q) return 700;
  if (kataQ.every((t) => e.kata.any((w) => w.startsWith(t)))) {
    return 600 - e.kata.length;
  }
  if (e.nama.contains(q)) return 400;
  if (e.kota.contains(q)) return 200;
  return 0;
}
```

Pemakaian: `q = normalisasi(input)`, `kataQ = q.split(' ')`, saring `skor > 0`, urut menurun menurut skor lalu nama.

### 13.5 Painter peta titik

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';

class PetaTitikPainter extends CustomPainter {
  PetaTitikPainter({
    required this.redup,
    required this.sorot,
    required this.kontrol,
    required this.sapuan,
    required this.adaFilter,
  }) : super(repaint: Listenable.merge([kontrol, sapuan]));

  /// Koordinat ternormalisasi (x 0..1, y 0..0,383), urut dari barat ke timur.
  final Float32List redup;
  final Float32List sorot;
  final TransformationController kontrol;
  final Animation<double> sapuan; // 0..1
  final bool adaFilter;

  @override
  void paint(Canvas canvas, Size size) {
    final m = kontrol.value;
    final skala = m.getMaxScaleOnAxis();
    canvas.save();
    canvas.transform(m.storage);
    canvas.scale(size.width); // ruang kerja: lebar = 1

    final diameter =
        (1.8 * math.sqrt(skala)).clamp(1.8, 6.0) / (size.width * skala);

    final cat = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = diameter
      ..color = adaFilter ? Warna.titikRedup : Warna.titikBiasa;

    final n = (redup.length ~/ 2 * sapuan.value).floor() * 2;
    canvas.drawRawPoints(
      PointMode.points,
      Float32List.sublistView(redup, 0, n),
      cat,
    );

    if (sorot.isNotEmpty) {
      cat
        ..color = Warna.kunyit
        ..strokeWidth = diameter * 1.4;
      canvas.drawRawPoints(PointMode.points, sorot, cat);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PetaTitikPainter old) =>
      old.redup != redup || old.sorot != sorot || old.adaFilter != adaFilter;
}
```

Uji ketuk: balikkan matriks (`Matrix4.inverted(kontrol.value)`), terapkan ke posisi ketuk dengan `MatrixUtils.transformPoint`, bagi hasilnya dengan `size.width` untuk mendapat koordinat ternormalisasi, lalu cari di indeks grid.

## 14. Aksesibilitas dan performa

**Kontras.** Semua pasangan teks dan latar di bagian 4.2 melewati 4,5 banding 1. Batas kontrol interaktif melewati 3 banding 1. Garis pemisah baris sengaja tidak, karena dekoratif.

**Target sentuh** minimal 48dp, termasuk chip filter dan ikon info.

**Skala teks.** Layar diuji sampai 1,5 kali. Tidak ada tinggi tetap pada teks. Nama kampus terpanjang (92 karakter) harus terbaca penuh di detail pada 1,5 kali. Peta tidak ikut berskala.

**Pembaca layar.** Ledger dibaca per baris ("Dosen, 303.067"); garis titik-titik dikeluarkan dengan `ExcludeSemantics`. Peta punya label ringkas (bagian 6.7). Tombol ikon semua punya `tooltip` atau `Semantics.label`.

**Papan ketik dan fokus.** Cincin fokus `kunyit` 2dp pada semua kontrol.

**Tidak bergantung pada warna.** Titik yang cocok filter selalu didampingi hitungan teks.

**Anggaran performa.** Dengan cache, frame pertama di bawah 1,5 detik pada Android RAM 3 GB. Parse, indeks, dan proyeksi di isolate di bawah 400ms. Filter dan skor 4.342 entri di bawah 16ms. Pan dan zoom peta 60 fps pada 3.447 titik (satu panggilan gambar per lapisan). Tidak ada paket peta atau tile dalam APK.

## 15. Dilarang

Daftar ini ada karena pola-pola ini muncul otomatis pada aplikasi buatan generator, apa pun topiknya.

1. Gradien dalam bentuk apa pun, termasuk "wash" tipis di latar.
2. Glassmorphism, blur latar, atau efek kaca.
3. Bayangan (`BoxShadow`, `elevation` bukan nol, `Material(elevation:)`).
4. Kartu: kontainer membulat berbayang atau berbingkai untuk membungkus item daftar atau statistik.
5. Ikon di dalam lingkaran atau kotak berwarna, apa pun fungsinya.
6. Empat kotak statistik besar berjajar di bawah hero.
7. Angka yang menghitung naik dari nol saat tampil.
8. Teks sapaan: "Halo!", "Selamat datang di PDDikti".
9. Emoji di antarmuka, di string, atau di pesan galat.
10. Tanda pisah panjang atau pendek di string antarmuka.
11. Label huruf kapital semua atau berjarak lebar di atas judul.
12. Garis pemisah dekoratif dengan label ("OVERVIEW", "STATISTIK").
13. Badge "Baru", "Segera hadir", "Beta", atau titik notifikasi.
14. Ilustrasi stok, ilustrasi kosong berupa gambar, atau maskot.
15. Animasi masuk (fade, slide-up) pada baris daftar, dan efek hover.
16. Shimmer skeleton. Gunakan teks kemajuan yang jujur.
17. `ColorScheme.fromSeed`, `colorSchemeSeed`, dan warna bawaan Material (biru, ungu).
18. Ripple dan `InkSparkle`.
19. Indikator pil pada navigation bar.
20. FAB (floating action button).
21. Warna merah atau hijau untuk menilai angka.
22. Peringkat, "top 10", "kampus terbaik", atau urutan berdasarkan kelulusan sebagai tampilan utama.
23. Teks rata kanan-kiri.
24. Font monospace untuk label data.
25. Logo, warna ungu, atau nama "resmi" yang mengesankan aplikasi ini milik pemerintah.
26. Mengubah kapitalisasi atau memotong nama kampus dari API.
27. Menyimpan `id_sp` sebagai kunci cache atau parameter rute.

## 16. Keputusan yang ditolak

| Opsi | Alasan ditolak |
|---|---|
| Peta tile (`flutter_map` dengan tile OpenStreetMap) | Butuh jaringan, kebijakan tile OSM membatasi pemakaian aplikasi berskala besar, dan 3.447 penanda di atas basemap berubah menjadi bukit penanda. Titik tanpa basemap lebih jujur: persebaran menjadi bentuk |
| Tema terminal hijau atau HUD siber | Nada main-main untuk keperluan memastikan sebuah kampus terdaftar, dan hijau neon di atas gelap adalah default yang sangat umum |
| Warna per kelompok di peta | Pelangi membuat orang membaca warna, bukan persebaran. Warna kunyit dicadangkan untuk "cocok dengan query" |
| Peringkat kelulusan | Definisi angka tidak diketahui, nol bisa berarti kosong (bagian 3) |
| Indeks A sampai Z | Huruf awal nama tidak membedakan (bagian 7) |
| Mode terang di versi 1 | Menggandakan pekerjaan uji kontras tanpa mengubah tugas utama. Token sudah siap untuk ditambahkan |
| `google_fonts` saat runtime | Butuh jaringan dan menghubungi pihak ketiga |
| Shimmer skeleton | Generik, dan untuk unduhan 1,2 MB teks kemajuan lebih informatif |
| Halaman kegiatan | Tidak ada endpoint sendiri, hanya satu item di dalam `/api/beranda` |
| Memakai angka beranda sebagai penyebut persen bidang ilmu | Dua ukuran berbeda (bagian 2.2) |
| Tab Tentang | Layar yang dibuka sekali seumur pemakaian tidak layak mendapat satu dari tiga tab |

## 17. Asumsi yang harus diverifikasi

Tandai selesai setelah diuji di perangkat, dan perbarui dokumen ini bila hasilnya berbeda.

- [ ] Gambar publikasi: `thumbnail` berupa path relatif dan diasumsikan relatif terhadap `https://pddikti.kemdiktisaintek.go.id`.
- [ ] Masa berlaku `id_sp`: apakah token dari `locations` tetap berlaku untuk `/logo` dan `/graduation-rate` setelah satu hari, tujuh hari? TTL cache 7 hari bergantung pada ini. Rancangan sudah menangani kegagalan, tetapi TTL mungkin harus lebih pendek.
- [ ] Arti `graduation_rate` bernilai 0 dengan `id_sp` pendek: diasumsikan "tidak ada data".
- [ ] Definisi `persentase_kelulusan` dan `total_mahasiswa` per bidang ilmu, dan alasan jumlahnya 4,77 kali `jumlah_mahasiswa`.
- [ ] Apakah server menolak tanpa header tertentu (`Origin`, `Referer`) atau pada `User-Agent` jujur. Bila ya, jangan menyamar sebagai peramban.
- [ ] Stabilitas endpoint: ini endpoint internal situs tanpa jaminan. Pantau perubahan skema.
- [ ] Apakah `FontFeature.tabularFigures()` berpengaruh pada berkas Archivo yang dibundel. Bila tidak, ledger memakai lebar kolom tetap untuk angka.
- [ ] Kepanjangan kelompok untuk glosarium di layar Tentang: PTN (negeri), PTS (swasta), PTA (keagamaan), PTK (kedinasan di bawah kementerian atau lembaga), PTLN (luar negeri), LLDIKTI (lembaga layanan pendidikan tinggi, pembina PTS per wilayah). Ini disimpulkan dari nilai di data, belum dari sumber resmi.
- [ ] `content_limit=1` diterima server pada `/api/beranda` (konten tidak dipakai, jadi payload bisa diperkecil).
- [ ] Penyebab selisih 74 kampus antara 4.416 (beranda) dan 4.342 (`locations`).

## 18. Kriteria selesai versi 1

Uji ini memakai fixture lengkap `test/fixtures/locations_full.json`.

- [ ] Parsing menghasilkan 4.342 `Kampus`. Tidak ada `kode` yang mengandung spasi. Tidak ada `kode` ganda.
- [ ] Setelah normalisasi koordinat: 3.447 titik layak digambar, 17 berstatus `dikoreksi`, 48 dibuang.
- [ ] Akademi Kepolisian (AKPOL), kode 484001, berstatus `dikoreksi` dan terplot di sekitar lintang -7,02 dan bujur 110,42.
- [ ] Mencari `233108` menempatkan Sekolah Tinggi Teologi Apostolic Jakarta di urutan pertama. Mencari `akpol` menemukan Akademi Kepolisian (AKPOL).
- [ ] Filter kelompok PTN menghasilkan 127 kampus, dan hitungan di peta serta daftar sama-sama 127.
- [ ] Setelah satu kali unduhan berhasil, mode pesawat tidak mengganggu Beranda, Kampus, dan detail (selain logo dan kelulusan yang belum pernah dimuat).
- [ ] Cold start dengan cache sampai peta tampil di bawah 1,5 detik pada Android RAM 3 GB.
- [ ] Detail kampus "Sekolah Tinggi Agama Kristen Reformed Remnant Internasional Minahasa Provinsi Sulawesi Utara" terbaca penuh pada skala teks 1,5 kali, tanpa elipsis.
- [ ] Pencarian dan filter pada 4.342 entri selesai di bawah 16ms.
- [ ] Pemeriksaan teks otomatis lolos: tidak ada karakter tanda pisah panjang atau pendek di `lib/` dan `assets/`; `grep -rE "BoxShadow|elevation: [1-9]|fromSeed|colorSchemeSeed|LinearGradient|RadialGradient|BackdropFilter" lib/` tidak menghasilkan apa pun.
- [ ] Setiap string pada tabel bagian 9 muncul persis di aplikasi, dan tidak ada string antarmuka lain yang melanggar aturan sentence case.
