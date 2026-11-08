# NEXORA Local LAN Server — Windows + Android

Panduan ini menjalankan backend dan PostgreSQL NEXORA di laptop Windows. HP Android mengakses aplikasi melalui Wi-Fi yang sama. Tidak diperlukan VPS atau port forwarding router.

## 1. Arsitektur dan batas akses

- **Laptop Windows:** Docker Desktop, FastAPI backend, PostgreSQL, recurring worker, dan web dashboard.
- **HP Android:** APK NEXORA. APK memanggil API laptop melalui IPv4 privat Wi-Fi, misalnya `http://192.168.1.25:8000/api/v1`.
- **Browser laptop:** dashboard dibuka pada `http://localhost:8000/`.
- **Database:** port PostgreSQL `5432` hanya berada pada jaringan internal Docker Compose. Tidak ada port database yang dipublikasikan ke Wi-Fi.
- **API:** satu-satunya port yang dibuka ke LAN adalah TCP `8000` (bisa diganti lewat `.env`). Aturan Windows Firewall dibatasi ke profil `Private` dan `LocalSubnet`.

Docker Desktop mempublikasikan port container ke host ketika port dipetakan; host firewall tetap mengatur apakah koneksi LAN diizinkan. Karena itu, konfigurasi ini memakai aturan firewall lokal dan tidak membuat port forwarding pada router.

## 2. Persyaratan laptop

1. Windows 10/11 64-bit dengan virtualisasi aktif.
2. Docker Desktop untuk Windows menggunakan Linux containers (WSL 2 disarankan).
3. PowerShell 5.1 atau PowerShell 7.
4. Wi-Fi/Ethernet rumah atau jaringan kantor tepercaya.
5. Ruang disk kosong untuk image Docker, database, dan dokumen yang diunggah. Sediakan ruang tambahan untuk backup.
6. HP Android terhubung ke SSID/jaringan lokal yang sama dengan laptop.

Docker harus menjalankan Linux containers. Setelah Docker Desktop dipasang, buka aplikasinya dan tunggu status Engine menjadi Running sebelum menjalankan NEXORA.

## 3. Pasang source ke laptop

1. Ekstrak `NEXORA-final-project.zip`.
2. Pastikan folder `NEXORA` berisi `docker-compose.yml`, `Dockerfile`, `backend`, `frontend`, dan `scripts`.
3. Simpan folder di lokasi yang stabil, contoh `C:\NEXORA`. Jangan menjalankan dari folder sementara Downloads yang sering dibersihkan.
4. Jangan mengunggah file `.env` ke GitHub. `.env` dihasilkan secara lokal oleh script setup dan harus tetap berada di laptop.

## 4. Buat secret lokal otomatis

Klik dua kali `Start-NEXORA-LAN.bat` untuk pertama kali. Script akan:

- memeriksa Docker CLI dan Docker Engine;
- membuat `.env` jika belum ada;
- menghasilkan `POSTGRES_PASSWORD` acak 256-bit dan `JWT_SECRET` acak 512-bit menggunakan cryptographic random generator;
- menetapkan zona waktu `Asia/Makassar`;
- membatasi CORS ke origin Android WebView yang digunakan aplikasi dan localhost;
- memvalidasi Docker Compose;
- membangun dan menjalankan container.

Secret tidak ditampilkan di terminal. Jangan mengirim file `.env` lewat chat/email dan jangan commit ke repository.

Jika `.env` sudah ada, script tidak menimpanya. Jangan gunakan opsi regenerasi secret pada database yang sudah berisi data kecuali kamu memahami dampaknya. Mengganti password PostgreSQL di `.env` saja tidak otomatis mengganti password role yang sudah tersimpan di volume PostgreSQL.

## 5. Ubah profil jaringan Windows menjadi Private

Aturan firewall NEXORA hanya berlaku pada profil `Private`.

Windows 11:

1. Buka Settings → Network & internet → Wi-Fi.
2. Pilih jaringan Wi-Fi yang sedang tersambung.
3. Pada Network profile type, pilih `Private` hanya untuk jaringan rumah/kantor yang kamu percaya.

Jangan mengubah jaringan publik, hotel, kafe, bandara, atau Wi-Fi bersama yang tidak kamu kendalikan menjadi Private.

## 6. Tambahkan aturan firewall LAN

Setelah profil Wi-Fi yang tepercaya menjadi Private:

1. Klik kanan `Allow-NEXORA-Firewall.bat` dan pilih Run as administrator, atau jalankan `scripts/windows/Allow-NEXORA-Firewall.ps1`.
2. Setujui UAC Windows.
3. Script membuat satu aturan inbound TCP untuk port `NEXORA_PORT` (default 8000), profil `Private`, sumber `LocalSubnet` saja.

Aturan ini tidak membuka router, tidak membuka database, dan tidak mengizinkan inbound dari profil Public. Jika port di `.env` diubah, jalankan ulang script firewall.

## 7. Jalankan server

Klik dua kali `Start-NEXORA-LAN.bat`.

Script menjalankan perintah setara dengan:

```powershell
docker compose config --quiet
docker compose up -d --build
```

Backend menjalankan `alembic upgrade head` ketika container API dimulai. Tunggu sampai health check `http://127.0.0.1:8000/health` mengembalikan status `ok`.

Script menampilkan alamat IP LAN laptop, dashboard, dan URL API. Contoh output:

```text
Dashboard : http://192.168.1.25:8000/
Android   : http://192.168.1.25:8000/api/v1
```

Alamat IP contoh di atas hanya ilustrasi. Gunakan alamat aktual yang ditampilkan oleh script pada laptopmu.

## 8. Uji melalui browser laptop

Di laptop, buka:

- Dashboard: `http://localhost:8000/`
- Health check: `http://localhost:8000/health`
- Dokumentasi API: `http://localhost:8000/docs`

Health check harus menampilkan JSON dengan `status: ok`. Jangan membagikan `/docs` ke internet; layanan ini hanya dimaksudkan pada LAN pribadi.

## 9. Uji koneksi dari HP sebelum memasang APK

1. Sambungkan HP ke Wi-Fi/SSID yang sama dengan laptop.
2. Matikan sementara mobile data untuk memastikan pengujian benar-benar melalui Wi-Fi (opsional).
3. Buka Chrome di HP.
4. Masukkan URL health check dari alamat LAN yang ditampilkan laptop, contoh `http://192.168.1.25:8000/health`.
5. Pastikan HP menerima JSON `status: ok`.

Jika tidak bisa:

- pastikan kedua perangkat berada pada subnet/SSID yang sama;
- jangan memakai Wi-Fi Guest;
- periksa apakah router mengaktifkan AP/client isolation;
- pastikan Windows Network Profile berstatus Private;
- jalankan ulang `Allow-NEXORA-Firewall.bat` sebagai Administrator;
- periksa `docker compose ps` dan `docker compose logs --tail=150 api db`.

## 10. Bangun APK khusus LAN dari GitHub Actions

APK LAN memakai HTTP ke alamat IP privat karena laptop lokal belum memakai sertifikat HTTPS. Konfigurasi cleartext dan WebView mixed-content hanya diaktifkan pada **debug APK** melalui `ALLOW_CLEARTEXT=true`. Build release tetap menolak HTTP. Pengaturan `MIXED_CONTENT_ALWAYS_ALLOW` hanya ada pada debug APK LAN; jangan distribusikan APK ini di luar Wi-Fi pribadi yang tepercaya.

1. Upload seluruh isi folder `NEXORA` ke root repository GitHub, termasuk `.github/workflows`.
2. Buka tab Actions.
3. Pilih workflow `Build Android APK`.
4. Klik Run workflow, branch `main`, `signed_release=false`.
5. Setelah sukses, download artifact `NEXORA-Android-LAN-debug-APK`.
6. Ekstrak artifact dan pindahkan `app-debug.apk` ke HP.
7. Izinkan instalasi dari sumber yang kamu pilih bila Android memintanya.

Ini adalah APK debug untuk pengujian LAN, bukan APK untuk Play Store atau distribusi publik. HTTP tidak mengenkripsi password/token/transaksi di jalur Wi-Fi; gunakan jaringan WPA2/WPA3 pribadi yang tepercaya. Jangan menggunakan APK debug untuk data finansial sensitif pada Wi-Fi yang tidak tepercaya.

## 11. Hubungkan APK ke backend laptop

1. Buka NEXORA di HP.
2. Masuk ke Profil → Pengaturan akun → Koneksi backend → Konfigurasi. Jika layar awal meminta koneksi server, pilih tombol tersebut.
3. Masukkan URL API dengan alamat IP laptop, contoh:

```text
http://192.168.1.25:8000/api/v1
```

4. Ganti `192.168.1.25` dengan IP aktual laptopmu. Jangan masukkan `localhost` di HP; `localhost` pada HP berarti HP itu sendiri.
5. Tekan `Simpan & uji koneksi`. Aplikasi memeriksa endpoint `/health` sebelum menyimpan alamat.
6. Setelah koneksi berhasil, buat akun NEXORA atau login. Simpan recovery code yang muncul saat pendaftaran.

Untuk browser laptop, dashboard pada `http://localhost:8000` otomatis menggunakan API pada origin yang sama. Untuk HP fisik, gunakan IPv4 laptop. `10.0.2.2` hanya untuk Android Emulator pada komputer host, bukan HP fisik.

## 12. Operasi sehari-hari

| Tugas | File/perintah |
|---|---|
| Mulai server | `Start-NEXORA-LAN.bat` |
| Lihat status, IP, dan health | `Status-NEXORA-LAN.bat` |
| Hentikan server | `Stop-NEXORA-LAN.bat` |
| Atur ulang firewall | `Allow-NEXORA-Firewall.bat` (Run as administrator) |
| Log service | `docker compose logs -f api db recurring-worker` |
| Lihat status container | `docker compose ps` |
| Jalankan ulang | `docker compose restart api recurring-worker` |

`docker compose down` tidak menghapus named volumes. **Jangan menjalankan `docker compose down -v`** kecuali memang ingin menghapus database dan file yang disimpan pada volume.

## 13. Data, backup, dan pemulihan

- Database utama berada di named volume Docker `nexora-postgres`.
- Lampiran/dokumen privat berada di named volume `nexora-private-files`.
- Jangan hapus volume tersebut saat memperbarui source.
- Simpan backup terenkripsi ke disk lain. Backup pada disk yang sama bukan perlindungan dari kerusakan laptop.
- Script Bash backup/restore tersedia di `scripts/backup-postgres.sh` dan `scripts/restore-postgres.sh`; jalankan dari lingkungan shell yang memiliki Docker CLI dan ikuti prompt/README script.
- Uji proses restore ke database uji sebelum bergantung pada backup untuk pemulihan.

## 14. Batasan mode lokal

- Laptop harus hidup, tidak sleep, Docker Desktop berjalan, dan jaringan Wi-Fi tersedia.
- Jika laptop mati atau berpindah Wi-Fi, HP tidak dapat mengakses backend.
- IP laptop dapat berubah saat router memberi DHCP lease baru. Jalankan `Status-NEXORA-LAN.bat` dan perbarui API Base URL di aplikasi HP.
- Guest Wi-Fi atau access point isolation dapat memblokir koneksi antarperangkat.
- Koneksi HTTP pada LAN tidak terenkripsi. Gunakan hanya jaringan pribadi yang menggunakan WPA2/WPA3 dan kata sandi yang kuat. Jangan gunakan mode ini untuk Wi-Fi publik atau untuk data produksi bernilai tinggi.
- Jangan membuat port forwarding pada router dan jangan menonaktifkan Windows Firewall.
- APK saat ini menargetkan Android API 36. Pada target SDK 36, izin jaringan lokal belum diwajibkan secara default. Jika kelak target SDK dinaikkan ke API 37+, ikuti panduan Android untuk mendeklarasikan dan meminta `ACCESS_LOCAL_NETWORK` saat runtime.
- Fitur yang membutuhkan layanan internet pihak ketiga (contoh data pasar langsung) tetap tidak tersedia jika tidak ada provider dan koneksi internet.

## 15. Troubleshooting cepat

### `Docker Engine belum berjalan`
Buka Docker Desktop dan tunggu sampai Engine berstatus Running. Pastikan mode Linux containers.

### Port 8000 sudah dipakai
Ganti `NEXORA_PORT` pada `.env`, contoh `8001`. Jalankan ulang `Allow-NEXORA-Firewall.bat`, lalu jalankan `Start-NEXORA-LAN.bat`. Akses HP menjadi `http://<IP-LAPTOP>:8001/api/v1`.

### API health check laptop gagal
Jalankan `docker compose ps`, kemudian `docker compose logs --tail=200 api db`. Periksa apakah migrasi database gagal atau port sudah dipakai.

### HP bisa membuka dashboard tapi aplikasi mengatakan gagal koneksi
Pastikan API Base URL memakai IP IPv4 laptop, berakhiran `/api/v1`, bukan `localhost`. Contoh `http://192.168.1.25:8000/api/v1`.

### HP tidak bisa membuka health check
Periksa Wi-Fi sama, Private profile, aturan firewall, guest isolation, dan IP terbaru laptop. Jangan mengatasi masalah dengan membuka port ke `Any`/Public.

### Aplikasi kembali ke mode demo
Buka Profil → Koneksi backend, masukkan URL server, dan simpan setelah health check berhasil. Jika data lokal/browser demo dipakai, data tersebut tidak otomatis disalin ke server; buat/masuk dengan akun server untuk memulai data yang tersinkron.
