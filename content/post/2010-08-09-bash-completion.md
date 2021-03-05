---
date: "2010-08-09"
slug: "bash-completion"
aliases: ["bash-completion"]
tags: ["bash"]
title: "Bash completion - расширенная автоподстановка"
---

Очень нужная тулза для ленивых админов. Может работать автодополнением для разных консольных программ: aptitude, git, invoke-rc.d, ssh и других.

Список поддерживающих программ находиться в директории /etc/bash_completion.d

По желанию можно самому расширить этот список. Не забудьте прислать ваши труды мейнтейнеру пакета.

```
aptitude install bash-completion
```


Добавляем в ~/.bashrc

```
# Use bash-completion, if available
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi
```
