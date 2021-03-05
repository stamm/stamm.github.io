---
date: "2011-02-05"
slug: "project-in-utf8-mysql-in-cp1251"
aliases: ["project-in-utf8-mysql-in-cp1251"]
tags: ["mysql"]
title: "Проект в utf8, mysql-база в cp1251"
---

Бывает так, что исходники проекта в utf8, а данные в базе хранятся в cp1251. Чтобы MySQL сам занимался переводом в другую кодировку, но после коннекта выполнить команды:

```mysql
$db->query('SET NAMES cp1251');
$db->query('SET CHARACTER SET utf8');
```
