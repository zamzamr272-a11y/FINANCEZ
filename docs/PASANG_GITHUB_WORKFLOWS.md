# Cara memasang NEXORA ke GitHub dan menjalankan workflows

Panduan ini untuk Windows dan GitHub melalui browser. Upload source ke repository tidak otomatis membuat backend online; backend perlu VPS/server dan file `.env` tersendiri.

## A. Siapkan folder proyek

1. Download `NEXORA-final-project.zip`.
2. Klik kanan ZIP di Windows Explorer → **Extract All**.
3. Buka folder hasil ekstrak `NEXORA`.
4. Pastikan di dalam folder itu terlihat `backend`, `frontend`, `android`, `docs`, `scripts`, `Dockerfile`, `docker-compose.yml`, `.env.example`, dan `.github`.
5. Pastikan folder `.github` tidak tertinggal. Di File Explorer aktifkan **View → Show → Hidden items** bila tidak terlihat.
6. Jangan membuat atau mengunggah file `.env`, database lokal, folder `backend/data`, file backup, atau Android keystore.

## B. Buat repository kosong

1. Masuk ke https://github.com/new dan login.
2. Isi nama repository, misalnya `nexora`.
3. Pilih Private untuk proyek yang belum siap publik.
4. Jangan centang README, `.gitignore`, atau license (repository sebaiknya kosong).
5. Klik **Create repository**.

## C. Upload source

Cara melalui website GitHub:

1. Buka repository baru.
2. Klik **Add file → Upload files**.
3. Dari folder lokal `NEXORA`, pilih dan upload **seluruh isi foldernya**, termasuk `.github` (bukan folder induk `NEXORA` agar isi proyek tidak bertingkat `NEXORA/NEXORA`).
4. Jika perlu, aktifkan tampilan hidden items untuk memastikan `.github` ikut terpilih. Folder `.github/workflows` harus ada pada root repository.
5. Isi pesan commit, misalnya `Add NEXORA application source`.
6. Klik **Commit changes** ke branch `main`.

Setelah commit, tampilan utama repository seharusnya langsung menunjukkan folder `backend`, `frontend`, `android`, `.github`, serta file `Dockerfile` dan `docker-compose.yml`.

## D. Aktifkan GitHub Actions

1. Pada repository, buka **Actions**.
2. Jika GitHub meminta izin, klik **I understand my workflows, go ahead and enable them** atau tombol enable yang tersedia.
3. Buka **Settings → Actions → General**.
4. Pastikan Actions diizinkan untuk repository (pilih kebijakan yang mengizinkan actions yang diperlukan).
5. Untuk workflow APK debug dan Quality checks, tidak perlu menambah secrets.

## E. Jalankan workflow dan download APK

### Build Android APK

Workflow: `.github/workflows/android-apk.yml`

- Akan berjalan otomatis saat ada push ke `main`/`master` yang mengubah file `android/**`, `frontend/**`, atau workflow APK.
- Untuk menjalankan manual: **Actions → Build Android APK → Run workflow → Branch: main → signed_release: false → Run workflow**.
- Buka run yang baru dibuat dan tunggu job **debug-apk** berstatus hijau **Success**.
- Di bagian **Artifacts**, download `NEXORA-Android-LAN-debug-APK`.
- Ekstrak file artifact ZIP tersebut. Di dalamnya ada `app-debug.apk`.
- Salin APK ke Android, buka melalui Files/Downloads, lalu izinkan instalasi dari aplikasi sumber jika Android memintanya.

APK debug untuk pengujian. APK ini belum berisi backend/database. Setelah backend tersedia, buka aplikasi → **Hubungkan/konfigurasi**, masukkan base API HTTPS dengan format `https://api.domain-kamu.id/api/v1`, lalu uji koneksi. Jangan gunakan URL HTTP publik.

### Quality checks

Workflow: `.github/workflows/quality.yml`

- Berjalan otomatis saat push ke `main`/`master` yang mengubah backend/frontend/workflow quality, juga pada pull request.
- Bisa dijalankan manual: **Actions → Quality checks → Run workflow**.
- Buka run dan periksa semua step harus hijau. Jika gagal, buka step merah dan baca log error.

### Publish backend container (opsional)

Workflow: `.github/workflows/container-publish.yml`

- Bisa dijalankan manual dari **Actions → Publish backend container → Run workflow**.
- Juga berjalan ketika tag versi `v*` didorong, misalnya `v0.1.0`.
- Workflow memakai `GITHUB_TOKEN` yang disediakan GitHub dan permission `packages: write`.
- Hasilnya image di GitHub Container Registry: `ghcr.io/OWNER/REPOSITORY`.
- Ini hanya memublikasikan image; tidak membuat VPS, domain, HTTPS, atau database production.

### Deploy backend ke VPS (opsional)

Workflow: `.github/workflows/deploy-vps.yml`

Jika secrets di bawah belum diisi, workflow ini tidak error: ia menampilkan peringatan kuning **Deploy VPS dilewati** beserta daftar secret yang kurang, lalu tidak mengirim apa pun ke server. Deploy sungguhan baru jalan setelah VPS siap dan repository secrets berikut dibuat melalui **Settings → Secrets and variables → Actions → New repository secret**:

- `VPS_HOST`: IP atau hostname VPS.
- `VPS_USER`: user SSH non-root yang memiliki izin menjalankan Docker.
- `VPS_SSH_PRIVATE_KEY`: private key khusus deployment.
- `VPS_KNOWN_HOSTS`: host key VPS yang fingerprint-nya sudah diverifikasi secara independen.
- `VPS_PATH`: direktori absolut proyek pada VPS, misalnya `/opt/nexora`.

Buat `.env` secara langsung di VPS sebelum menjalankan deploy. Isi `POSTGRES_PASSWORD`, `JWT_SECRET` yang acak dan panjang, `CORS_ORIGINS` yang tepat, `APP_TIMEZONE=Asia/Makassar`, serta nilai lain sesuai `.env.example`. Jangan pernah memasukkan `.env` ke repository. Setelah secrets dan server siap, pilih **Actions → Deploy NEXORA backend to VPS → Run workflow**.

## F. Signed release APK (opsional, bukan untuk langkah pertama)

Untuk membuat signed release, pemilik aplikasi harus membuat Android keystore sendiri dan menyimpannya secara aman di luar repository. Tambahkan empat repository secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Lalu jalankan **Actions → Build Android APK → Run workflow**, pilih `signed_release: true`, dan mulai workflow. Artifact jika berhasil bernama `NEXORA-Android-signed-release-APK`. Jangan pernah commit file `.jks`/`.keystore` atau password ke GitHub. Kehilangan keystore dapat menghalangi pembaruan aplikasi dengan identitas signing yang sama.

## G. Arti empat workflow

| File workflow | Fungsi | Trigger |
|---|---|---|
| `quality.yml` | Tes backend, syntax frontend, migrasi | Push tertentu, pull request, manual |
| `android-apk.yml` | Membuat APK debug; signed release opsional | Push tertentu, pull request, manual |
| `container-publish.yml` | Build dan push image backend ke GHCR | Tag `v*` atau manual |
| `deploy-vps.yml` | Menyalin source dan menjalankan Compose di VPS | Manual, memerlukan VPS secrets dan `.env` di VPS |

## H. Jika workflow tidak muncul

- Pastikan folder ada persis di root repository: `.github/workflows/`.
- Pastikan file berekstensi `.yml` dan sudah masuk commit.
- Pastikan branch yang dipilih `main` dan Actions diaktifkan.
- Refresh tab Actions. Jalankan `workflow_dispatch` workflow dari dropdown nama workflow jika tombol **Run workflow** tersedia.
- Jika gagal, buka workflow run → job → step merah → salin pesan error. Jangan mengunggah secret, password, private key, atau `.env` saat meminta bantuan.
