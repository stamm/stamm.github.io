---
layout: post
title: "Установить текстовый редактор по-умолчанию"
date: 2011-03-12 18:32
comments: true
categories: debian
---

Установить mcedit текстовым редактором по-умолчанию в системе:

{% codeblock %}
sudo update-alternatives --set editor /usr/bin/mcedit
{% endcodeblock %}

Выбрать редактор из списка:

{% codeblock %}
sudo update-alternatives --config editor
{% endcodeblock %}


