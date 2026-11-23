# Departmental-Announcement-System-with-Drupal
Information System Engineering
Linux Operating System Usage and Managment 
Group-8 Departmental Announcement System with Drupal 

# Departmental-Announcement-System-with-Drupal

## Gereksinimler

- Linux işletim sistemi 
- İnternet bağlantısı
- `sudo` yetkisine sahip bir kullanıcı

Diğer tüm bileşenler (Apache, PHP, MariaDB, Composer, Drupal vb.) `kurulum.sh` betiği tarafından otomatik olarak kurulur.

## Kurulum

1. Depoyu klonlayın ve proje klasörüne girin:
   ```bash
   git clone <repo-linki>
   cd <proje-klasoru>
   ```

2. Betiğe çalıştırma izni verin:
   ```bash
   chmod +x kurulum.sh
   ```

3. Kurulum betiğini çalıştırın:
   ```bash
   sudo ./kurulum.sh
   ```

4. Betik tamamlandığında tarayıcıdan şu adrese gidin:
   ```
   http://localhost
   ```
   [Port farklıysa: `http://localhost:8080`]

## kurulum.sh Ne Yapar?

Betik sırasıyla şu işlemleri gerçekleştirir:

1. Paket listesini günceller.
2. Gerekli yazılımları kurar: [Apache, PHP ve eklentileri, MariaDB, Composer].
3. Veritabanını ve veritabanı kullanıcısını oluşturur.
4. Drupal'i kurar ve yapılandırır.
5. [Varsa: Projeye ait özel modül/tema ve yapılandırma dosyalarını yükler.]
6. Servisleri başlatır.

## Giriş Bilgileri

| Alan | Değer |
|------|-------|
| Yönetici kullanıcı adı | [admin] |
| Yönetici şifresi | [şifre] |
| Yönetim paneli | `http://localhost/user/login` |

## Sorun Giderme

- **Permission denied hatası:** `chmod +x kurulum.sh` komutunu çalıştırdığınızdan emin olun.
- **Port kullanımda hatası:** 80 numaralı portu kullanan başka bir servisi (ör. `sudo systemctl stop nginx`) durdurun.
- **Kurulum yarıda kesildi:** Betiği tekrar çalıştırabilirsiniz. [Betiğiniz tekrar çalıştırmaya uygundur.]
