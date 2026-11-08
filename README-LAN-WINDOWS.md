# Jalankan NEXORA di Laptop Windows dan HP pada Wi-Fi yang Sama

Mulai cepat:

1. Instal/jalankan Docker Desktop (Linux containers).
2. Pastikan Wi-Fi rumah/kantor tepercaya diset sebagai Private.
3. Klik `Allow-NEXORA-Firewall.bat` → Run as administrator.
4. Klik `Start-NEXORA-LAN.bat`.
5. Buka `http://localhost:8000/` di laptop.
6. Buka `http://IP-LAPTOP:8000/health` di Chrome HP untuk memastikan jaringan tersambung.
7. Bangun/download artifact `NEXORA-Android-LAN-debug-APK` lewat GitHub Actions.
8. Pada APK, atur API Base URL menjadi `http://IP-LAPTOP:8000/api/v1`.

**Dokumentasi lengkap:** [`docs/LAN_LOCAL_SERVER.md`](docs/LAN_LOCAL_SERVER.md)

Jangan buka port router. Jangan commit `.env`. Jangan gunakan debug APK/HTTP pada Wi-Fi publik.
