---
date: "2010-07-28 04:00:00"
slug: "debian-4-configure-web-server-nginx-apache-mysql-postgresql"
aliases: ["debian-4-configure-web-server-nginx-apache-mysql-postgresql"]
tags: ["postgresql", "apache", "logrotate", "php", "debian", "mysql", "nginx", "bind"]
title: "Debian. Часть 4. Настройка веб-сервера: nginx, apache, mysql, postgresql"
---

У меня работает связка nginx -> apache2 + mysql + postgresql. Поставим memcached, APC (кэшер для php), и несколько модулей для php5.

Для того, чтобы nginx проксировал через локальный адрес (192.168.1.254, например), необходимо добавить в bind наш домен. Это ещё пригодиться для доступа из локальной сети, чтобы запросы не шли через «внешку», а также для однозначной идентификации того, что заходят из «доверенной» сети. Добавляем в файл /etc/bind/named.conf.local наш домен:

```
zone "zagirov.name" {
    type master;
    file "/etc/bind/db.zagirov.name";
};
```

Создаём файл /etc/bind/db.zagirov.name:

```
$TTL    604800
@   IN  SOA zagirov.name. root.zagirov.name. (
                  2     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
;
@   IN  NS  localhost.
@   IN  A   192.168.1.254
*   IN  A   192.168.1.254
```

Я использую Debian testing (squeeze). Устанавливаем пакеты:

```
aptitude install apache2 nginx libapache2-mod-php5 php5-cli php5-mysql php5-pgsql php5-xmlrpc php5-gd php5-curl php5-xsl php-apc memcached php5-memcache mysql-server postgresql
```

Структура папок сайта: logs – логи tmp – папка для временных файлов и файлов сессии www – содержимое сайта

Создадим «эталонную» папку для сайта, которая будет структурой для будущих сайтов

```
mkdir - p /var/www/etalon/{logs,tmp,www}
chown www-data.www-data /var/www/etalon/{tmp,www}
chmod 0700 /var/www/etalon/{tmp,www}
```

Открываем в mc папку /var/www/, выбираем папку etalon, нажимает shift+F5, вводим название сайта(zagirov.name). Появилась папка для будущего сайта: /var/www/zagirov.name/ Чтобы логи архивировались, создаём правило для logrotate в файле /etc/logrotate.d/sites:

```
/var/www/*/logs/*.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root root
    sharedscripts
    postrotate
        if [ -f "`. /etc/apache2/envvars ; echo ${APACHE_PID_FILE:-/var/run/apache2.pid}`" ]; then
            /etc/init.d/apache2 reload > /dev/null
        fi
        [ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

Теперь настраиваем nginx. Удаляем все символические ссылки из папки /etc/nginx/sites-enabled Создаём конфигурацию для неописанных доменов: /etc/nginx/sites-available/default_http В случае, когда сайт не описан nginx просто разорвёт соединение, ничего не выдав.

```
server {
    listen          80 default;
    server_name     _;
    access_log      off;
    server_name_in_redirect  off;
    return 444;
}
```

Открываем mc. В левой панели /etc/nginx/sites-enabled, в правой – /etc/nginx/sites-available Выбираем файл default_http и нажимаем комбинацию Ctrl+X, а затем S – это создаст символическую ссылку выбранного файла в папке другой панели. Теперь создадим файл для сайта /etc/nginx/sites-available/zagirov.name:

```
server {
    listen   80;
    server_name zagirov.name www.zagirov.name rustam.zagirov.name;

    server_tokens off;

    access_log /var/www/zagirov.name/logs/nginx.access.log;
    error_log /var/www/zagirov.name/logs/nginx.error.log warn;

    charset utf-8;
    client_max_body_size 1m;

    root /var/www/zagirov.name/www;
    index index.php index.html index.htm;

    location / {
        #Реврайт
        #try_files $uri $uri /index.php?q=$uri&$args;

        proxy_pass http://zagirov.name:81;
        include proxy.conf;
    }

    #Тут перечисляем все пути и файлы статики (картинки, стили)
    location ~ /(favicon.ico|wp-content/uploads/|wp-content/themes/openark-blog/(images/|style.css)) {
        expires 7d;
    }
}
```

Опять включаем сайт созданием символической ссылки.

Теперь настраиваем apache. Удаляем включённые по дефолту сайты из папки /etc/apache2/sites-enabled Меняем порт с 80 на 81 в файле /etc/apache2/ports.conf:

```
NameVirtualHost *:81
Listen 81
```

Создаём конфигурацию для неописанных доменов: /etc/apache2/sites-available/default_http

```
<virtualhost *:81>
    ServerName default
</virtualhost>
```

Создадим настройки для сайта в файле /etc/apache2/sites-available/zagirov.name:

```
<virtualhost *:81>
    ServerName zagirov.name
    ServerAlias www.zagirov.name rustam.zagirov.name
    DocumentRoot /var/www/zagirov.name/www
    ErrorLog /var/www/zagirov.name/logs/apache2.error.log
    CustomLog /var/www/zagirov.name/logs/apache2.access.log combined
    AddDefaultCharset UTF8
    php_flag magic_quotes_gpc off
    php_admin_value open_basedir "/var/www/zagirov.name/www"
    php_admin_value upload_tmp_dir "/var/www/zagirov.name/tmp"
    php_value session.save_path "/var/www/zagirov.name/tmp"
</virtualhost>
```

Включаем сайт:

```
a2ensite zagirov.name
```

Перезапускаем apache и nginx.

```
invoke-rc.d apache2 restart
invoke-rc.d nginx restart
```

Установка рутового пароля для пользователя postgres для PostgreSQL:

```
su postgres
psql -d template1
ALTER USER postgres WITH PASSWORD 'Str0ng passw0rd';
```

[← Часть 3](/post/debian-3-setting-iptables-forward-nat-firewall) 
