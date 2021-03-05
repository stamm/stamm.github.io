---
tags: [nginx]
date: 2011-10-30T00:00:00Z
title: 'Nginx: общие принципы конфигурации'
slug: nginx-config
aliases: [nginx-config]
---

На днях посмотрел [видео с участием Игоря Сысоева](http://video.yandex.ru/users/ibondarets/view/1/) - отца русского nginx =)

В выступлении Игорь говорит не о мастабировании в привычном для всех понимании (высокая нагрузка), а в плане рекомендаций к написанию конфигурации для nginx, чтобы при росте конфигурации не было проблем с его редактированием.

## Виды location:
1. Описанные простыми строками (статические)

```
location /dir/ {} - обычный префиксный location
location = /dir/ {} - точное совпадение по запросу
location ^~ /dir/ {} - префиксный location, но после него не идёт проверка по location на регулярных выражениях
```

2. Описанные регулярными выражениями

```
location ~ /dir/ {} - с учётом регистра
location ~* /dir/ {} - без учёта регистра
```

3. Именнованные location

```
location @php {}
```

Расположение статических location не играет роли.

Location'ы, написанные с помощью регулярных выражений, выполянются в порядке написания.

По возможности используйте статические location'ы. Например, вместо

```
location ~ .(css|js|jpe?g|png)$ {}
```

выносить все статические файлы в определённый каталог

```
location /static/ {}
```

Заворачивание location на регулярном выражении в статический location

```
location ~* ^/i/(.)(.-\.gif)(
  alias /images/$1$1$2
)
```

```
location /i/ {
  location ~* ^/i/(.)(.-\.gif)$ {
    alias /images/$1$1$2
  }
  return 404
}
```

Понимание директив root и alias:

В общем смысле, root - добавляем в запрос путь в качестве префикса, а alias - заменяет location на указанный в директиве alias



```
location /dir/ {
    root /path/to/data;
}
```

```
             /dir/a/image.gif
/path/to/data/dir/a/image.gif
```

```
location /dir/ {
     alias /path/to/data/;
}
```

```
         /dir/a/image.gif
/path/to/data/a/image.gif
```



```
location ~ ^/dir/ {
  root /path/to/$subdomain;
}
```


```
             /dir/a/image.gif
/path/to/shop/dir/a/image.gif
```

```
location ~ ^/dir/.+/(.)(.*)$ {
    alias /path/to/data/$1/$1$2;
}
```

```
         /dir/a/image.gif
/path/to/data/i/image.gif
```

```
location ~ ^/dir/ {
    alias /path/to/data/0.gif
}
```

```
/dir/a/image.gif
/path/to/data/0.gif
```

Обратите внимание на конечных слэш в proxy_pass

```
location /dir/ {
  proxy_pass http://back
}
```

```
/dir/a/image.gif
/dir/a/image.gif
```

```
location /dir/ {
    proxy_pass http://back/
}
```

```
/dir/a/image.gif
    /a/image.gif
```

Большинство директив носит декларативный характер, а это значит нет разницы, где их определять.

```
server {
    location / {}
    location /images/ {}
    
    root /path/;
}
```

Не рекомендуется использовать if. В примере сработает только последний if. Игорь рекомендует использовать if в связке с return.

```
location / {

  if (1) {
    gzip off;
  }

  if (1) {
    keepalive off;
  }
}
```

## Распространённые ошибки:

В этом примере break вообще не нужен, а expires можно вынести в location

```
location ~* \.(gif|jpe?g|png)$ {
  root /data;
  if (-e $request_filename) {
     expires 1y;
     break;
  }
}
```

Break тут не нужен.

```
location ~* \.(gif|jpe?g|png)$ {
   root /data;
   break;
}
```

Такое возникает у переходящих с apache. Тут нужно заменить всё на статические location.

```
location / {
  if ($uri ~ ^/login.php$) { }

  if ($uri ~ ^/image.php$) { }
}
```
