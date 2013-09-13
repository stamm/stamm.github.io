---
layout: post
title: "Yii: рецепты №2"
date: 2012-03-26 19:23
comments: true
categories:
- php
- yii
- sphinx
---

Продолжаю делится интересным о Yii

### Шифрование данных

Иногда требуется зашировать данные с возможностью последующей обратной дешифровкой.

В yii есть отличная обёртка для такого рода операций: [CSecurityManager::encrypt()](http://www.yiiframework.com/doc/api/1.1/CSecurityManager#encrypt-detail) и [CSecurityManager::decrypt()](http://www.yiiframework.com/doc/api/1.1/CSecurityManager#decrypt-detail)

Настраиваем [алгоритм](http://ru.wikipedia.org/wiki/Advanced_Encryption_Standard), [режим](http://ru.wikipedia.org/wiki/%D0%A0%D0%B5%D0%B6%D0%B8%D0%BC_%D1%88%D0%B8%D1%84%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F) и ключ шифрования.

{% codeblock lang:php %}
'components'=>array(
  'securityManager' => array(
    'cryptAlgorithm'=>array('rijndael-256', '', 'ofb', ''),
    'encryptionKey' => 'pnkRVLZC6Oj87H2G8qmsNN',
  ),
{% endcodeblock %}

{% codeblock lang:php %}
$encrypt = Yii::app()->securityManager->encrypt('очень важные данные');
echo Yii::app()->securityManager->decrypt($encrypt);
{% endcodeblock %}

Примечания:

* Чтобы использовать шифрованные данные в виде параметров в get-запросе, нужно использовать функцию base64_encode() и base64_decode()
* Можно использовать разные ключи, передав второй параметр в функции CSecurityManager::encrypt() и CSecurityManager::decrypt()


### Организация конфигураций

В Yii существует 3 уровня конфигураций: веб-приложение, консольное приложение, тесты. Требуется прописывать в этих 3 файлах часть одинаковых конфигураций: пути для импорта, конфигурация базы, правила роутов. Так же нужно убрать настройки из системы контроля версии файлы, которые могут быть разные на разных серверах или компьютерах разработчиков: подключение к базе, разных уровень логирования, кэширование. Нужно оставить только "болванку" конфигураций, которые корректируются в связи с необходимостью.

Схемотично такую систему можно изобразить так:

![yii-config](/images/yii-cookbook-2/yii-config.png)

Все файлы, имеющие custom в имени, убираются из системы контроля версии (в моём случае добавляются в [.gitignore](https://github.com/stamm/yii.blog/blob/master/.gitignore)). Вместо них создаются файлы-примеры для настройки: example.main.custom.php, example.console.custom.php, example.test.custom.php.

Для веб-приложения используются 2 файла: main.php и main.custom.php.

В main.custom.php пишутся индивидуальные настройки: подключение к mysql, сервер кэширования. У разработчика включаются gii, yii-debug-toolbar, добавляются вспомогательные режимы логирования, профилирования.

В main.php пишутся все настройки, которые не будут менятся для конкретного сервера: пути импорта, правила роутинга и т.п. И эти настройки сливаются с настройками с main.custom.php через функцию CMap::mergeArray(). Приоритет имеют настройки из main.custom.php

Примеры файлов [main.php](https://github.com/stamm/yii.blog/blob/master/src/protected/config/main.php), [main.custom.php](https://github.com/Stamm/yii.blog/blob/master/src/protected/config/example.main.custom.php)

Конфигурация консольного приложения работает схоже: сначала сливаются изменения из main.php ( включая main.custom.php) c console.php, а затем накладываются из console.custom.php. Настройки тестов работают аналогично.

Естественно, у этой схемы есть свои минусы:

В консольном приложении не может быть некоторых параметров, а некоторые нужно удалить. Например, нужно удалить параметр defaultController:

{% codeblock lang:php %}
unset($aConfig['defaultController']);
{% endcodeblock %}

Или отключить Yii debug toolbar:

{% codeblock lang:php %}
foreach( $aConfig['components']['log']['routes'] as $k => $v ){
  if( $v['class'] == 'XWebDebugRouter' ){
    unset( $aConfig['components']['log']['routes'][$k] );
  }
}
{% endcodeblock %}

[Пример такой конфигурации](https://github.com/Stamm/yii.blog/tree/master/src/protected/config)


### SphinxSQL

Есть 2 способа работы со sphinx из php: через api (используя библиотеку) и воспользоваться SphinxQL: получение данных через протокол mysql и используя запросы, очень схожие с синтаксисом MySQL-запросов.

Для меня более предпочтителен второй вариант, не нужно таскать с собой библиотеку и все новые фишки будут реализованы в первую очередь в SphinxQL.

Включаем в параметрах sphinx прослушивание через протокол mysql

{% codeblock %}
searchd {
listen = 127.0.0.1:9306:mysql41
}
{% endcodeblock %}

Включаем в настройках yii компонент sphinx

{% codeblock %}
sphinx' => array(
    'class' => 'system.db.CDbConnection',
    'connectionString' => 'mysql:host=127.0.0.1;port=9306',
),
{% endcodeblock %}

Теперь мы можем делать запросы:

{% codeblock %}
$sSql = 'SELECT post_id
    FROM main
    WHERE
        MATCH(' . Yii::app()->sphinx->quoteValue('yii') . ')
        AND iscomment = 0
    ORDER BY @weight
OPTION field_weights=(title=10,content=1)';

$ids = Yii::app()->sphinx
  ->createCommand($sSql)
  ->queryColumn();
{% endcodeblock %}