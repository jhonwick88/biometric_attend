# Biometric Attend

Biometric Attend (\`biometric_attend\`) adalah aplikasi absensi modern berbasis Flutter yang mendukung otentikasi biometrik (sidik jari/pengenalan wajah) untuk proses absensi dan login yang cepat, aman, dan efisien.

Aplikasi ini menggunakan **Firebase** untuk pengelolaan pengguna dan basis data tersinkronisasi *real-time*.

## Daftar Fitur Unggulan

- **Manajemen Akun Terpusat**: Pendaftaran (*Register*) dan Masuk (*Login*) pengguna yang divalidasi dengan Firebase Authentication.
- **Biometric Quick Login**: Fitur login super cepat menggunakan otentikasi biometrik bawaan perangkat keras (Fingerprint/FaceID) yang diintegrasikan dengan penyimpanan kredensial yang aman (`flutter_secure_storage`).
- **Absensi Masuk & Keluar**: Layar khusus absensi masuk (*Check-in*) dan absensi pulang (*Check-out*) dengan indikator status harian.
- **Riwayat Absensi**: Menampilkan riwayat absensi harian yang memuat rekam jejak jam masuk dan keluar secara kronologis.
- **Validasi Lokasi (Geo-tagging)**: Memastikan pengguna berada di lokasi yang ditentukan sebelum dapat menekan tombol absensi (menggunakan `geolocator`).
- **State Management Modern**: Penulisan dan struktur kode rapi karena memanfaatkan arsitektur reaktif modern menggunakan `flutter_riverpod`.

## Flow / Alur Aplikasi

1. **Autentikasi (Pertama Kali)**
    - Pengguna baru harus mendaftar melalui tombol "Register".
    - Setelah berhasil atau jika sudah punya akun, masuk (*Login*) dengan Email dan Password.
    - Setiap login tersukses, kredensial pengguna akan dienkripsi dan disimpan secara rahasia di dalam perangkat.

2. **Autentikasi Biometrik (Sesi Berikutnya)**
    - Pengguna tidak lagi perlu mengingat/mengetik password secara repetitif. Cukup tekan layar **"Sidik Jari"** di halaman login. Tampilan verifikasi biometrik sistem akan mengambil alih. Proses login langsung berjalan instan dalam hitungan detik.

3. **Dashboard Absensi (Home)**
    - Aplikasi membaca waktu riil dan status pengguna saat ini.
    - Pada awal shift kerja, tekan **Absen Masuk**. Aplikasi melakukan validasi (termasuk cek koordinat GPS jika dikonfigurasi). Data jam masuk otomatis dicatat ke Cloud Firestore.
    - Daftar Riwayat di sebelah bawah akan menampilkan tanggal hari ini dengan status masuk.

4. **Selesai Bekerja**
    - Di penghujung hari, tekan tombol **Absen Pulang**. Firebase akan memperbarui (*update*) catatan kehadiran Anda untuk hari bersangkutan sehingga stempel jam pulang pun terekam.

## Memulai Proyek Ini

Jika ini adalah proyek Flutter pertama Anda, berikut beberapa panduan teknis yang bermanfaat:

- [Lab Pemrograman Flutter](https://docs.flutter.dev/get-started/codelab)
- [Sumber Belajar Flutter](https://docs.flutter.dev/reference/learning-resources)

### Prasyarat
Untuk menjalankan *source-code* secara optimal, pastikan hal berikut sudah siap di komputer Anda:
- Flutter SDK (Versi ~3.11.0 ke atas)
- Proyek Firebase yang sudah terkonfigurasi (File `google-services.json` untuk Android, `GoogleService-Info.plist` untuk iOS, dan `firebase_options.dart` untuk *Web/Multi-platform* harus ditambahkan).
- Fitur biometrik dan izin akses lokasi `AndroidManifest.xml` (sudah disesuaikan di paket aslinya).

### Langkah Instalasi
1. Clone repositori ini ke dalam direktori komputer Anda.
2. Buka terminal atau konsol perintah pada *root* proyek.
3. Jalankan `flutter pub get` untuk mengunduh semua direktori dependensi mulai dari `riverpod` hingga `local_auth`.
4. Jalankan `flutter run` pada emulator berfitur sistem biometrik atau melalui perangkat fisik langsung.
