# Departmental-Announcement-System-with-Drupal
Information System Engineering
Linux Operating System Usage and Managment 
Group-8 Departmental Announcement System with Drupal 

# Bölüm Duyuru Sistemi (Grup 8)

Uygulama **Drupal 11** üzerine kuruludur ve **Apache + MariaDB + PHP** ile çalışır.

## Ekip
|----------|-----------|
| Kuzey Elyasa Turan | 251307057 |
| İpeksu Atakan | 251307064 |

## Gereksinimler

- **Ubuntu 24.04 veya 26.04** (betik yalnızca Ubuntu'da çalışır)
- `sudo` yetkisi
- İnternet bağlantısı 
- En az **2 GB** boş disk alanı (`/var` altında)

Apache, MariaDB, PHP (8.3 veya üstü), Composer ve Drupal'in kendisi `drupal_kurulum.sh` tarafından otomatik kurulur.

## Kurulum

### 1. Depoyu klonlayın

```bash
git clone <repo-linki>
cd <proje-klasoru>
```

### 2. Kurulum betiğini çalıştırın

```bash
sudo bash drupal_kur.sh (Bu komut yerine 'sudo ./drupal_kurulum.sh' yazılabilir.)
```

Kurulum birkaç dakika sürebilir. Betik bitince ekranda "Kurulum betiği tamamlandı." mesajını ve kurulan sürümleri görmelisiniz.

### 3. Drupal web kurulumunu tamamlayın

Tarayıcıda şu adresi açın:

```
http://localhost
```

Kurulum sihirbazında sırasıyla:

1. Dil seçin.
2. Kurulum profili olarak **Standart** seçin.
3. Veritabanı ekranında şu bilgileri girin:

    |----------|-----------|
   | Veritabanı türü | MySQL, MariaDB, Percona Server veya eşdeğeri |
   | Veritabanı adı | `drupal` |
   | Veritabanı kullanıcısı | `drupaluser` |
   | Veritabanı parolası | Aşağıdaki komutun çıktısındaki `DB_PASS` değeri |

   Parolayı görmek için:
   ```bash
   sudo cat /root/.drupal_db_bilgileri
   ```
4. Site adı ve yönetici hesabı bilgilerini girin (aşağıdaki "Giriş Bilgileri" bölümüne bakın).

### 4. Kurulum sonrası ayar (önerilir)

Web kurulumu bittikten sonra ayar dosyasını korumaya alın:

```bash
sudo chmod 444 /var/www/drupal/web/sites/default/settings.php
sudo chmod 555 /var/www/drupal/web/sites/default
```

## Giriş Bilgileri

|----------|-----------|
| Yönetici kullanıcı adı | [admin] |
| Yönetici parolası | [parola] |
| Giriş sayfası | `http://localhost/user/login` |

## drupal_kur.sh Ne Yapar?

1. **Ön koşulları kontrol eder:** root yetkisi, Ubuntu, internet bağlantısı, boş disk alanı.
2. **Paketleri kurar:** Apache, MariaDB, PHP ve eklentileri (gd, xml, mbstring, curl, zip, intl, mysql), Composer. PHP sürümünün en az 8.3 olduğunu doğrular.
3. **Veritabanını hazırlar:** `drupal` veritabanını ve `drupaluser` kullanıcısını oluşturur. Parolayı rastgele üretir ve yalnızca root'un okuyabildiği `/root/.drupal_db_bilgileri` dosyasına yazar.
4. **Drupal'i indirir:** `composer create-project drupal/recommended-project` ile `/var/www/drupal` klasörüne kurar.
5. **Dosya izinlerini ayarlar:** `settings.php` ve `files` klasörünü hazırlar, sahipliği `www-data` kullanıcısına verir.
6. **Apache'yi yapılandırır:** `drupal` sanal sunucusunu oluşturur, `rewrite` modülünü açar, varsayılan siteyi devre dışı bırakır.
7. **PHP ayarlarını günceller:** `memory_limit=256M`, `upload_max_filesize=20M`, `post_max_size=25M`.
8. **Apache'yi yeniden başlatır** ve özet bilgi yazdırır.

Betik **tekrar çalıştırılabilir**: Drupal zaten indirilmişse o adımı atlar, önceki veritabanı parolasını yeniden kullanır.

### İsteğe bağlı ayarlar

Varsayılan değerler ortam değişkenleriyle değiştirilebilir:

```bash
sudo DB_NAME=mydb DB_USER=myuser DB_PASS=gizli SITE_DIR=/var/www/site bash drupal_kur.sh
```

|----------|-----------|
| `DB_NAME` | `drupal` |
| `DB_USER` | `drupaluser` |
| `DB_PASS` | Rastgele üretilir |
| `SITE_DIR` | `/var/www/drupal` |
| `SERVER_NAME` | `drupal.local` |

## Proje Yapısı

```
[Kendi yapınıza göre düzenleyin, ör.]
├── drupal_kur.sh          # Otomatik kurulum betiği
├── README.md
├── config/                # [Varsa] Drupal yapılandırma dışa aktarımı
└── modules/custom/        # [Varsa] Özel modüller
```

## Sorun Giderme

|----------|-----------|
| `Bu betik root yetkisiyle çalışmalı` | `sudo bash drupal_kur.sh` ile çalıştırın. |
| `Bu betik Ubuntu için yazıldı` | Ubuntu 24.04 veya 26.04 kullanın. |
| `drupal.org'a ulaşılamıyor` | İnternet bağlantınızı kontrol edin. |
| `Yetersiz disk alanı` | `/var` altında en az 2 GB yer açın. |
| `/var/www/drupal boş değil` | Klasörü temizleyin ya da `SITE_DIR` ile farklı klasör verin. |
| Sayfa açılmıyor | `sudo systemctl status apache2 mariadb` ile servisleri kontrol edin. |
| Apache hatası | `sudo tail /var/log/apache2/drupal_error.log` |
| Kurulum sihirbazı `settings.php` yazamıyor | `sudo chmod 664 /var/www/drupal/web/sites/default/settings.php` |

## Güvenlik Notu

`/root/.drupal_db_bilgileri` dosyası veritabanı parolasını içerir. Bu dosyayı **Git deposuna eklemeyin**.
