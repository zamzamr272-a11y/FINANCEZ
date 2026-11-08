# Perubahan UI (perapian tampilan)

## Font
- Satu keluarga font: Inter (dibundel di `frontend/assets/fonts/`, lisensi OFL). Sebelumnya judul/angka memakai `Manrope` yang tidak pernah dimuat, sehingga jatuh ke font serif bawaan browser dan tampil campur aduk.
- Skala teks tetap: 12 / 13 / 14 / 16 / 20 / 24 / 28 px. Sebelumnya banyak teks 7-10px.
- Label KAPITAL ber-spasi lebar diganti huruf biasa.

## Tata letak
- `styles.css` ditulis ulang dan terstruktur (token warna, spasi kelipatan 4, radius, tinggi kontrol 40px).
- Kolom dashboard baris atas dan bawah sejajar; judul halaman + tombol aksi rapi satu baris.
- Sidebar, topbar, dan navigasi bawah (mobile) memakai ikon SVG seragam menggantikan simbol unicode.
- Banner mode pratinjau kini benar-benar tersembunyi saat sudah terhubung ke server (atribut `hidden` sebelumnya tertimpa CSS).
- Aksi pesan komunitas muncul saat di-hover (selalu tampil di layar sentuh); jumlah reaksi tetap terlihat.
- Daftar grup tidak lagi meluber keluar panel.

## Perbaikan bug tampilan
- Grafik arus kas tampil sebagai blok hitam karena kelas CSS grafik tidak pernah ada; kini berupa grafik garis dengan sumbu nominal, dan lebarnya menyesuaikan layar.
- Grafik donat menampilkan setiap segmen dua kali (panjang pola salah); kini proporsinya benar.
- Gambar maskot memakai path absolut `/assets/mascot.svg` yang gagal di Android WebView; kini relatif.
- Cache service worker dinaikkan ke `nexora-shell-v2` supaya pengguna lama menerima tampilan baru.
