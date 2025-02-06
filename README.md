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

### 🛠 Service Management
```bash
# Manajemen service systemd
sudo systemctl start multicraft    # Mulai service
sudo systemctl stop multicraft     # Hentikan service
sudo systemctl restart multicraft  # Restart service
sudo systemctl status multicraft   # Cek status service
sudo journalctl -u multicraft -f   # Monitor log systemd real-time

# Menggunakan skrip Multicraft langsung
/home/minecraft/multicraft/bin/multicraft start     # Mulai daemon
/home/minecraft/multicraft/bin/multicraft stop      # Hentikan daemon
/home/minecraft/multicraft/bin/multicraft restart   # Restart daemon
/home/minecraft/multicraft/bin/multicraft reload    # Reload konfigurasi
```

### 🔧 Konfigurasi
```bash
sudo nano /home/minecraft/multicraft/multicraft.conf  # Edit konfig utama
sudo nano /var/www/html/multicraft/protected/config/config.php  # Konfig panel
mysql -u multicraft_panel -p  # Akses database panel
```

### 📜 Log Monitoring
```bash
tail -f /home/minecraft/multicraft/multicraft.log  # Log daemon real-time
tail -f /var/www/html/multicraft/protected/runtime/panel.log  # Log panel
tail -f /home/minecraft/multicraft/servers/server*/server.log  # Log server spesifik
multicraft log  # Tampilkan log interaktif
```

### 🎮 Server Operations
```bash
multicraft start 1      # Start server ID 1
multicraft stop 1       # Stop server ID 1
multicraft restart 1    # Restart server ID 1
multicraft cmd 1 "say Hello World"  # Kirim command ke console
multicraft list         # Daftar semua server
multicraft jarlist      # Daftar versi JAR tersedia
multicraft getjar       # Update Minecraft JAR
```

### 💾 Backup & Restore
```bash
# Backup database
mysqldump -u root -p multicraft_panel > panel_backup.sql
mysqldump -u root -p multicraft_daemon > daemon_backup.sql

# Backup file server
tar -czvf mc_backup_$(date +%F).tar.gz /home/minecraft/multicraft/servers/

# Restore otomatis
multicraft restore /path/to/backup.tar.gz
```

### 👤 User Management
```bash
# Reset password user
mysql -u root -p -e "USE multicraft_panel; UPDATE user SET password=MD5('passwordbaru') WHERE username='admin';"

# Buat user baru via SQL
mysql -u root -p -e "USE multicraft_panel; INSERT INTO user (username,password) VALUES ('newuser',MD5('password'));"
```

### 📊 Monitoring
```bash
multicraft status       # Status semua server
htop                    # Monitor resource real-time
df -h /home             # Cek penggunaan disk
iftop                   # Monitor bandwidth jaringan
sudo lsof -i :25565     # Cek port yang digunakan
```

### 🧹 Maintenance
```bash
multicraft cleanup      # Bersihkan file temporary
multicraft update       # Update versi Multicraft
sudo apt autoremove     # Hapus paket tidak terpakai
find /home/minecraft/multicraft/servers/ -name "*.jar" -mtime +30 -delete  # Hapus JAR lama
```

### 🔐 Security
```bash
sudo ufw status numbered            # Cek firewall rules
sudo ufw allow 25565/tcp            # Buka port Minecraft
sudo ufw allow 21/tcp               # Buka port FTP
sudo certbot renew --dry-run        # Test renew SSL
sudo chmod 600 /home/minecraft/multicraft/multicraft.conf  # Amankan konfig
```

### 🚀 Advanced Operations
```bash
# Multi-daemon setup
DAEMON_ID=2 /home/minecraft/multicraft/bin/multicraft start

# Force kill frozen server
pkill -f "server_1/main.sh"

# Mount RAM disk untuk world storage
sudo mount -t tmpfs -o size=2G tmpfs /home/minecraft/multicraft/servers/server_1/world/

# Benchmark performance
sysbench cpu --threads=4 run
```

### ⚙️ FTP Management
```bash
sudo systemctl restart proftpd      # Restart service FTP
tail -f /var/log/proftpd/auth.log   # Monitor autentikasi FTP
ftpwho -v                           # Cek user FTP aktif
```

### 🕒 Cron Jobs Contoh
```bash
# Auto-backup harian
0 2 * * * /usr/bin/mysqldump -u root -pPASSWORD multicraft_panel > /backups/panel_$(date +\%F).sql

# Auto-restart mingguan
0 4 * * 1 /home/minecraft/multicraft/bin/multicraft restart

# SSL auto-renew
0 3 1 * * /usr/bin/certbot renew --quiet
```

### 🔄 Troubleshooting Toolkit
```bash
multicraft debug        # Mode debug verbose
nc -zv localhost 25465  # Test koneksi daemon
ss -tulpn | grep java   # Cek proses Java
mtr 8.8.8.8             # Network diagnostics
strace -p $(pgrep multicraft)  # Trace system calls
```

## 📜 License
Proyek ini dilisensikan di bawah [MIT License](LICENSE) - bebas digunakan untuk keperluan pribadi maupun komersial.

---

**Dibuat dengan ❤️ oleh Arpeezy**  
[![Sponsor](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://saweria.co/Arpeezy)

> ⚠️ **Disclaimer**: Script ini tidak berafiliasi dengan Multicraft. Selalu backup data penting sebelum melakukan instalasi.
