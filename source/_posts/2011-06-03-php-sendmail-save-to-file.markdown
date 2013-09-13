---
layout: post
title: "Сохраняем письма, отправленные из php, в файлы"
date: 2011-06-03 18:42
comments: true
categories: php
---

При разработке нужно как-то складировать письма, отправляемые из php через функцию mail. Был написан такой скрипт:

{% codeblock lang:php %}
#!/usr/bin/env php
<?php
define('SENDMAIL_DIR', '/tmp/mail/');
if ( ! file_exists(SENDMAIL_DIR))
{
  mkdir(SENDMAIL_DIR, 0777, true);
}

function generateFileName($i = 1)
{
  $fileName = SENDMAIL_DIR . date('Y-m-d_H-i-s_') . $i . '.eml';
  return file_exists($fileName) ? generateFileName(++$i) : $fileName;
}

$mail = fopen('php://stdin', 'r') or die();
$file = fopen(generateFileName(), 'w');

while ( ! feof($mail))
{
  fwrite($file, fgets($mail));
}

fclose($mail);
fclose($file);
{% endcodeblock %}

Даём ему право на исполнение для пользователя веб-сервера (обычно www-data).

Теперь создаём файл конфига для php в debian **/etc/php5/conf.d/sendmail-local.conf** со следующим содержимым:

{% codeblock lang:ini %}
[mail function]
sendmail_path = "/path/to/script/sendmail"
{% endcodeblock %}