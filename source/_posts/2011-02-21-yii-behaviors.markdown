---
layout: post
title: "Yii: поведения (behaviors)"
date: 2011-02-21 16:23
comments: true
categories: 
- yii
- php
---

Поведения в yii позволяют применять некоторые методы к уже существующему объекту из другого класса. Для чего могут понадобиться поведения? Рассмотрим "жизненный" пример. Нужно получить какие-то данные по залогиненному пользователю. Можно, конечно, использовать что-то вроде:

{% codeblock lang:php %}
User::model()->findByPk(Yii::app()->user->id);
{% endcodeblock %}

А можно использовать поведения и добавить метод в Yii::app()->user protected/components/WebUser.php

{% codeblock lang:php %}
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
{% endcodeblock %}

Добавляем в конфиг protected/config/main.php

{% codeblock lang:php %}
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
{% endcodeblock %}

Теперь можно использовать так:

{% codeblock lang:php %}
Yii::app()->user->data->posts;
{% endcodeblock %}