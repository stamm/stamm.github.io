---
layout: post
title: "Bash completion - расширенная автоподстановка "
date: 2010-08-09 14:01
comments: true
categories: bash 
---

Очень нужная тулза для ленивых админов. Может работать автодополнением для разных консольных программ: aptitude, git, invoke-rc.d, ssh и других.

Список поддерживающих программ находиться в директории /etc/bash_completion.d

По желанию можно самому расширить этот список. Не забудьте прислать ваши труды мейнтейнеру пакета.

{% codeblock %}
aptitude install bash-completion
{% endcodeblock %}


Добавляем в ~/.bashrc

{% codeblock %}
# Use bash-completion, if available
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi
{% endcodeblock %}