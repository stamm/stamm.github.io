---
layout: post
title: "MySQL запросы через консоль"
date: 2010-09-14 14:05
comments: true
categories:
- bash
- debian
- mysql
---

Обнаружил очень простой способ выполнения MySQL запросов в Debian. Причём без указания логина и пароля. В Debian'е создаётся системный пользователь debian-sys-maint, от которого и будут идти запросы. Например выборка:

{% codeblock %}
echo "SELECT * FROM database.table WHERE id > 10" | mysql --defaults-file=/etc/mysql/debian.cnf -Bs
{% endcodeblock %}

Можно мониторить нагрузку:

{% codeblock %}
watch 'echo "show full processlist" | mysql --defaults-file=/etc/mysql/debian.cnf -Bs'
{% endcodeblock %}
