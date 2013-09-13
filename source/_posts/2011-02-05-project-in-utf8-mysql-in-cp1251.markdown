---
layout: post
title: "Проект в utf8, mysql-база в cp1251"
date: 2011-02-05 16:22
comments: true
categories: mysl
---

Бывает так, что исходники проекта в utf8, а данные в базе хранятся в cp1251. Чтобы MySQL сам занимался переводом в другую кодировку, но после коннекта выполнить команды:

{% codeblock %}
$db->query('SET NAMES cp1251');
$db->query('SET CHARACTER SET utf8');
{% endcodeblock %}