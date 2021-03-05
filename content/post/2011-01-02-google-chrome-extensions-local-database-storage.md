---
date: "2011-01-02"
slug: "google-chrome-extensions-local-database-storage"
aliases: ["google-chrome-extensions-local-database-storage"]
tags: ["chrome", "chromium", "javascript", "database"]
title: "Расширение для Google Chrome: local database storage"
---

Продолжаем осваивать плагинописание для браузеров на основе chromium и ,соответственно, для google chrome. Текущая тема: научиться использовать local database storage. Local database storage - это база данных, использумая из javascript. Представляет она собой SQLite внутри. Синтаксис привычный для SQL баз. Я буду использовать базу для запоминания всех полученных цитат. Логически все действия можно разделить на 4 операции:

1. Открытие базы и получение коннекта к ней
2. Создание таблицы
3. Запись в таблицу
4. Чтение из таблицы


Открытие базы и получение коннекта

```js
function get_db()
{
  return openDatabase("quotes", "1.0", "A list of quotes.", 2*1024*1024);
}
```

где quotes - название базы данных 1.0 - версия БД (не изменять) A list of quotes - комментарий 210241024 - максимальный размер базы данных в байтах

Создание таблицы

```js
get_db().transaction(function(tx) {
  tx.executeSql("CREATE TABLE quotes (text TEXT, author TEXT, timestamp REAL)");
});
```

Запись в таблицу

```js
get_db().transaction(function(tx) {
  tx.executeSql("INSERT INTO quotes (text, author, timestamp) VALUES (?, ?, ?)", [text, author, new Date().getTime()]);
});
```

Чтение из таблицы

```js
get_db().transaction(function(tx) {
  tx.executeSql("SELECT * FROM quotes ORDER BY rowid DESC LIMIT 3", [], function(tx, result) {
    for(var i = 0; i < result.rows.length; i++) {
      alert(result.rows.item(i)['text']);
    }
  }, null)
});
```

rowid - "скрытое" поле, с типом autoinc

[Исходный код на github](https://github.com/Stamm/chrome.extension.forismatic)

Ссылки по теме:

* http://dev.w3.org/html5/webdatabase/
* http://www.sqlite.org/docs.html
