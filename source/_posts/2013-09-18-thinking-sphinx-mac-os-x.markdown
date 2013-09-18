---
layout: post
title: "Бага thinking-sphinx в Mac OS X"
date: 2013-09-18 18:33
comments: true
categories:
- sphinx
- ruby
---


Возникла ошибка при использовании thinking-sphinx под Mac OS X. Убил полдня на её решение. Надеюсь этот пост поможет быстрей справиться с этим багом таким же как и я программистам, которые используют методику google driven development.

Эта ошибка воспроизводилась на Mac OS X 10.8.4, thinking-sphinx 3.0.5, и sphinx 2.0.9.

Началось всё с этой ошибки:

{% codeblock %}
undefined method `inject' for nil:NilClass
{% endcodeblock %}

И стектрейсом
{% codeblock %}
(gem) thinking-sphinx-3.0.5/lib/thinking_sphinx/middlewares/inquirer.rb:49:in `call'
(gem) thinking-sphinx-3.0.5/lib/thinking_sphinx/middlewares/inquirer.rb:14:in `block in call'
(gem) thinking-sphinx-3.0.5/lib/thinking_sphinx/middlewares/inquirer.rb:13:in `call'
(gem) thinking-sphinx-3.0.5/lib/thinking_sphinx/middlewares/geographer.rb:11:in `call'
(gem) thinking-sphinx-3.0.5/lib/thinking_sphinx/middlewares/sphinxql.rb:13:in `call'
(gem) thinking-sphinx-3.0.5/lib/thinking_sphinx/middlewares/stale_id_filter.rb:10:in `call'
(gem) middleware-0.1.0/lib/middleware/runner.rb:31:in `call'
(gem) middleware-0.1.0/lib/middleware/builder.rb:102:in `call'
(gem) thinking-sphinx-3.0.5/lib/thinking_sphinx/search.rb:65:in `populate'
{% endcodeblock %}

В логах было только видно, что запрос исполняется.

{% codeblock %}
Sphinx Query (36.6ms)  SELECT * FROM `index` WHERE MATCH('телеФон*')
{% endcodeblock %}

После копаний оказалось, что thinking-sphinx выполняет сразу два запроса: собственно запрос на получение данных из сфинкса и запрос «SHOW META».

Оказалось, что во время второго запроса, сфинкс по неизведанной причине разрывает соединение.

{% codeblock %}
Sphinx Retrying query "SELECT * FROM `index` WHERE MATCH('телеФон*'); SHOW META" after error: Lost connection to MySQL server during query
{% endcodeblock %}


Скачал beta-версию (2.1.1) sphinx'а, причём сайт при загрузке выдал мне сообщение: «Congratulations! It's official, you're a Sphinxter!!» =)

На этой версии ошибок не было.
Скорее всего это из-за mac, думаю, что на линуксе было бы всё нормально. Но проверять этот вариант уже нет времени.

