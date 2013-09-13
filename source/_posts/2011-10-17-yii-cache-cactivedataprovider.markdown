---
layout: post
title: "Yii: используем кэш в CActiveDataProvider"
date: 2011-10-17 18:48
comments: true
categories: 
- yii
- php
---


Репост моей заметки из wiki: http://www.yiiframework.com/wiki/233/using-cache-in-cactivedataprovider/.

Первый параметр в конструкторе [CActiveDataProvider](http://www.yiiframework.com/doc/api/1.1/CActiveDataProvider/) может быть строковым значением с названием модели или экземпляр класса модели.

Поэтому можно использовать [CActiveRecord::cache()](http://www.yiiframework.com/doc/api/1.1/CActiveRecord#cache-detail) для кэширования, но нужно установить значение 3 у третьего параметра, потому что мы должны закэшировать 2 запроса: получение количества записей и само получение записей.

Не забудьте использовать зависимости для принудительного протухания кэша.

{% codeblock lang:php %}
{% raw %}
$dependecy = new CDbCacheDependency('SELECT MAX(update_time) FROM {{post}}')
 
CActiveDataProvider(Post::model()->cache($duration, $dependecy, 2), array ( 
    'criteria' => array ( 
        'condition' => 'status = 1',
        'order' => 'DESC create_time',
    ) 
    'pagination' => array ( 
        'pageSize' => 20, 
    ) 
));
{% endraw %}
{% endcodeblock %}