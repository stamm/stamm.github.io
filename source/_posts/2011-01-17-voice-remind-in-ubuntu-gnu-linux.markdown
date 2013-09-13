---
layout: post
title: "Голосовое напоминание в Ubuntu Gnu/Linux"
date: 2011-01-17 16:20
comments: true
categories: 
- linux
- bash
- ubuntu
---

Сидя за компом забываешь кое-что сделать, например, выключить плиту. В линуксе это можно реализовать так:

{% codeblock %}
echo "нужная комманда" | at 07:00
{% endcodeblock %}

Примеры: Сказать голосом через 10 минут, что нужно выключить плиту:

{% codeblock %}
$ echo "espeak -v ru 'Выключи плиту'" | at `date -d '+10 minute' +%H:%M`
{% endcodeblock %}

Пора выходить:

{% codeblock %}
$ echo "espeak -v ru 'Пока выходить'" | at 20:00
{% endcodeblock %}

Весело получается ;)
