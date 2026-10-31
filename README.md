# PDDikti Mobile

Klien mobile modern, cepat, dan luring (*offline-first*) untuk mengakses data publik Pangkalan Data Pendidikan Tinggi (PDDikti) Kementerian Pendidikan Tinggi, Sains, dan Teknologi Republik Indonesia.

Aplikasi ini dibangun menggunakan **Flutter 3 / Dart 3**, berarsitektur **Riverpod**, tema gelap profesional (**Dark Indigo & Kunyit** sesuai `DESIGN.md`), bebas dari bayangan dan kartu bertumpuk, serta dilengkapi sistem pembaruan mandiri (*Over-The-Air / OTA Update*) yang aman.

---

## Fitur Utama

1. **Peta Sebaran Kampus & Siluet Indonesia Luring**
   - Vektor peta kepulauan Indonesia (32 provinsi, 290 poligon cincin) dirender native 60/120 FPS tanpa memuat *tile server* pihak ketiga.
   - 3.447 titik koordinat kampus terproyeksi *equirectangular* presisi, mendukung interaksi ketuk deteksi kampus terdekat, pan, dan zoom hingga 12x.
2. **Pencarian Terpadu Real-Time (Direct Gateway)**
   - Menghubungkan langsung ke REST gateway `https://api-pddikti.kemdiktisaintek.go.id` secara paralel tanpa terhalang Cloudflare Turnstile web bot challenge.
   - Mendukung pencarian instan: Mahasiswa (nama/NIM), Dosen (nama/NIDN), Program Studi, dan Perguruan Tinggi.
3. **Format Data Profil Lengkap**
   - Tampilan profil mahasiswa 8 atribut resmi:
     - Nama | Perguruan Tinggi
     - Jenis Kelamin | Tanggal Masuk (format baku bahasa Indonesia)
     - NIM | Jenjang - Program Studi
     - Status Awal Mahasiswa | Status Terakhir Mahasiswa (Aktif per semester / Lulus)
   - Riwayat status perkuliahan per semester beserta SKS.
   - Detail kelulusan untuk alumni (Nomor Ijazah, Tanggal Keluar).
4. **Pembaruan Mandiri (OTA Update) Standar 2026**
   - Memeriksa pembaruan rilis langsung dari repositori GitHub secara berkala atau manual via menu *Tentang*.
   - Mengunduh berkas APK dengan indikator progres unduhan dan memvalidasi integritas berkas via *checksum* **SHA-256**.
   - Memicu penginstalan langsung ke sistem Android melalui `PackageInstaller`.

---

## Konfigurasi Penandatanganan APK (*Release Signing*)

Aplikasi menggunakan Android Gradle Plugin modern dengan Kotlin DSL (`build.gradle.kts`) yang mendukung skema tanda tangan **V1, V2, V3, dan V4**.

### 1. Membuat Keystore Produksi
Jalankan perintah berikut di terminal untuk menghasilkan berkas `upload-keystore.jks`:
```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pddikti_release
```

### 2. Menyiapkan `key.properties`
Salin berkas `android/key.properties.example` menjadi `android/key.properties`:
```properties
storePassword=password_keystore_anda
keyPassword=password_key_anda
keyAlias=pddikti_release
storeFile=upload-keystore.jks
```
> Berkas `android/key.properties` dan `*.jks` telah otomatis didaftarkan di `.gitignore` untuk mencegah kebocoran kredensial ke repositori publik.

---

## GitHub Actions & Otomatisasi Rilis (CI/CD)

Repositori ini telah dilengkapi alur kerja otomatis di `.github/workflows/release.yml`:
1. Setiap kali Anda membuat tag versi baru (misal: `git tag v1.0.1 && git push origin v1.0.1`):
   - GitHub Actions akan menjalankan `flutter analyze` dan `flutter test`.
   - Melakukan *build* APK rilis yang diobfuskasi (`--obfuscate --split-debug-info`).
   - Menghitung *checksum* SHA-256 berkas APK.
   - Menghasilkan manifest `version.json`.
   - Mengunggah rilis resmi ke GitHub Releases secara otomatis beserta berkas `app-release.apk`.

### Konfigurasi GitHub Secrets
Tambahkan rahasia berikut di pengaturan repositori Anda (**Settings > Secrets and variables > Actions**):
- `KEYSTORE_BASE64`: Isi berkas `upload-keystore.jks` yang di-encode ke Base64 (`base64 -w 0 android/upload-keystore.jks`).
- `KEY_ALIAS`: Alias kunci rilis (contoh: `pddikti_release`).
- `KEY_PASSWORD`: Password kunci Anda.
- `STORE_PASSWORD`: Password keystore Anda.

---

## Menjalankan & Membangun Aplikasi

### Persyaratan
- Flutter SDK 3.24+ (Dart 3.5+)
- Java 17

### Langkah Menjalankan
```bash
# 1. Unduh dependensi
flutter pub get

# 2. Jalankan pengujian
flutter test

# 3. Jalankan aplikasi di perangkat/emulator
flutter run
```

### Membangun Berkas APK Rilis
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```
Hasil APK akan berada di `build/app/outputs/flutter-apk/app-release.apk`.

---

## Lisensi & Batasan

Aplikasi ini bersifat tidak resmi (*unofficial*) dan tidak berafiliasi dengan Kementerian Pendidikan Tinggi, Sains, dan Teknologi Republik Indonesia. Seluruh data publik bersumber dari portal resmi PDDikti.
