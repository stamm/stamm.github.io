---
tags: [nginx]
date: 2011-05-06T00:00:00Z
title: Nginx конфиги
slug: nginx-configs
aliases: [nginx-configs]
---

В интернете довольно много можно выложено конфигов nginx под различные веб-приложения. Но в большинстве из них используются if совместно с rewrite, что достойно [всяческого порицания](http://sysoev.ru/nginx/docs/faq.html) по словам автора nginx Игоря Сысоева. Выложу используемые мной конфиги для различных систем (redmine, chive)

## Redmine:

```
upstream thin {
  server unix:/tmp/redmine.0.sock;
}

server {
  listen 80;
  server_name redmine.zagirov.name;
  root /usr/share/redmine/public/;
  access_log /var/log/nginx/redmine.access.log;
  error_log /var/log/nginx/redmine.error.log;

  location / {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    include proxy.conf;
    proxy_pass http://thin;
  }

  error_page 500 502 503 504 /500.html;
  error_page 404 403 /404.html;
}
```

## [Chive](http://www.chive-project.com/) - отличный аналог phpmyadmin

```
location /chive/ {
  try_files $uri $uri/ /chive/index.php?$request_uri&$args;
  location ~ ^/chive/(protected|yii)/ {
    deny all;
  }

  location ~ /chive/(assets|css|images|js|themes)/ {
    expires 1y;
  }

  location = /chive/index.php {
    fastcgi_pass admin_zagirov_backend;
    include fastcgi_params;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param   QUERY_STRING        $query_string&__chive_rewrite_on=1;
  }
}
```

## Конфиг для мною обожаемого Yii:

```
upstream yii-clean.zagirov.name {
  server unix:/var/run/php5-fpm/yii-clean.zagirov.name.sock;
}
server {
  listen   80;
  server_name yii-clean.zagirov.name;
  server_tokens off;
  server_name_in_redirect  off;

  access_log  /var/www/yii-clean.zagirov.name/logs/nginx.access.log;
  error_log /var/www/yii-clean.zagirov.name/logs/nginx.error.log warn;

  charset utf-8;
  client_max_body_size 10m;
  fastcgi_intercept_errors on;
  root /var/www/yii-clean.zagirov.name/www;
  index index.php index.html index.htm;

  fastcgi_read_timeout 6000;

  location ~ /(.ht|index-test.php){
    deny all;
  }

  location ~ /(.svn|.git|.svn|themes/[^/]+/views)/ {
    deny all;
  }


  location ~ /(assets|css|themes/new/css)/ {
    expires 7d;
  }

    location / {
    try_files $uri $uri/ /index.php?$request_uri&$args;
  }

  location /index.php {
    fastcgi_pass yii-clean.zagirov.name;
    include fastcgi_params;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
  }
}

server {
  listen   80;
  server_name test.yii-clean.zagirov.name;
  server_tokens off;
  server_name_in_redirect  off;

  access_log  /var/www/yii-clean.zagirov.name/logs/nginx.test.access.log;
  error_log /var/www/yii-clean.zagirov.name/logs/nginx.test.error.log warn;

  gzip off;
  charset utf-8;
  client_max_body_size 10m;
  fastcgi_intercept_errors on;
  root /var/www/yii-clean.zagirov.name/www;
  index index-test.php index.html index.htm;

  fastcgi_read_timeout 6000;

  location ~ /(.ht|index.php)
  {
    deny all;
  }

  location ~ /(.svn|.git|.svn|themes/[^/]+/views)/ {
    deny all;
  }


  location ~ /(assets|css|themes/new/css)/ {
    expires 7d;
  }

  location / {
    try_files $uri $uri/ /index-test.php?$request_uri&$args;
  }

  location /index-test.php {
    fastcgi_pass yii-clean.zagirov.name;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
  }
}
```
