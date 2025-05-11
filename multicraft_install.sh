#!/bin/bash
set -euo pipefail

# Konfigurasi Awal
clear
echo -e "\033[1;36m==== INSTALASI MULTICRAFT 2.5.0 ====\033[0m"
echo "Skrip ini akan melakukan instalasi lengkap Multicraft dengan:"
echo "- Webserver Apache + PHP"
echo "- Database MySQL"
echo "- Sertifikat SSL Let's Encrypt"
echo "- Konfigurasi Keamanan"
echo -e "\033[1;33mPastikan Anda memiliki akses root dan domain yang sudah diarahkan ke server!\033[0m"
echo "=============================================="

# Fungsi Validasi Input
validasi_input() {
  local prompt=$1
  local validation=$2
  local input
  while true; do
    read -p "$prompt" input
    if [[ $input =~ $validation ]]; then
      echo "$input"
      break
    else
      echo -e "\033[1;31mInput tidak valid! Silakan coba lagi.\033[0m"
    fi
  done
}

# Mengumpulkan Informasi yang Diperlukan
echo -e "\n\033[1;34m[1/5] KONFIGURASI DASAR\033[0m"
DOMAIN=$(validasi_input "Masukkan domain lengkap (contoh: multicraft.saya.com): " '^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$')
EMAIL=$(validasi_input "Masukkan email administrator: " '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
DAEMON_NUM=$(validasi_input "Masukkan nomor daemon (default 1): " '^[0-9]+$')
LICENSE_KEY=$(validasi_input "Masukkan license key (atau kosongkan jika tidak ada): " '^.*$')

echo -e "\n\033[1;34m[2/5] KONFIGURASI KEAMANAN\033[0m"
echo "Buat password untuk database dan user sistem:"
while true; do
  read -sp "Password (minimal 8 karakter, harus mengandung angka dan simbol): " PASSWORD
  local symbol_regex='[!@#$%^&*]'  # Menyimpan pola regex dalam variabel
  if [[ ${#PASSWORD} -ge 8 && "$PASSWORD" =~ [0-9] && "$PASSWORD" =~ $symbol_regex ]]; then
    echo -e "\n\033[1;32mPassword valid!\033[0m"
    break
  else
    echo -e "\n\033[1;31mPassword tidak memenuhi kriteria! Ulangi.\033[0m"
  fi
done

# Generate Password Unik
PANEL_DB_PASS="${PASSWORD}panel#$(openssl rand -base64 3)"
DAEMON_DB_PASS="${PASSWORD}daemon#$(openssl rand -base64 3)"
MYSQL_ROOT_PASS=$(openssl rand -base64 12)

# Ekspor Variabel
export DEBIAN_FRONTEND=noninteractive
export MULTICRAFT_VERSION="2.5.0"

# Fungsi Error Handling
handle_error() {
  echo -e "\033[1;31mERROR: Gagal pada langkah $1\033[0m"
  echo "Detail error tersedia di multicraft_install.log"
  exit 1
}

# Mulai Logging
exec > >(tee -i multicraft_install.log)
exec 2>&1

# Header Instalasi
echo -e "\n\033[1;34m[3/5] MEMULAI INSTALASI\033[0m"
echo "Detail instalasi akan dicatat di multicraft_install.log"

# Update Sistem
echo -e "\n--- Memperbarui sistem ---"
apt-get update -q || handle_error "Update Package"
apt-get upgrade -y -q || handle_error "System Upgrade"

# Instal Dependensi
echo -e "\n--- Menginstal dependensi ---"
apt-get install -y -q \
  apache2 \
  mysql-server \
  php \
  libapache2-mod-php \
  php-mysql \
  php-curl \
  php-gd \
  php-xml \
  php-sqlite3 \
  php-zip \
  php-mbstring \
  openjdk-17-jre-headless \
  zip \
  unzip \
  certbot \
  python3-certbot-apache \
  expect \
  ufw \
  htop \
  nano || handle_error "Dependency Installation"

# Konfigurasi Firewall
echo -e "\n--- Mengatur firewall ---"
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
_EOF_ || handle_error "MySQL Secure Installation"

# Buat Database
echo -e "\n--- Membuat database ---"
mysql --user=root --password="${MYSQL_ROOT_PASS}" <<_EOF_
CREATE DATABASE multicraft_panel;
CREATE DATABASE multicraft_daemon;
CREATE USER 'multicraft_panel'@'localhost' IDENTIFIED BY '${PANEL_DB_PASS}';
CREATE USER 'multicraft_daemon'@'localhost' IDENTIFIED BY '${DAEMON_DB_PASS}';
GRANT ALL PRIVILEGES ON multicraft_panel.* TO 'multicraft_panel'@'localhost';
GRANT ALL PRIVILEGES ON multicraft_daemon.* TO 'multicraft_daemon'@'localhost';
FLUSH PRIVILEGES;
_EOF_ || handle_error "Database Creation"

# Konfigurasi PHP
echo -e "\n--- Mengoptimalkan PHP ---"
PHP_INI="/etc/php/$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)/apache2/php.ini"
sed -i -e 's/^max_execution_time =.*/max_execution_time = 180/' \
       -e 's/^memory_limit =.*/memory_limit = 256M/' \
       -e 's/^upload_max_filesize =.*/upload_max_filesize = 128M/' \
       -e 's/^post_max_size =.*/post_max_size = 128M/' \
       "$PHP_INI" || handle_error "PHP Configuration"

# Konfigurasi Apache
echo -e "\n--- Mengatur virtual host ---"
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
systemctl restart apache2 || handle_error "Apache Restart"

# Mengambil Sertifikat SSL
echo -e "\n--- Membuat SSL dengan Certbot ---"
certbot --apache --non-interactive --agree-tos --email ${EMAIL} -d ${DOMAIN} || handle_error "SSL Generation"

# Unduh dan Ekstrak Multicraft
echo -e "\n--- Mengunduh Multicraft ${MULTICRAFT_VERSION} ---"
cd /tmp || handle_error "Temp Directory"
wget -q "https://www.multicraft.org/download/linux64?version=${MULTICRAFT_VERSION}" -O multicraft.tar.gz || handle_error "Download Multicraft"
tar xzf multicraft.tar.gz || handle_error "Extract Multicraft"
cd multicraft || handle_error "Multicraft Directory"

# Otomasi Instalasi
echo -e "\n--- Melakukan instalasi otomatis ---"
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
send "${PASSWORD}\r"

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
[ $? -eq 0 ] || handle_error "Automated Setup"

# Konfigurasi Tambahan
echo -e "\n--- Menyempurnakan konfigurasi ---"
sed -i "s/^daemon_db_user =.*/daemon_db_user = multicraft_daemon/" /home/minecraft/multicraft/multicraft.conf
sed -i "s/^daemon_db_password =.*/daemon_db_password = ${DAEMON_DB_PASS}/" /home/minecraft/multicraft/multicraft.conf

# Keamanan Panel
echo "Order deny,allow
Deny from all" > /var/www/html/multicraft/protected/.htaccess
chown -R www-data:www-data /var/www/html/multicraft
find /var/www/html/multicraft -type d -exec chmod 755 {} \;
find /var/www/html/multicraft -type f -exec chmod 644 {} \;

# Systemd Service
echo -e "\n--- Membuat systemd service ---"
cat > /etc/systemd/system/multicraft.service <<EOF
[Unit]
Description=Multicraft Daemon
After=network.target

[Service]
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
systemctl start multicraft || handle_error "Service Start"

# Finalisasi
echo -e "\n\033[1;34m[5/5] FINALISASI INSTALASI\033[0m"
rm -rf /var/www/html/multicraft/install.php
mysqladmin -u root -p"${MYSQL_ROOT_PASS}" password "${PASSWORD}"

# Informasi Login
echo -e "\n\033[1;32m==== INSTALASI BERHASIL ====\033[0m"
echo "Akses Panel: https://${DOMAIN}/multicraft"
echo "Username Admin: admin"
echo "Password Admin: admin (Segera ganti setelah login!)"
echo -e "\n\033[1;33m=== INFORMASI DATABASE ==="
echo -e "Root Password: ${MYSQL_ROOT_PASS}"
echo -e "Panel DB User: multicraft_panel\nPassword: ${PANEL_DB_PASS}"
echo -e "Daemon DB User: multicraft_daemon\nPassword: ${DAEMON_DB_PASS}\033[0m"
echo -e "\n\033[1;33mSimpan informasi ini di tempat aman!\033[0m"
