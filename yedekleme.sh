#!/usr/bin/env bash

# Kurulum betiğinin kaydettiği veritabanı bilgilerini içeri aktar
source /root/.drupal_db_bilgileri

# Yedeklerin tutulacağı klasörü ve o anın tarihi
YEDEK_KLASORU="/var/backups/drupal"
TARIH=$(date +"%Y-%m-%d_%H-%M")
mkdir -p "$YEDEK_KLASORU"

# Veritabanının yedeğini alma
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$YEDEK_KLASORU/veritabani_$TARIH.sql"

# Drupal site dosyalarını sıkıştırarak yedekleme
tar -czf "$YEDEK_KLASORU/dosyalar_$TARIH.tar.gz" /var/www/drupal

echo "Yedekleme başarıyla tamamlandı: $YEDEK_KLASORU"
