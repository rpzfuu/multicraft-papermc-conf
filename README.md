# 🚀 Multicraft Auto-Installer for Ubuntu

[![Multicraft Version](https://img.shields.io/badge/Multicraft-2.5.0-blue.svg)](https://www.multicraft.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Tested%20on-Ubuntu%2020.04%20|%2022.04-orange)](https://ubuntu.com)
![MySQL](https://img.shields.io/badge/MySQL-8.0+-blue.svg)
![PHP](https://img.shields.io/badge/PHP-7.4+-purple.svg)

**Instalasi otomatis panel game server Multicraft dengan fitur lengkap dalam 5 menit!**  
🔥 Termasuk: Web Server (Apache), Database (MySQL), SSL Gratis (Let's Encrypt), dan Konfigurasi Keamanan Profesional.

## 🌟 Fitur Utama
- ✅ Instalasi 1-komando
- ✅ Konfigurasi SSL Otomatis
- ✅ Optimasi Performa Server
- ✅ Firewall Terintegrasi
- ✅ Systemd Service Management
- ✅ Backup Database Otomatis
- ✅ Multi-User Support
- ✅ FTP Server Terintegrasi

## 🚀 Quick Start
Untuk instalasi cepat (Domain sudah diarahkan ke IP server):
```bash
bash <(wget -qO- https://raw.githubusercontent.com/rpzfuu/multicraft-papermc-conf/main/multicraft_install.sh)
```

## 📋 Prasyarat
- [x] Domain yang sudah diarahkan ke IP server
- [x] Ubuntu 20.04/22.04 LTS
- [x] Akses root/sudo
- [x] Minimal 2GB RAM
- [x] Ruang disk 10GB+

## 📚 Daftar Isi
1. [Instalasi Manual](#-instalasi-manual)
2. [Instalasi Otomatis](#-instalasi-otomatis)
3. [Post-Installation](#-post-installation)
4. [Troubleshooting](#-troubleshooting)
5. [License](#-license)

## 🛠 Instalasi Manual

### 1. Persiapan Server
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git wget curl
```

### 2. Download Skrip
```bash
wget https://raw.githubusercontent.com/rpzfuu/multicraft-papermc-conf/main/multicraft_install.sh
chmod +x multicraft_install.sh
```

### 3. Jalankan Instalasi
```bash
sudo ./multicraft_install.sh
```

## 🤖 Instalasi Otomatis
Skrip akan memandu Anda melalui proses instalasi:
1. Masukkan domain lengkap (contoh: mc.domainanda.com)
2. Masukkan email administrator
3. Masukkan nomor daemon (default: 1)
4. Masukkan license key (jika ada)
5. Buat password kuat untuk sistem

📝 **Contoh Flow Instalasi:**
```
[+] Mengkonfigurasi Firewall...
[✓] Apache berhasil diinstal
[✓] MySQL terkonfigurasi dengan aman
[+] Membuat sertifikat SSL...
[✓] SSL berhasil dibuat untuk domain.com
[+] Menginstal Multicraft 2.5.0...
[✓] Service Multicraft aktif
```

## 🎉 Post-Installation
1. Akses panel di: `https://domainanda.com/multicraft`
2. Login pertama:
   ```
   Username: admin
   Password: admin
   ```
3. Segera ganti password admin
4. Tambahkan server Minecraft melalui menu **Servers**

💡 **Tips:**
- Jalankan `multicraft log` untuk memantau log
- Backup reguler dengan `multicraft backup`
- Update script dengan `multicraft update`

## 🔧 Troubleshooting

### Masalah Umum & Solusi

| Gejala                          | Solusi                                  |
|---------------------------------|-----------------------------------------|
| Domain tidak terdeteksi         | Periksa DNS A record & propagasi       |
| Error MySQL                     | Cek password di `/home/minecraft/multicraft/multicraft.conf` |
| SSL tidak terpasang             | Jalankan `certbot renew --force-renewal` |
| Panel tidak bisa akses daemon   | Verifikasi firewall dan port 25465     |

**Perintah Diagnostik:**
```bash
# Cek status service
systemctl status multicraft

# Lihat log instalasi
tail -f /var/log/multicraft_install.log

# Tes koneksi database
mysql -u multicraft_panel -p
```

## 📜 License
Proyek ini dilisensikan di bawah [MIT License](LICENSE) - bebas digunakan untuk keperluan pribadi maupun komersial.

---

**Dibuat dengan ❤️ oleh Arpeezy**  
[![Sponsor](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://saweria.co/Arpeezy)

> ⚠️ **Disclaimer**: Script ini tidak berafiliasi dengan Multicraft. Selalu backup data penting sebelum melakukan instalasi.
