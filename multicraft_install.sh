#!/bin/bash
set -euo pipefail

# Konfigurasi Awal
clear
echo -e "\033[1;36m==== INSTALASI MULTICRAFT 2.5.0 UNTUK UBUNTU 24.04 ====\033[0m"
echo "Skrip ini akan melakukan instalasi lengkap Multicraft dengan:"
echo -e "- PHP 8.1 + Ekstensi yang diperlukan\n- MySQL 8.0\n- Apache 2.4\n- SSL Let's Encrypt"
echo -e "\033[1;33mPastikan domain sudah diarahkan ke server dan port 80/443 terbuka!\033[0m"
echo "=============================================================="

# Fungsi Validasi Input
validasi_input() {
  local prompt=$1
  local validation=$2
  local default=$3
  local input
  while true; do
    read -p "$prompt" input
    input=${input:-$default}
    if [[ $input =~ $validation ]]; then
      echo "$input"
      break
    else
      echo -e "\033[1;31mInput tidak valid! Silakan coba lagi.\033[0m"
    fi
  done
}

# Mengumpulkan Informasi
echo -e "\n\033[1;34m[1/5] KONFIGURASI DASAR\033[0m"
DOMAIN=$(validasi_input "Masukkan domain lengkap (contoh: mc.example.com): " '^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$' "")
EMAIL=$(validasi_input "Masukkan email administrator: " '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' "")
DAEMON_NUM=$(validasi_input "Nomor daemon (default 1): " '^[0-9]+$' "1")
LICENSE_KEY=$(validasi_input "License key (kosongkan jika tidak ada): " '^.*$' "")

# Validasi Password
echo -e "\n\033[1;34m[2/5] KONFIGURASI KEAMANAN\033[0m"
generate_password() {
  local length=16
  tr -dc 'A-Za-z0-9!@#$%^&*()_+{}|<>?' </dev/urandom | head -c $length
}

echo "Membuat password aman..."
MYSQL_ROOT_PASS=$(generate_password)
PANEL_DB_PASS=$(generate_password)
DAEMON_DB_PASS=$(generate_password)
SYS_PASSWORD=$(generate_password)

# Ekspor Variabel
export DEBIAN_FRONTEND=noninteractive
export MULTICRAFT_VERSION="2.5.0"

# Fungsi Error Handling
handle_error() {
  echo -e "\033[1;31mERROR: Gagal pada langkah $1\033[0m"
  echo "Detail error: $2"
  exit 1
}

# Mulai Logging
exec > >(tee -i multicraft_install.log)
exec 2>&1

# Header Instalasi
echo -e "\n\033[1;34m[3/5] MEMULAI INSTALASI\033[0m"

# Update Sistem
echo -e "\n--- Memperbarui Sistem ---"
apt-get update -q || handle_error "Update System" "$?"
apt-get upgrade -y -q || handle_error "System Upgrade" "$?"

# Instal Dependensi
echo -e "\n--- Menginstal Paket Utama ---"
apt-get install -y -q \
  apache2 \
  mysql-server \
  php8.1 \
  libapache2-mod-php8.1 \
  php8.1-mysql \
  php8.1-curl \
  php8.1-gd \
  php8.1-xml \
  php8.1-sqlite3 \
  php8.1-zip \
  php8.1-mbstring \
  openjdk-17-jre-headless \
  zip \
  unzip \
  certbot \
  python3-certbot-apache \
  expect \
  ufw \
  htop \
  nano \
  pwgen || handle_error "Dependency Installation" "$?"

# Konfigurasi Firewall
echo -e "\n--- Mengatur Firewall ---"
ufw allow "OpenSSH"
ufw allow "Apache Full"
ufw --force enable

# Konfigurasi MySQL
echo -e "\n--- Mengamankan MySQL ---"
mysql --user=root <<_EOF_
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_ || handle_error "MySQL Secure Installation" "$?"

# Buat Database
echo -e "\n--- Membuat Database ---"
mysql --user=root --password="${MYSQL_ROOT_PASS}" <<_EOF_
CREATE DATABASE multicraft_panel;
CREATE DATABASE multicraft_daemon;
CREATE USER 'multicraft_panel'@'localhost' IDENTIFIED BY '${PANEL_DB_PASS}';
CREATE USER 'multicraft_daemon'@'localhost' IDENTIFIED BY '${DAEMON_DB_PASS}';
GRANT ALL PRIVILEGES ON multicraft_panel.* TO 'multicraft_panel'@'localhost';
GRANT ALL PRIVILEGES ON multicraft_daemon.* TO 'multicraft_daemon'@'localhost';
FLUSH PRIVILEGES;
_EOF_ || handle_error "Database Creation" "$?"

# Optimasi PHP untuk Ubuntu 24.04
echo -e "\n--- Mengoptimalkan PHP 8.1 ---"
PHP_INI="/etc/php/8.1/apache2/php.ini"
sed -i \
  -e 's/^max_execution_time =.*/max_execution_time = 180/' \
  -e 's/^memory_limit =.*/memory_limit = 512M/' \
  -e 's/^upload_max_filesize =.*/upload_max_filesize = 256M/' \
  -e 's/^post_max_size =.*/post_max_size = 256M/' \
  -e 's/^max_input_vars =.*/max_input_vars = 5000/' \
  "$PHP_INI" || handle_error "PHP Configuration" "$?"

# Konfigurasi Apache
echo -e "\n--- Membuat Virtual Host ---"
cat > /etc/apache2/sites-available/multicraft.conf <<EOF
<VirtualHost *:80>
    ServerName ${DOMAIN}
    Redirect permanent / https://${DOMAIN}/
</VirtualHost>

<VirtualHost *:443>
    ServerAdmin ${EMAIL}
    ServerName ${DOMAIN}
    DocumentRoot /var/www/html/multicraft
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN}/privkey.pem
    
    <Directory /var/www/html/multicraft>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/multicraft_error.log
    CustomLog \${APACHE_LOG_DIR}/multicraft_access.log combined
</VirtualHost>
EOF

# Aktifkan Konfigurasi
a2ensite multicraft.conf
a2dissite 000-default.conf
a2enmod rewrite ssl
systemctl restart apache2 || handle_error "Apache Restart" "$?"

# Generate SSL Certificate
echo -e "\n--- Membuat SSL Certificate ---"
certbot --apache --non-interactive --agree-tos --email ${EMAIL} -d ${DOMAIN} || handle_error "SSL Generation" "$?"

# Install Multicraft
echo -e "\n--- Mengunduh Multicraft ${MULTICRAFT_VERSION} ---"
cd /tmp || handle_error "Change Directory" "$?"
wget -q "https://www.multicraft.org/download/linux64?version=${MULTICRAFT_VERSION}" -O multicraft.tar.gz || handle_error "Download Multicraft" "$?"
tar xzf multicraft.tar.gz || handle_error "Extract Multicraft" "$?"
cd multicraft || handle_error "Enter Multicraft Directory" "$?"

# Automated Setup dengan Expect
echo -e "\n--- Instalasi Otomatis Multicraft ---"
/usr/bin/expect <<EOD
set timeout 300
spawn ./setup.sh

expect "Run each Minecraft server under its own user? (Multicraft will create system users):"
send "y\r"

expect "Run Multicraft under this user:"
send "minecraft\r"

expect "User not found. Create user 'minecraft' on start of installation?"
send "y\r"

expect "Install Multicraft in:"
send "/home/minecraft/multicraft\r"

expect "If you have a license key you can enter it now:"
send "${LICENSE_KEY}\r"

expect "Daemon number?"
send "${DAEMON_NUM}\r"

expect "Will the web panel run on this machine?"
send "y\r"

expect "User of the webserver:"
send "www-data\r"

expect "Location of the web panel files:"
send "/var/www/html/multicraft\r"

expect "Please enter a new daemon password:"
send "${SYS_PASSWORD}\r"

expect "Enable builtin FTP server?"
send "y\r"

expect "IP the FTP server will listen on:"
send "0.0.0.0\r"

expect "IP to use to connect to the FTP server:"
send "${DOMAIN}\r"

expect "FTP server port:"
send "21\r"

expect "Block FTP upload of .jar files?"
send "y\r"

expect "What kind of database do you want to use?"
send "mysql\r"

expect "Database host:"
send "localhost\r"

expect "Database name:"
send "multicraft_daemon\r"

expect "Database user:"
send "multicraft_daemon\r"

expect "Database password:"
send "${DAEMON_DB_PASS}\r"

expect "Path to java program:"
send "/usr/bin/java\r"

expect "Path to zip program:"
send "/usr/bin/zip\r"

expect "Press [Enter] to continue."
send "\r"

expect "Save entered settings?"
send "y\r"

expect eof
EOD
[ $? -eq 0 ] || handle_error "Multicraft Setup" "$?"

# Final Configuration
echo -e "\n--- Konfigurasi Akhir ---"
sed -i "s/^user =.*/user = minecraft/" /home/minecraft/multicraft/multicraft.conf
sed -i "s/^password =.*/password = ${SYS_PASSWORD}/" /home/minecraft/multicraft/multicraft.conf

# File Permissions
chown -R minecraft:minecraft /home/minecraft/multicraft
chown -R www-data:www-data /var/www/html/multicraft
find /var/www/html/multicraft -type d -exec chmod 755 {} \;
find /var/www/html/multicraft -type f -exec chmod 644 {} \;

# Systemd Service
echo -e "\n--- Membuat Systemd Service ---"
cat > /etc/systemd/system/multicraft.service <<EOF
[Unit]
Description=Multicraft Daemon
After=network.target

[Service]
Type=forking
User=minecraft
Group=minecraft
WorkingDirectory=/home/minecraft/multicraft
ExecStart=/home/minecraft/multicraft/bin/multicraft start
ExecStop=/home/minecraft/multicraft/bin/multicraft stop
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable multicraft
systemctl start multicraft || handle_error "Start Service" "$?"

# Finalisasi
echo -e "\n\033[1;34m[5/5] FINALISASI\033[0m"
rm -rf /var/www/html/multicraft/install.php
mysqladmin -u root -p"${MYSQL_ROOT_PASS}" password "${SYS_PASSWORD}"

# Hasil Instalasi
echo -e "\n\033[1;32m==== INSTALASI BERHASIL ====\033[0m"
echo "Akses Panel: https://${DOMAIN}"
echo "Username Admin: admin"
echo "Password Admin: admin (Ganti segera setelah login!)"

echo -e "\n\033[1;33m=== INFORMASI DATABASE ==="
echo -e "MySQL Root Password: ${MYSQL_ROOT_PASS}"
echo -e "Panel DB User: multicraft_panel\nPassword: ${PANEL_DB_PASS}"
echo -e "Daemon DB User: multicraft_daemon\nPassword: ${DAEMON_DB_PASS}\033[0m"

echo -e "\n\033[1;33m=== INFORMASI LOGIN SISTEM ==="
echo -e "Minecraft User: minecraft"
echo -e "Password Sistem: ${SYS_PASSWORD}\033[0m"

echo -e "\n\033[1;31mSimpan informasi ini di tempat aman!\033[0m"
