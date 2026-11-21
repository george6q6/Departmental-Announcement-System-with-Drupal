#!/usr/bin/env bash
# Drupal Bölüm Duyuru Sistemi - Geri Yükleme Betiği
# Kullanım:
#   sudo ./geri_yukle.sh                      -> en son yedeği geri yükler
#   sudo ./geri_yukle.sh 2026-11-21_14-02     -> belirtilen tarihli yedeği geri yükler

set -euo pipefail

# Veritabanı bilgilerini içeri aktar (DB_USER, DB_PASS, DB_NAME)
source /root/.drupal_db_bilgileri

YEDEK_KLASORU="/var/backups/drupal"
SITE_KLASORU="/var/www/drupal"

# Tarih verilmediyse en son alınan yedeği bul
if [ -n "${1:-}" ]; then
  TARIH="$1"
else
  SON_SQL=$(ls -t "$YEDEK_KLASORU"/veritabani_*.sql | head -n 1)
  TARIH=$(basename "$SON_SQL" .sql | sed 's/^veritabani_//')
  echo "Tarih verilmedi, en son yedek kullanilacak: $TARIH"
fi

SQL_DOSYASI="$YEDEK_KLASORU/veritabani_$TARIH.sql"
ARSIV_DOSYASI="$YEDEK_KLASORU/dosyalar_$TARIH.tar.gz"

# Yedek dosyaları gerçekten var mı?
if [ ! -f "$SQL_DOSYASI" ] || [ ! -f "$ARSIV_DOSYASI" ]; then
  echo "HATA: $TARIH tarihli yedek dosyalari bulunamadi."
  echo "Mevcut yedekler:"
  ls -1 "$YEDEK_KLASORU"
  exit 1
fi

echo "Geri yukleme basliyor: $TARIH"

# 1) Veritabanını geri yükle
echo "Veritabani geri yukleniyor..."
MYSQL_PWD="$DB_PASS" mysql -u "$DB_USER" "$DB_NAME" < "$SQL_DOSYASI"

# 2) Site dosyalarını geri yükle
echo "Site dosyalari geri yukleniyor..."
tar -xzf "$ARSIV_DOSYASI" -C /

# 3) Dosya sahipliğini web sunucusuna ver (yüklenen ekler için gerekli)
chown -R www-data:www-data "$SITE_KLASORU/sites/default/files" 2>/dev/null || true

# 4) Drupal önbelleğini temizle (drush kuruluysa)
if command -v drush >/dev/null 2>&1; then
  drush --root="$SITE_KLASORU" cache:rebuild || true
fi

echo "Geri yukleme basariyla tamamlandi: $TARIH"
