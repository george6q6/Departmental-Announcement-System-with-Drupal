#!/usr/bin/env bash
# ------------------------------------------------------------------
# Drupal kurulum betiği (Grup 8 - Bölüm Duyuru Sistemi)
# Hedef sistem : Ubuntu 24.04 / 26.04 (Apache + MariaDB + PHP + Drupal 11)
# Not: PHP 8.5'te OPcache PHP'nin içinde gelir, ayrı paket gerekmez.
# Kullanım     : sudo bash drupal_kur.sh
# İsteğe bağlı : DB_PASS=... sudo -E bash drupal_kur.sh
# Betik tekrar çalıştırılabilir; var olanı bozmadan devam eder.
# ------------------------------------------------------------------
set -euo pipefail

# ---------- Ayarlar ----------
DB_NAME="${DB_NAME:-drupal}"
DB_USER="${DB_USER:-drupaluser}"
DB_PASS="${DB_PASS:-}"
SITE_DIR="${SITE_DIR:-/var/www/drupal}"
SERVER_NAME="${SERVER_NAME:-drupal.local}"
MIN_PHP="8.3"
MIN_DISK_MB=2048
CRED_FILE="/root/.drupal_db_bilgileri"   # Git'e ekleme!!!!!!

# ---------- Yardımcı fonksiyonlar ----------
log()  { echo -e "\033[1;34m[BİLGİ]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[TAMAM]\033[0m $*"; }
fail() { echo -e "\033[1;31m[HATA]\033[0m  $*" >&2; exit 1; }

trap 'fail "Betik $LINENO. satırda beklenmedik şekilde durdu. Yukarıdaki çıktıya bakın."' ERR

# ---------- 1. Ön koşul kontrolleri ----------
log "Ön koşullar kontrol ediliyor..."

[[ $EUID -eq 0 ]] || fail "Bu betik root yetkisiyle çalışmalı. Şöyle deneyin: sudo bash $0"

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "ubuntu" ]] || fail "Bu betik Ubuntu için yazıldı (tespit edilen: ${ID:-bilinmiyor})."
else
  fail "İşletim sistemi tespit edilemedi (/etc/os-release yok)."
fi

command -v curl >/dev/null 2>&1 || { apt-get update -y >/dev/null && apt-get install -y curl >/dev/null; }

curl -fsI --max-time 10 https://www.drupal.org >/dev/null 2>&1 \
  || fail "İnternet bağlantısı yok ya da drupal.org'a ulaşılamıyor. Ağ ayarlarını kontrol edin."

FREE_MB=$(df -Pm /var | awk 'NR==2 {print $4}')
[[ "$FREE_MB" -ge "$MIN_DISK_MB" ]] \
  || fail "Yetersiz disk alanı: ${FREE_MB} MB boş, en az ${MIN_DISK_MB} MB gerekli."

ok "Ön koşullar tamam (Ubuntu ${VERSION_ID}, ${FREE_MB} MB boş alan)."

# ---------- 2. Paket kurulumu ----------
log "Paketler kuruluyor (Apache, MariaDB, PHP, Composer)... Bu birkaç dakika sürebilir."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null
apt-get install -y apache2 mariadb-server \
  php php-cli libapache2-mod-php php-mysql php-gd php-xml \
  php-mbstring php-curl php-zip php-intl \
  unzip curl composer openssl >/dev/null \
  || fail "Paket kurulumu başarısız oldu. 'apt-get install' çıktısını elle çalıştırıp bakın."

PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
if ! php -r "exit(version_compare(PHP_VERSION, '${MIN_PHP}', '>=') ? 0 : 1);"; then
  fail "PHP sürümü çok eski: ${PHP_VER}. En az ${MIN_PHP} gerekli."
fi
ok "Paketler kuruldu (PHP ${PHP_VER})."

systemctl enable --now mariadb apache2 >/dev/null 2>&1 \
  || fail "Apache veya MariaDB başlatılamadı. 'systemctl status apache2 mariadb' ile bakın."

# ---------- 3. Veritabanı ----------
log "Veritabanı hazırlanıyor..."

if [[ -z "$DB_PASS" ]]; then
  if [[ -f "$CRED_FILE" ]]; then
    DB_PASS=$(grep '^DB_PASS=' "$CRED_FILE" | cut -d= -f2-)
    log "Önceki çalıştırmadan kayıtlı parola kullanılıyor."
  else
    DB_PASS=$(openssl rand -base64 18 | tr -d '/+=')
  fi
fi

mysql <<SQL || fail "Veritabanı işlemi başarısız. MariaDB çalışıyor mu? (systemctl status mariadb)"
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

umask 077
printf 'DB_NAME=%s\nDB_USER=%s\nDB_PASS=%s\n' "$DB_NAME" "$DB_USER" "$DB_PASS" > "$CRED_FILE"
umask 022
ok "Veritabanı hazır. Bilgiler: $CRED_FILE (yalnızca root okuyabilir)"

# ---------- 4. Drupal indirme ----------
if [[ -f "${SITE_DIR}/web/index.php" ]]; then
  log "Drupal zaten indirilmiş (${SITE_DIR}), bu adım atlanıyor."
else
  log "Drupal indiriliyor (Composer)... Bu birkaç dakika sürebilir."
  mkdir -p "$SITE_DIR"
  if [[ -n "$(ls -A "$SITE_DIR" 2>/dev/null)" ]]; then
    fail "${SITE_DIR} boş değil ve içinde Drupal yok. Klasörü temizleyin ya da SITE_DIR değiştirin."
  fi
  COMPOSER_ALLOW_SUPERUSER=1 composer create-project drupal/recommended-project "$SITE_DIR" --no-interaction \
    || fail "Composer ile Drupal indirilemedi. İnternet bağlantısını ve PHP eklentilerini kontrol edin."
  ok "Drupal indirildi."
fi

# ---------- 5. Dosya izinleri ----------
log "Dosya izinleri ayarlanıyor..."
DEFAULT_DIR="${SITE_DIR}/web/sites/default"
mkdir -p "${DEFAULT_DIR}/files"
if [[ ! -f "${DEFAULT_DIR}/settings.php" ]]; then
  cp "${DEFAULT_DIR}/default.settings.php" "${DEFAULT_DIR}/settings.php"
fi
chown -R www-data:www-data "$SITE_DIR"
chmod 775 "${DEFAULT_DIR}/files"
chmod 664 "${DEFAULT_DIR}/settings.php"
ok "İzinler ayarlandı."

# ---------- 6. Apache yapılandırması ----------
log "Apache yapılandırılıyor..."
cat > /etc/apache2/sites-available/drupal.conf <<EOF
<VirtualHost *:80>
    ServerName ${SERVER_NAME}
    DocumentRoot ${SITE_DIR}/web

    <Directory ${SITE_DIR}/web>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/drupal_error.log
    CustomLog \${APACHE_LOG_DIR}/drupal_access.log combined
</VirtualHost>
EOF

a2enmod rewrite >/dev/null
a2dissite 000-default >/dev/null 2>&1 || true
a2ensite drupal >/dev/null
apache2ctl configtest >/dev/null 2>&1 \
  || fail "Apache yapılandırmasında hata var. 'apache2ctl configtest' çıktısına bakın."

# ---------- 7. PHP ayarları ----------
PHP_INI="/etc/php/${PHP_VER}/apache2/php.ini"
if [[ -f "$PHP_INI" ]]; then
  sed -i 's/^memory_limit = .*/memory_limit = 256M/'            "$PHP_INI"
  sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' "$PHP_INI"
  sed -i 's/^post_max_size = .*/post_max_size = 25M/'            "$PHP_INI"
  ok "PHP ayarları güncellendi."
else
  log "Uyarı: ${PHP_INI} bulunamadı, PHP ayarları elle yapılmalı."
fi

systemctl restart apache2 || fail "Apache yeniden başlatılamadı. 'journalctl -xeu apache2' ile bakın."

# ---------- Özet ----------
echo
ok "Kurulum betiği tamamlandı."
echo "  Sürümler : $(php -v | head -1 | cut -d' ' -f1-2), $(apache2 -v | head -1 | cut -d: -f2 | xargs), $(mysql --version | cut -d' ' -f1-5)"
echo "  Veritabanı: ad=${DB_NAME}  kullanıcı=${DB_USER}  (parola: ${CRED_FILE})"
echo "  Sonraki adım: Tarayıcıda siteyi açıp Drupal web kurulumunu tamamlayın."
echo "  Kurulum bitince şunu çalıştırın:"
echo "    chmod 444 ${DEFAULT_DIR}/settings.php && chmod 555 ${DEFAULT_DIR}"


