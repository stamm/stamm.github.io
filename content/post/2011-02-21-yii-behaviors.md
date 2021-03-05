---
tags:
- yii
- php
comments: true
date: 2011-02-21T00:00:00Z
title: 'Yii: поведения (behaviors)'
slug: yii-behaviors
aliases: [yii-behaviors]
---

Поведения в yii позволяют применять некоторые методы к уже существующему объекту из другого класса. Для чего могут понадобиться поведения? Рассмотрим "жизненный" пример. Нужно получить какие-то данные по залогиненному пользователю. Можно, конечно, использовать что-то вроде:

```php
User::model()->findByPk(Yii::app()->user->id);
```

А можно использовать поведения и добавить метод в Yii::app()->user protected/components/WebUser.php

```php
class WebUser extends CBehavior
{
  public function getData()
  {
    if ($this->getOwner()->id)
    {
      return User::model()->findByPk($this->getOwner()->id);
    }
    else
    {
      return FALSE;
    }
  }
}
```

Добавляем в конфиг protected/config/main.php

```php
...
'user'=>array(
  'loginUrl' => '/login',
  // enable cookie-based authentication
  'allowAutoLogin'=>true,
  'behaviors' => array(
    'WebUser' => array(
      'class' => 'WebUser',
    )
  )
),
...
```

Теперь можно использовать так:

```php
Yii::app()->user->data->posts;
```
