---
layout: post
title: "Yii: рецепты №1"
date: 2012-03-23 19:19
comments: true
categories:
- php
- yii
- phpstorm
---


### Пакетирование js и css-файлов и использование зависимостей между этими пакетами.

Есть замечательный инструмент для рисования графиков на js — [highcharts](http://www.highcharts.com/), но он использует фреймворк jQuery и сам jQuery не подключает. Соответственно, мы создаём наш пакет, где указываем js и css файлы из highcharts и прописываем зависимость от jQuery.

<!-- more -->

{% codeblock lang:php %}
'clientScript'=>array(
  'packages' => array(
       'highcharts' => array(
            'baseUrl' => '/js/highcharts/',
            'js'=>array(YII_DEBUG ? 'highcharts.src.js' : 'highcharts.js'),
            'css' => array('highcharts.css'),
            'depends'=>array('jquery'),
        ),
    )
)
{% endcodeblock %}

Теперь вместо

{% codeblock lang:php %}
Yii::app()->clientScript
->registerPackage('jquery')
->registerScriptFile('/js/highcharts/highcharts.js')
->registerCssFile('/js/highcharts/highcharts.css');
{% endcodeblock %}

Пишем

{% codeblock lang:php %}
Yii::app()->clientScript
->registerPackage('highcharts');
{% endcodeblock %}


### YII_DEBUG

Эта константа позволяет включать режим дебага и она же доставляет немного неудобства. Локально нужно устанавливать констатну YII_DEBUG в true, но не комитить это изменение нельзя. Т.е. перед комитом нужно выставлять значение в false. Мы же программисты, народ ленивый, поэтому тем меньше пальцедвижений, тем лучше.

* Можно воспользовать [changelist в PhpStorm](/phpstorm-redmine-changelist-workflow)
* Можно не добавлять файл в коммит

Но эти варианты не подходят, когда используется консоль, нельзя будет использовать команду **git add .**

Решение очевидное: использовать директивы [auto_prepend_file](http://www.php.net/manual/en/ini.core.php#ini.auto-prepend-file) При запуске любого php-файла, будет предварительно выполнятся наш файлик с установленной константой.

Теперь пишем в файл с настройками сайта php-fpm **/etc/php5/fpm/pool.d/super-site-on-yii.conf**

{% codeblock lang:php %}
[php]
php_admin_value[auto_prepend_file] = /var/www/yii_debug.php
{% endcodeblock %}

Создаём файл /var/www/yii_debug.php

{% codeblock lang:php %}
<?php
// Если включен профайлер xdebug
//define('YII_DEBUG', empty($_GET['XDEBUG_PROFILE']));
define('YII_DEBUG', true);
{% endcodeblock %}

### Автодополнение в PhpStorm

При подключении стороннего компонента или расширении стандартного хотелось бы «научить» IDE подсказывать

{% codeblock lang:php %}
'components'=>array(
  'user'=>array(
    'class' => 'WebUser',
  ),
  'myext'=>array(
    'class' => 'MyExt',
  ),
)
{% endcodeblock %}

Создаём файлик в любом месте, из которого он не сможет подключится автолоадерем. Например, в protected/autocomplete.php

{% codeblock lang:php %}
<?php
/**
 * @property WebUser $user
 * @property MyExt $myext
 */
class CApplication {}
{% endcodeblock %}

Теперь по вводу Yii::app()->myext PhpStorm будет посказывать методы из класса MyExt.


Ещё можно заставить PhpStorm подсказывать в файлах представления (views)

Обычно хватает стандартного набора ($this и $form), но в каждой конкретной view может быть свой набор переменных

{% codeblock lang:php %}
/** @var $this Controller */
/** @var $form CActiveForm */
/** @var $model User */
{% endcodeblock %}

Последний метод можно полу-автоматизировать через шаблоны gii. Это остаётся в качестве самостоятельной работы читателя.