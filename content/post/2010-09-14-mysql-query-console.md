---
date: "2010-09-14"
slug: "mysql-query-console"
aliases: ["mysql-query-console"]
tags: ["bash", "debian", "mysql"]
title: "MySQL запросы через консоль"
---

Обнаружил очень простой способ выполнения MySQL запросов в Debian. Причём без указания логина и пароля. В Debian'е создаётся системный пользователь debian-sys-maint, от которого и будут идти запросы. Например выборка:

```
echo "SELECT * FROM database.table WHERE id > 10" | mysql --defaults-file=/etc/mysql/debian.cnf -Bs
```

Можно мониторить нагрузку:

```
watch 'echo "show full processlist" | mysql --defaults-file=/etc/mysql/debian.cnf -Bs'
```
