---
layout: post
title: "Обновление gem mysql2 на MacOS X при обновлении MySQL до 5.6"
date: 2013-03-04 19:02
comments: true
categories:
- ruby
- mysql
- mac
---


На MacOS X в homebrew появился MySQL 5.6.10.

Поэтому при обновлении MySQL будет выскакивать ошибка о несоответствии библиотек:

{% codeblock %}
Incorrect MySQL client library version! This gem was compiled for 5.5.28 but the client library is 5.6.10. 
{% endcodeblock %}

Если ставить так, как написано в readme:

{% codeblock %}
gem install mysql2 --with-mysql-config=/usr/local/bin/mysql_config 
{% endcodeblock %}

То возникает ошибка:

{% codeblock %}
ERROR: While executing gem ... (OptionParser::InvalidOption) invalid option: --with-mysql-config 
{% endcodeblock %}

Нужно добавить больше тирешек и кавычек

{% codeblock %}
gem install mysql2 -- '--with-mysql-config=/usr/local/bin/mysql_config' 
{% endcodeblock %}

## UPDATE:

Чтобы bundler всегда использовал данный параметр, выполните команду:

{% codeblock %}
bundle config build.mysql2 --with-mysql-config=/usr/local/bin/mysql_config
{% endcodeblock %}