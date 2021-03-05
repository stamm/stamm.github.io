---
tags:
- yii
- php
- completion
- bash
date: 2011-10-23T00:00:00Z
title: 'Yii: автодополнение в консоли'
slug: yii-console-completion
aliases: [yii-console-completion]
---

Очень не хватало автодополнения комманд при вызове консольных комманд yii, чувствовал какую-то неполноценность yii в bash.

На просторах интернета была найдена статья, позволяющая реализовать автодополнение с помощью родной unix-утилиты bash_completion.

Если у вас проект находиться под управлением git, то просто добавляем сабмодуль:

```
git submodule add git://github.com/Stamm/yii-console-completion protected/extensions/complete/
```

Или создайте файл LCompleteCommand.php в protected/extensions/complete/

Теперь подключаем класс в конфигурационном файле для консольного приложения (обычно это console.php):

```
'commandMap' => array(
    'complete' => array(
        'class' => 'ext.complete.LCompleteCommand',
        //'bashFile' => '/etc/bash_completion.d/yii_applications' //Defaults to </etc/bash_completion.d/yii_applications>. May be changed if needed
    ),
),
```

Пути до директории bash-completion могут различаться в зависимости от системы. Для Debian и Ubuntu можно оставить стандартный путь. В Mac OS X bash-completion был установлен с помощью homebrew, так что путь нужно сменить на /usr/local/etc/bash_completion.d/yii_applications

Теперь выполняем комманду для создания bash-completion файла от root:

```
sudo ./yiic complete install
```

Теперь при создании новой сессии в bash будет работать автодополнение для yiic:

1. Для приложения — набор возможных команд
2. Для команды — набор возможных действий (actions) и именованых параметров действия по умолчанию
3. Для действия — подсказки по ее именованым параметрам

Источник: http://habr-sandbox.livejournal.com/230319.html
