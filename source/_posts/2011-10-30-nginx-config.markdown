---
layout: post
title: "Nginx: общие принципы конфигурации"
date: 2011-10-30 18:59
comments: true
categories: nginx
---

На днях посмотрел [видео с участием Игоря Сысоева](http://video.yandex.ru/users/ibondarets/view/1/) - отца русского nginx =)

В выступлении Игорь говорит не о мастабировании в привычном для всех понимании (высокая нагрузка), а в плане рекомендаций к написанию конфигурации для nginx, чтобы при росте конфигурации не было проблем с его редактированием.

## Виды location:
1. Описанные простыми строками (статические)

{% codeblock %}
location /dir/ {} - обычный префиксный location
location = /dir/ {} - точное совпадение по запросу
location ^~ /dir/ {} - префиксный location, но после него не идёт проверка по location на регулярных выражениях
{% endcodeblock %}

2. Описанные регулярными выражениями

{% codeblock %}
location ~ /dir/ {} - с учётом регистра
location ~* /dir/ {} - без учёта регистра
{% endcodeblock %}

3. Именнованные location

{% codeblock %}
location @php {}
{% endcodeblock %}

Расположение статических location не играет роли.

Location'ы, написанные с помощью регулярных выражений, выполянются в порядке написания.

По возможности используйте статические location'ы. Например, вместо

{% codeblock %}
location ~ .(css|js|jpe?g|png)$ {}
{% endcodeblock %}

выносить все статические файлы в определённый каталог

{% codeblock %}
location /static/ {}
{% endcodeblock %}

Заворачивание location на регулярном выражении в статический location

{% codeblock %}
location ~* ^/i/(.)(.-\.gif)(
  alias /images/$1$1$2
)
{% endcodeblock %}

{% codeblock %}
location /i/ {
  location ~* ^/i/(.)(.-\.gif)$ {
    alias /images/$1$1$2
  }
  return 404
}
{% endcodeblock %}

Понимание директив root и alias:

В общем смысле, root - добавляем в запрос путь в качестве префикса, а alias - заменяет location на указанный в директиве alias



{% codeblock %}
location /dir/ {
    root /path/to/data;
}
{% endcodeblock %}

{% codeblock %}
             /dir/a/image.gif
/path/to/data/dir/a/image.gif
{% endcodeblock %}

{% codeblock %}
location /dir/ {
     alias /path/to/data/;
}
{% endcodeblock %}

{% codeblock %}
         /dir/a/image.gif
/path/to/data/a/image.gif
{% endcodeblock %}



{% codeblock %}
location ~ ^/dir/ {
  root /path/to/$subdomain;
}
{% endcodeblock %}


{% codeblock %}
             /dir/a/image.gif
/path/to/shop/dir/a/image.gif
{% endcodeblock %}

{% codeblock %}
location ~ ^/dir/.+/(.)(.*)$ {
    alias /path/to/data/$1/$1$2;
}
{% endcodeblock %}

{% codeblock %}
         /dir/a/image.gif
/path/to/data/i/image.gif
{% endcodeblock %}

{% codeblock %}
location ~ ^/dir/ {
    alias /path/to/data/0.gif
}
{% endcodeblock %}

{% codeblock %}
/dir/a/image.gif
/path/to/data/0.gif
{% endcodeblock %}

Обратите внимание на конечных слэш в proxy_pass

{% codeblock %}
location /dir/ {
  proxy_pass http://back
}
{% endcodeblock %}

{% codeblock %}
/dir/a/image.gif
/dir/a/image.gif
{% endcodeblock %}

{% codeblock %}
location /dir/ {
    proxy_pass http://back/
}
{% endcodeblock %}

{% codeblock %}
/dir/a/image.gif
    /a/image.gif
{% endcodeblock %}

Большинство директив носит декларативный характер, а это значит нет разницы, где их определять.

{% codeblock %}
server {
    location / {}
    location /images/ {}
    
    root /path/;
}
{% endcodeblock %}

Не рекомендуется использовать if. В примере сработает только последний if. Игорь рекомендует использовать if в связке с return.

{% codeblock %}
location / {

  if (1) {
    gzip off;
  }

  if (1) {
    keepalive off;
  }
}
{% endcodeblock %}

## Распространённые ошибки:

В этом примере break вообще не нужен, а expires можно вынести в location

{% codeblock %}
location ~* \.(gif|jpe?g|png)$ {
  root /data;
  if (-e $request_filename) {
     expires 1y;
     break;
  }
}
{% endcodeblock %}

Break тут не нужен.

{% codeblock %}
location ~* \.(gif|jpe?g|png)$ {
   root /data;
   break;
}
{% endcodeblock %}

Такое возникает у переходящих с apache. Тут нужно заменить всё на статические location.

{% codeblock %}
location / {
  if ($uri ~ ^/login.php$) { }

  if ($uri ~ ^/image.php$) { }
}
{% endcodeblock %}