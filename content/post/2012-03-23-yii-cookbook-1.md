---
tags:
- php
- yii
- phpstorm
date: 2012-03-23T00:00:00Z
title: 'Yii: рецепты №1'
slug: yii-cookbook-1
aliases: [yii-cookbook-1]
---

### Пакетирование js и css-файлов и использование зависимостей между этими пакетами.

Есть замечательный инструмент для рисования графиков на js — [highcharts](http://www.highcharts.com/), но он использует фреймворк jQuery и сам jQuery не подключает. Соответственно, мы создаём наш пакет, где указываем js и css файлы из highcharts и прописываем зависимость от jQuery.

<!--more-->

```
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
```

Теперь вместо

```
Yii::app()->clientScript
->registerPackage('jquery')
->registerScriptFile('/js/highcharts/highcharts.js')
->registerCssFile('/js/highcharts/highcharts.css');
```

Пишем

```
Yii::app()->clientScript
->registerPackage('highcharts');
```


### YII_DEBUG

Эта константа позволяет включать режим дебага и она же доставляет немного неудобства. Локально нужно устанавливать констатну YII_DEBUG в true, но не комитить это изменение нельзя. Т.е. перед комитом нужно выставлять значение в false. Мы же программисты, народ ленивый, поэтому тем меньше пальцедвижений, тем лучше.

* Можно воспользовать [changelist в PhpStorm](/phpstorm-redmine-changelist-workflow)
* Можно не добавлять файл в коммит

Но эти варианты не подходят, когда используется консоль, нельзя будет использовать команду **git add .**

Решение очевидное: использовать директивы [auto_prepend_file](http://www.php.net/manual/en/ini.core.php#ini.auto-prepend-file) При запуске любого php-файла, будет предварительно выполнятся наш файлик с установленной константой.

Теперь пишем в файл с настройками сайта php-fpm **/etc/php5/fpm/pool.d/super-site-on-yii.conf**

```
[php]
php_admin_value[auto_prepend_file] = /var/www/yii_debug.php
```

Создаём файл /var/www/yii_debug.php

```
<?php
// Если включен профайлер xdebug
//define('YII_DEBUG', empty($_GET['XDEBUG_PROFILE']));
define('YII_DEBUG', true);
```

### Автодополнение в PhpStorm

При подключении стороннего компонента или расширении стандартного хотелось бы «научить» IDE подсказывать

```
'components'=>array(
  'user'=>array(
    'class' => 'WebUser',
  ),
  'myext'=>array(
    'class' => 'MyExt',
  ),
)
```

Создаём файлик в любом месте, из которого он не сможет подключится автолоадерем. Например, в protected/autocomplete.php

```
<?php
/**
 * @property WebUser $user
 * @property MyExt $myext
 */
class CApplication {}
```

Теперь по вводу Yii::app()->myext PhpStorm будет посказывать методы из класса MyExt.


Ещё можно заставить PhpStorm подсказывать в файлах представления (views)

Обычно хватает стандартного набора ($this и $form), но в каждой конкретной view может быть свой набор переменных

```
/** @var $this Controller */
/** @var $form CActiveForm */
/** @var $model User */
```

Последний метод можно полу-автоматизировать через шаблоны gii. Это остаётся в качестве самостоятельной работы читателя.
