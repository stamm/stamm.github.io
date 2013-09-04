---
layout: post
title: "Настройка Netbeans для yii с поддержкой xdebug, тестов phpunit и selenium"
date: 2010-10-24 14:05
comments: true
categories:
- netbeans
- selenium
- php
- php5
- php5-fpm
- xdebug
- yii
- phpunit
---

После прочтения книги [Agile Web Application Development with Yii 1.1 and PHP5](http://www.amazon.com/dp/1847199585?tag=gii20f-20&camp=0&creative=0&linkCode=as1&creativeASIN=1847199585&adid=0BHF2HS6FNS82M85KJQT) захотелось рассказать о настройке NetBeans для работы с yii, включая поддержку unit-тестов + тесты через selenium.

Selenium позволяет проводить тесты, почти полностью эмулируя действия через браузер: кликать по ссылкам, вводить текст.

Это очень мощно!
Имеются:
- Сервер (ip: 192.168.0.3) Debian или другой linux-сервер [с настроенным nginx, php5-fpm, xdebug](/debian-4-configure-web-server-nginx-apache-mysql-postgresql/)
- Компьютер разработчика (ip: 192.168.0.2) Ubuntu 10.10 с установленным [NetBeans 7.0m2](http://netbeans.org/downloads/index.html)

Сайт будет располагаться в /var/www/yii/www, а yii в /var/www/yii-lib/yii

Действия на сервере
Создаём папку, где будет располагаться сайт.

{% codeblock %}
mkdir -p /var/www/yii/{logs,tmp,www}
chown www-data.www-data /var/www/yii/{tmp,www}
chmod 0700 /var/www/yii/{tmp,www}
{% endcodeblock %}

Создаём конфиг для php5-fpm. Файл: /etc/php5/fpm/pool.d/yii.conf
{% codeblock %}
[yii]
listen = /var/run/php5-fpm/yii.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

user = www-data
group = www-data

pm = dynamic
pm.max_children = 50
pm.start_servers = 1
pm.min_spare_servers = 1
pm.max_spare_servers = 5
pm.max_requests = 500

pm.status_path = /status
ping.path = /ping
ping.response = pong
; Это значение стоит увеличить при активном использовании xdebug, иначе скрипт отвалится. Также нужно соответственно изменить в nginx параметр fastcgi_read_timeout.
request_terminate_timeout = 5m
request_slowlog_timeout = 2s
slowlog = /var/www/yii/logs/php-fpm.slow.log
chdir = /var/www/yii/www
catch_workers_output = yes

env[TMP] = /var/www/yii/tmp
env[TMPDIR] = /var/www/yii/tmp
env[TEMP] = /var/www/yii/tmp

php_flag[display_errors] = on
php_admin_value[error_log] = /var/www/yii/logs/fpm-php.log
php_admin_flag[log_errors] = on

php_admin_value[open_basedir] = /var/www/yii/www:/var/www/yii/tmp:/var/www/yii/yii
php_admin_value[upload_tmp_dir] = /var/www/yii/tmp
php_admin_value[session.save_path] = /var/www/yii/tmp
{% endcodeblock %}

Конфигурация сайта для nginx. Файл: /etc/nginx/sites-available/yii

{% codeblock %}
upstream yii {
  server unix:/var/run/php5-fpm/yii.sock;
}
server {
  listen   80;
  server_name yii.local;
  server_tokens off;
  server_name_in_redirect  off;

  access_log /var/www/yii/logs/nginx.access.log gzip;
  error_log /var/www/yii/logs/nginx.error.log warn;

  # ОБЯЗАТЕЛЬНО нужно отключить gzip, потому что тесты selenium не будет работать
  gzip off;
  charset utf-8;
  client_max_body_size 1m;
  fastcgi_intercept_errors on;

  # Это значение стоит увеличить при активном использовании xdebug, иначе скрипт отвалится. Также нужно соответственно изменить в php5-fpm параметр request_terminate_timeout.
  fastcgi_read_timeout 600;
  root /var/www/yii/www;
  index index.php index.html index.htm;

  location ~ /.ht
  {
    deny all;
  }

  location ~ /(.git|protected)/ {
    deny all;
  }

  location ~ /(assets|css)/ {
    expires 7d;
  }

  location / {
    try_files $uri $uri/ @php;
  }

  location ~ \.php$ {
    try_files $uri @php;
    fastcgi_pass yii;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME /var/www/yii/www$fastcgi_script_name;
    include fastcgi_params;
  }

  location @php {
    fastcgi_pass yii;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME /var/www/yii/www/index.php;
    fastcgi_param SCRIPT_NAME /index.php;
    fastcgi_param QUERY_STRING q=$uri&$args;
    include fastcgi_params;
  }
}
{% endcodeblock %}


Включаем сайт, путём линкования в папку sites-enabled.

Скачивание yii

{% codeblock %}
# Скачиваем исходники yii
cd /usr/local/src
wget http://yii.googlecode.com/files/yii-1.1.4.r2429.tar.gz
mkdir -p /var/www/yii-lib/
tar xvfz yii-1.1.4.r2429.tar.gz -C /var/www/yii-lib/
cd /var/www/yii-lib/
# Делаем линк на текущую версию
ln -s yii-1.1.4.r2429 yii
# Меняем пользователя и группу
chown -R www-data.www-data /var/www/yii-lib/
# Создаём веб-приложение
/var/www/yii-lib/yii/framework/yiic webapp /var/www/yii/www/
Create a Web application under '/var/www/yii/www'? [Yes|No] Y
# Меняем пользователя и группу
chown -R www-data.www-data /var/www/yii/www
{% endcodeblock %}

Устанавливаем php5-xdebug

{% codeblock %}
aptitude install php5-xdebug
{% endcodeblock %}

Настраиваем xdebug для работы отладки /etc/php5/fpm/conf.d/xdebug.ini

{% codeblock %}
zend_extension=/usr/lib/php5/20090626+lfs/xdebug.so

xdebug.remote_enable=on
xdebug.remote_handler=dbgp
xdebug.remote_mode=req
# Ip-адрес компьютера разработчика
xdebug.remote_host=192.168.0.2
xdebug.remote_log="/var/log/xdebug.log"
# По-умолчанию, используется 9000 порт, но он у меня уже занят.
xdebug.remote_port=9009
xdebug.idekey=netbeans-xdebug
{% endcodeblock %}

Рестартим fpm и apache:

{% codeblock %}
invoke-rc.d php5-fpm restart
invoke-rc.d apache2 restart
{% endcodeblock %}

Настройка компьютера разработчика
Я монтирую всю папку /var/www к себе. Это очень удобно, т.к. не нужно скачивать все файлы с сайта. Нужен пакет sshfs.

{% codeblock %}
sudo mkdir -p /mnt/www
sudo chown ВЫ.ВЫ /mnt/www
sshfs www-data@192.168.0.3:/var/www /mnt/www
{% endcodeblock %}

Прописываем в /etc/hosts


{% codeblock %}
192.168.0.3 yii.local
{% endcodeblock %}

Phpunit
Устанавливаем

{% codeblock %}
{% endcodeblock %}

{% codeblock %}
{% endcodeblock %}

{% codeblock %}
{% endcodeblock %}

[Скачиваем последний дистрибутив Debian](http://www.debian.org/CD/torrent-cd/)
![Схема сети](/images/debian-1-install/schema.png)