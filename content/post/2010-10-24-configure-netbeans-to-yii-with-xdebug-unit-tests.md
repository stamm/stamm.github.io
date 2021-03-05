---
date: "2010-10-24"
slug: "configure-netbeans-to-yii-with-xdebug-unit-tests"
aliases: ["configure-netbeans-to-yii-with-xdebug-unit-tests"]
tags: ["netbeans", "selenium", "php", "php5", "php5-fpm", "xdebug", "yii", "phpunit"]
title: "Настройка Netbeans для yii с поддержкой xdebug, тестов phpunit и selenium"
---

После прочтения книги [Agile Web Application Development with Yii 1.1 and PHP5](http://www.amazon.com/dp/1847199585?tag=gii20f-20&camp=0&creative=0&linkCode=as1&creativeASIN=1847199585&adid=0BHF2HS6FNS82M85KJQT) захотелось рассказать о настройке NetBeans для работы с yii, включая поддержку unit-тестов + тесты через selenium.

Selenium позволяет проводить тесты, почти полностью эмулируя действия через браузер: кликать по ссылкам, вводить текст.

Это очень мощно!
Имеются:
- Сервер (ip: 192.168.0.3) Debian или другой linux-сервер [с настроенным nginx, php5-fpm, xdebug](/debian-4-configure-web-server-nginx-apache-mysql-postgresql/)
- Компьютер разработчика (ip: 192.168.0.2) Ubuntu 10.10 с установленным [NetBeans 7.0m2](http://netbeans.org/downloads/index.html)

Сайт будет располагаться в **/var/www/yii/www**, а yii в **/var/www/yii-lib/yii**

Действия на сервере
Создаём папку, где будет располагаться сайт.

```
mkdir -p /var/www/yii/{logs,tmp,www}
chown www-data.www-data /var/www/yii/{tmp,www}
chmod 0700 /var/www/yii/{tmp,www}
```

Создаём конфиг для php5-fpm. Файл: **/etc/php5/fpm/pool.d/yii.conf**
```
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
```

Конфигурация сайта для nginx. Файл: **/etc/nginx/sites-available/yii**

```
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
```


Включаем сайт, путём линкования в папку sites-enabled.

Скачивание yii

```
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
```

Устанавливаем php5-xdebug

```
aptitude install php5-xdebug
```

Настраиваем xdebug для работы отладки **/etc/php5/fpm/conf.d/xdebug.ini**

```
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
```

Рестартим fpm и apache:

```
invoke-rc.d php5-fpm restart
invoke-rc.d apache2 restart
```

Настройка компьютера разработчика
Я монтирую всю папку /var/www к себе. Это очень удобно, т.к. не нужно скачивать все файлы с сайта. Нужен пакет sshfs.

```
sudo mkdir -p /mnt/www
sudo chown ВЫ.ВЫ /mnt/www
sshfs www-data@192.168.0.3:/var/www /mnt/www
```

Прописываем в **/etc/hosts**

```
192.168.0.3 yii.local
```

### Phpunit

Устанавливаем
![phpunit](/images/netbeans_yii-1.png)


### Selenium

[Скачиваем Selenium RC](http://seleniumhq.org/download/). Распаковываем и запускаем:

```
java -jar selenium/selenium-server-1.0.3/selenium-server.jar
```


### Netbeans

Устанавливаем [NetBeans](http://netbeans.org/downloads/index.html) (в моём случае это NetBeans 7.0m2). Ставим плагин **Selenium Module for PHP** (Tools → Plugins → Available Plugins).

Немного настраиваем (Tools → Options):

Php → General Ставим порт 9009 для xdebug и снимаем галку с опции **Stop at First Line**.

![phpunit](/images/netbeans_yii-2.png)

Php → Unit Testing Указываем путь до phpunit: /usr/bin/phpunit

![phpunit](/images/netbeans_yii-31.png)

Miscellaneous → Files Исключаем файл yiilite.php, чтобы при автокомплите подсказки не дублировались **^(yiilite.php|CVS|**

![phpunit](/images/netbeans_yii-16.png)

Создаём новый проект:

![phpunit](/images/netbeans_yii-4.png)

Указываем пути, название проект. Meta-файлы сохраняем в другой директории.

![phpunit](/images/netbeans_yii-5.png)

Указываем url проекта: http://yii.local/

![phpunit](/images/netbeans_yii-6.png)

Теперь вызываем настройки проекта.

Указываем директорию тестов (File → Project properties → Sources → Test Folder)

![phpunit](/images/netbeans_yii-8.png)

Задаём маппинг пути (File → Project properties → Run configuration → Advanced). Тут не видно, но указано, что /var/www доступно в /mnt/www.

![phpunit](/images/netbeans_yii-9.png)

Указываем директорию с yii: **/mnt/www/yii-lib/yii** (File → Project properties → PHP Include Path)

![phpunit](/images/netbeans_yii-10.png)

Папки, которые будут игнорироваться: **/mnt/www/yii/www/protected/runtime** (File → Project properties → Ignored Folders → Add Folder).

![phpunit](/images/netbeans_yii-11.png)

Настройка phpunit (File → Project properties → PhpUnit).

![phpunit](/images/netbeans_yii-12.png)

Открываем файлы index.php, index-test.php, protected/tests/bootstrap.php и заменяем **/yii-1.1.4.r2429/** на **/yii/**

Удалить из **protected/tests/phpunit.xml** тест под IE

```
<browser name="Internet Explorer" browser="*iexplore" />
```

Меняем константу TEST_BASE_URL в файле protected/tests/WebTestCase.php:

```
define('TEST_BASE_URL','http://yii.local/index-test.php');
```

Правим тест **protected/tests/functional/SiteTest.php (баг)**:

Заменяем $this->clickAndWait('link=Logout'); на $this->clickAndWait('link=Logout (demo)');

Теперь можно запустить тест Selenium


![phpunit](/images/netbeans_yii-13.png)

Появиться окошко выбора папки с этими тестами, указываем: /mnt/www/yii/www/protected/tests/functional

![phpunit](/images/netbeans_yii-14.png)

Будут всплывать окошки с firefox'ом и в конце концов появиться результат:

![phpunit](/images/netbeans_yii-15.png)



### Phpunit

Можно запускать phpunit тесты прямо с сервера или с рабочего компьютера, но придётся установить php и все используемые библиотеки (php5-pgsql, php5-mysql, etc). Рассмотрим 2-ой вариант. На компьютере разработчика установить phpunit и php5: Для phpunit теста можно установить свои параметры для yii в protected/config/test.php поверх стандартных (например, коннект к базе). Напишем простейший тест для проверки авторизации. Файл protected/tests/unit/AuthTest.php:

```
< ?php
class AuthTest extends CTestCase
{
  public function testAuth()
  {
    $login = new LoginForm;
    $login->username = 'demo';
    $login->password = 'demo';
    $this->assertTrue($login->login());
  }
}
```

Для выполнения теста в Netbeans нажимаем Alt+F6. При этом выполняться все тесты: и phpunit и selenium.

![phpunit](/images/netbeans_yii-17.png)


Можно выбрать AuthTest.php и нажать Shift+F6, тогда тестирование выполниться только из этого файла. Также можно выполнять phpunit тесты прямо с сервера (aptitude install phpunit):


```
cd /var/www/yii/www/protected/tests/
phpunit unit/AuthTest.php
PHPUnit 3.4.14 by Sebastian Bergmann.

.

Time: 0 seconds, Memory: 7.25Mb

OK (1 test, 1 assertion)
```



Также можно написать тесты, не использую базу данных, подменив некоторые таблицы fixtures - ассоциативным массивом, имитирующим записи в таблице.

Дебагинг кода
Тесты написаны, теперь можно дебажить код. Открываем index.php, на любой строке добавляем breakpoint (Ctrl+F8). Запускаем дебагинг (Ctrl+F5). Теперь можно "пройтись" по коду клавишами F7 (Step Into) и F8 (Step Over). Это очень помогает понять как же работает сам yii, а так же "качественно" дебажить код, видя текущие переменные, watches, Call stack.

Советую всем прочитать книгу [Agile Web Application Development with Yii1.1 and PHP5](http://www.amazon.com/dp/1847199585?tag=gii20f-20&camp=0&creative=0&linkCode=as1&creativeASIN=1847199585&adid=0BHF2HS6FNS82M85KJQT) всем, кто работает с yii. Книга поднимет уровень и в правильном написании кода для yii, и английского языка.
