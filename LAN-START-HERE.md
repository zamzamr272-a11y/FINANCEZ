# Mulai NEXORA di Laptop + HP (Wi-Fi yang Sama)

**Tidak perlu VPS.** Backend dan PostgreSQL berjalan di laptop kamu; HP Android mengaksesnya melalui Wi-Fi rumah/kantor yang sama.

## Sebelum mulai

- Instal dan jalankan Docker Desktop (Linux containers).
- Sambungkan laptop dan HP ke Wi-Fi pribadi yang sama.
- Pastikan Windows Wi-Fi profile adalah `Private` (hanya pada jaringan tepercaya).
- Pada build pertama, laptop perlu internet untuk mengambil base image dan dependency Docker. Sesudah image terbangun, backend dapat berjalan di LAN tanpa VPS.

## Urutan pemasangan

1. Ekstrak ZIP. Buka folder `NEXORA`.
2. Klik kanan `Allow-NEXORA-Firewall.bat` → **Run as administrator**. Setujui UAC.
3. Klik dua kali `Start-NEXORA-LAN.bat`. Script membuat `.env` dengan secret acak, menjalankan Docker Compose, lalu menampilkan IP laptop.
4. Di browser laptop, buka `http://localhost:8000/`.
5. Di Chrome HP, buka `http://IP-LAPTOP:8000/health` dan pastikan terlihat `status: ok`.
6. Upload source ke repository GitHub. Pada **Actions → Build Android APK → Run workflow**, jalankan dengan `signed_release=false`.
7. Download artifact `NEXORA-Android-LAN-debug-APK`, ekstrak `app-debug.apk`, lalu instal ke HP.
8. Di NEXORA HP → Profil → Koneksi backend → Konfigurasi, masukkan `http://IP-LAPTOP:8000/api/v1` (ganti dengan IP yang ditampilkan laptop). Tekan **Simpan & uji koneksi**.
9. Buat akun uji dan simpan recovery code.

## Tombol pengelolaan

- `Start-NEXORA-LAN.bat` — mulai backend, database, worker.
- `Status-NEXORA-LAN.bat` — status service dan IP laptop.
- `Stop-NEXORA-LAN.bat` — hentikan service tanpa menghapus database.
- `Allow-NEXORA-Firewall.bat` — buat aturan firewall terbatas pada Private/LocalSubnet.

## Sangat penting

- Di HP fisik, **jangan** memakai `localhost` atau `127.0.0.1`. Itu menunjuk ke HP sendiri. Gunakan IP Wi-Fi laptop.
- Jangan memakai Wi-Fi Guest atau jaringan dengan client/AP isolation.
- Jangan membuat port forwarding router. PostgreSQL tidak diekspos ke LAN.
- Jangan hapus named Docker volume dan jangan jalankan `docker compose down -v` bila ingin mempertahankan data.
- APK LAN adalah debug build yang memakai HTTP lokal. HTTP tidak mengenkripsi data di jalur Wi-Fi. Pakai WPA2/WPA3 pribadi yang tepercaya; jangan gunakan jaringan publik atau APK ini untuk rilis publik.
- Laptop harus tetap menyala, tidak sleep, dan Docker Desktop tetap berjalan saat HP memakai NEXORA.

Panduan lengkap dan troubleshooting ada di [`docs/LAN_LOCAL_SERVER.md`](docs/LAN_LOCAL_SERVER.md).
