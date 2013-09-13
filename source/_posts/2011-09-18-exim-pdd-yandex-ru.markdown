---
layout: post
title: "Настройка exim на почту для доменов от Яндекса (pdd.yandex.ru)"
date: 2011-09-18 18:44
comments: true
categories:
- exim
- yandex
- mail
---


Настраиваем отправку почты с нашего сервера через почту для доменов от Яндекса.

Для примера, используем домен zagirov.name.

Запускаем конфигурирование exim'а:

{% codeblock %}
dpkg-reconfigure exim4-config
{% endcodeblock %}

Отвечаем на вопросы:

* mail sent by SMARTHOST; received via SMTP or fetchmail
* Type System Mail Name: пусто
* Type IP Adresses to listen on for incoming SMTP connections: 127.0.0.1 ; ::1
* Other destinations for which mail: пусто
* Machines to relay mail for: пусто
* Type Machine handling outgoing mail for this host (smarthost): smtp.yandex.ru:587
* Hide local mail name in outgoing mail: Нет
* Keep number of DNS-queries minimal (Dial-on-Demand): Нет
* Delivery method for local mail: mbox format in /var/mail/ /exim4/conf.d/rewrite/00_exim4-config_header
* split configuration into small files: Да


Теперь прописываем пароль для ящика в файле **/etc/exim4/passwd.client**:

{% codeblock %}
smtp.yandex.ru:no-reply@zagirov.name:СВОЙ_ПАРОЛЬ
{% endcodeblock %}

Почтовый сервер яндекс ругается, что нужно заполненное поле FROM. Прописываем его в файле **/etc/exim4/conf.d/rewrite/00_exim4-config_header**:

{% codeblock %}
begin rewrite *@* no-reply@zagirov.name Ffr
{% endcodeblock %}