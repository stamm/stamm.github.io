---
tags:
- ruby
- mysql
- mac
date: 2013-03-04T00:00:00Z
title: Обновление gem mysql2 на MacOS X при обновлении MySQL до 5.6
slug: macos-update-mysql2-mysql-5-dot-6
aliases: [macos-update-mysql2-mysql-5-dot-6]
---

На MacOS X в homebrew появился MySQL 5.6.10.

Поэтому при обновлении MySQL будет выскакивать ошибка о несоответствии библиотек:


```
Incorrect MySQL client library version! This gem was compiled for 5.5.28 but the client library is 5.6.10. 
```

<!--more-->

Если ставить так, как написано в readme:

```
gem install mysql2 --with-mysql-config=/usr/local/bin/mysql_config 
```

То возникает ошибка:

```
ERROR: While executing gem ... (OptionParser::InvalidOption) invalid option: --with-mysql-config 
```

Нужно добавить больше тирешек и кавычек

```
gem install mysql2 -- '--with-mysql-config=/usr/local/bin/mysql_config' 
```

## UPDATE:

Чтобы bundler всегда использовал данный параметр, выполните команду:

```
bundle config build.mysql2 --with-mysql-config=/usr/local/bin/mysql_config
```
