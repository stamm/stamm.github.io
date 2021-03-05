---
tags:
- php
- yii
date: 2011-10-15T00:00:00Z
title: 'Yii: CGridView и запрос с group by и having by'
slug: yii-cgridview-query-with-group-by-and-having-by
aliases: [yii-cgridview-query-with-group-by-and-having-by]
---

Задача такая: вывести данные через компонент CGridView в YII, сгруппированные по определённому полю, а также применение условий по агрегированным данным.

Возьмём простую таблицу:

```
date | clicks
```

Нам нужно получить сгруппированные данные по каждому часу.

По сути нужно применить следующий запрос

```
SELECT *
FROM table
GROUP BY LEFT(date, 13);
```

Возникают следующие трудности в реализации через Yii:

* Yii не может посчитать общее количество, а соответственно будет неправильно создавать пагинатор. Yii просто обнуляет поля group by и having при подсчёте общего количества. Да ещё count(*) тут не сработает, нужно просто. посчитать количество строк, которое вернул запрос с группировкой
* Также нам не подходит использование where, чтобы искать по группированным данным. Тут нужно использовать having by.
* Сортировка. Yii автоматически подставляет поле без агрегирующей функции. А если использовать отношения, то ещё и подставит алиас главной таблицы (t.clicks).

Соответственно, мы руками высчитываем общее количество и устанавливаем найденное значение в атрибут totalItemCount компонента CActiveDataProvider

```
public function search()
{
  $criteria=new CDbCriteria;

  $criteria->compare('date',$this->date,true);

  if ($this->clicks)
  {
    // Скопипастил из исходников yii
    if(preg_match('/^(?:\s*(<>|<=|>=|<|>|=))(.*)$/', $this->clicks, $matches))
    {
      $clicks=$matches[2];
      $op=$matches[1];
    }
    else
    {
      $clicks = $this->clicks;
      $op='=';
    }
    // Проставляем having by
    $criteria->having = 'SUM(clicks) ' . $op . ' ' . Yii::app()->db->quoteValue($clicks);
  }
  // Выбираем дату без минут и секунд И сумму кликов за определённый час
  $criteria->select = 'LEFT(date, 13) AS date, SUM(clicks) AS clicks';
  // Применяем группировку по часам
  $criteria->group = 'LEFT(date, 13)';

  // Клонируем объект критерии, чтобы посчитать общее количество записей
  $countCriteria = clone $criteria;
  $countCriteria->select = '1';
  $sum = count(static::model()->findAll($countCriteria));


  $pages=new CPagination($sum);
  $pages->pageSize=50;
  $pages->applyLimit($criteria);

  return new CActiveDataProvider(get_class($this), array(
    'totalItemCount' => $sum,
    'criteria'=>$criteria,
    'pagination'=>$pages,
    'sort' => array(
      'attributes' => array(
        // Тут устанавливаем свою сортировку по нужному полю
        'clicks' => array(
          'asc' => 'SUM(clicks) ASC',
          'desc' => 'SUM(clicks) DESC',
        )
      ),
      'defaultOrder' => 'date DESC',
    ),
   ));
}
```
