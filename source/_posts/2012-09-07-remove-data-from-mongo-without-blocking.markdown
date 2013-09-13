---
layout: post
title: "Удаление данных из коллекции в Mongodb без блокировки"
date: 2012-09-07 19:35
comments: true
categories: mongodb
---

Задача: удалять устаревшие данные из большой коллекции монги. Можно пойти в лоб и удалять так:



{% codeblock lang:js %}
var time = new Date().getTime() - 2*24*60*60;
db.data.remove({updating_time: {$lte: time}})
{% endcodeblock %}

В этом случае возникнет блокировка, и запросы на чтение будут очень долго выполняется. А система устроена таким образом, что постоянно вставлять и обновлять данные из этой коллекции.

Удаление с указанием лимита в монге не существует, поэтому приходиться писать свои велосипеды.

Скрипт выбирает от 10к до 20к записей и удаляет их по _id (по 3к за раз). Если выборка + удаление длилось больше 10 секунд, то удаляется только 1000 записей. Это сделано на всякий случай, когда идёт активная нагрузка на коллекцию (в моём случае активная вставка по 10к элементов).

Все приведённые значения подобраны импирическим путём под конкретную задачу.

{% codeblock lang:js %}
function microtime() {
  return new Date().getTime() / 1000;
}

/**
 * Удаляет данные из монги частями
 * @param last_time - время последнего запроса
 * @param collection - имя коллекции
 * @param criteria - критерия для удаления
 * @return {Array}
 */
function delete_data(last_time, collection, criteria) {
  var ids = [],
    start_time = microtime(),
    i = 0;
  if (last_time < 10) {
    count = 10000 + Math.floor((Math.random() * (20000-10000)) + 1);
  } else {
    count = 1000;
  }
  db[collection].find(criteria, {_id: 1}).limit(count).forEach(function(u){
    i++;
    ids.push(u._id);
    if (i % 3000 == 0) {
      db[collection].remove({_id: {$in: ids }});
      ids = [];
    }
  });

  if (ids.length) {
    db[collection].remove({_id: {$in: ids }});
  }

  last_time = microtime() - start_time;
  return [i, last_time];
}

function delete(collection, criteria) {
  var i = 0,
    last_count = 1,
    last_time = 1;
  while (last_count && i < 1000) {
    i++;
    result = delete_data(last_time, collection, criteria);
    last_count = result[0];
    last_time = result[1];
    print(last_count + ' ' + last_time);
    if (i % 5 == 0) {
      print("count: " + db[collection].count());
    }
  }
}

var time = new Date().getTime() - 2*24*60*60;
delete('data', {updating_time: {$lte: time});
{% endcodeblock %}

Вызывать так:

{% codeblock lang:js %}
mongo -u "user" -p < mongo_remove.js
{% endcodeblock %}