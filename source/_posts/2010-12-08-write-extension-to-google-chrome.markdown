---
layout: post
title: "Пишем расширение под Google Chrome"
date: 2010-12-08 16:02
comments: true
categories: 
- javascript
- chrome
- chromium
---

В связи с последними тенденциями в вебе (в том числе и недавний запуск [webstore](https://chrome.google.com/webstore)), возникла идея попрактиковаться в написании плагина под Google Chrome. Решил написать плагин, который бы показывал цитаты с сайта [Forismatic.com](http://forismatic.com/), после прочтения [статьи о написании аналогичного апплета для gnome](http://habrahabr.ru/blogs/personal/102076/).

[Страница установки плагина](https://chrome.google.com/extensions/detail/aegemfnepncjfdnlphmlpmfaninhgafg).

### Требования:

* показ уведомлений через всплывающее окошко.
* двуязычность: русский и английский, причём язык должен подцепляться автоматически в зависимости от выставленного в браузере. Но при этом оставлять выбор на каком языке получать цитаты.
* настройка интервала обновления

Всем начинающим рекомендую сначала прочитать [отличный мануал от самого google](http://code.google.com/chrome/extensions/getstarted.html). В нём всё подробно описано, также есть примеры. Вообще можно увидеть исходники любого приложения: достаточно зайти в папку ~/.config/chromium/Default/Extensions (используется Chromium на Ubuntu).

Весь исходный код моего расширения [доступен на гитхабе](https://github.com/Stamm/chrome.extension.forismatic).

Получать цитаты будем с помощью [api forismatic.com](http://ru.forismatic.com/api/) в формате json.

Вот такой GET-запрос должен получится:
http://api.forismatic.com/api/1.0/?method=getQuote&format=json&key=123456lang=ru

Меняем lang на выбранный язык, а параметр key произвольно.


Теперь перейдём непосредственно к созданию приложения
Необходимо создать такую структуру:

* **_locales/en/messages.json** #для перевода на английский язык
* **_locales/ru/messages.json** #для перевода на русский язык
* **background.html** #файл, который выполняется при запуске плагина
* **functions.js** #небольшая библиотечка написанных функций
* **icon.png** #В связи с запуском webstore рекомендую использовать иконки по-качественней
* **manifest.json** #файл описания плагина
* **options.html** #html-файл настроек

Сначала создаём файлы переводы.


**_locales/en/messages.json**

{% codeblock %}
{
  "extName": {
    "message": "Forismatic quotes"
  },
  "extDescr": {
    "message": "Show quote from Forismatic.com"
  },
  "language": {
    "message": "Language"
  },
  "refresh": {
    "message": "Time refresh"
  },
  "save": {
    "message": "Save"
  },
  "options": {
    "message": "Options"
  },
  "options_saved": {
    "message": "Options saved"
  },
  "minutes": {
    "message": "in minutes"
  }
}
{% endcodeblock %}


**_locales/ru/messages.json**

{% codeblock %}
{
  "extName": {
    "message": "Forismatic цицаты"
  },
  "extDescr": {
    "message": "Показывает цитаты с сайта Forismatic.com"
  },
  "language": {
    "message": "Язык"
  },
  "refresh": {
    "message": "Время обновления"
  },
  "save": {
    "message": "Сохранить"
  },
  "options": {
    "message": "Опции"
  },
  "options_saved": {
    "message": "Настройки сохранены"
  },
  "minutes": {
    "message": "в минутах"
  }
}
{% endcodeblock %}

Теперь можно описать расширение в манифесте

**manifest.json**

{% codeblock %}
{
  "default_locale":"en",
  "name": "__MSG_extName__",
  "description": "__MSG_extDescr__",
  "version": "0.1.1",
  "background_page": "background.html",
  "options_page": "options.html",
  "permissions": [
    "notifications",
    "http://api.forismatic.com/*"
  ],
  "icons": {
    "128": "icon.png"
  }
}
{% endcodeblock %}

Параметр **default_locale** определяет стандартную локаль.

Параметр name описывает имя расширения. Мы его задаём в зависимости от языка, используя ранее описанную переменную в файлах локализации **extName**, предварительно обернув её: **MSG_extName** Также поступим и с параметром **description**. Кстати, при отображении расширения на https://chrome.google.com/extensions/ или на https://chrome.google.com/webstore будет тоже подставляться значение в зависимости от выбранного языка.

В значении **version** указываем версию плагина (причём при заливке новых версий, она должна быть больше предыдущей, что логично). Chrome будет раз в несколько часов и при загрузке проверять обновление плагина и автоматически обновлять его.

Параметры **background_page** и **options_page** указывают на страницу, выполняющуюся в фоне, и страницу настроек. В параметре permissions передаем массив, в котором описываем, что может делать расширение. Мы включили доступ к уведомлениям (notifications) и доступ к сайту api (http://api.forismatic.com/*).

С параметром **icons** всё понятно.

Библиотека функций для javascript

**functions.js**

{% codeblock %}
//"Главная" функция, которая будет показывать всплывающее окно с цитатой
function main()
{
  req = new XMLHttpRequest();
  req.onload = function () {
    var doc = req.responseText;
    if (doc) {
      //Хак, позволяющий получить json как объект
      var json = eval('(' + doc + ')');
      author = json.quoteAuthor;
      text = json.quoteText;
      link = json.quoteLink;
      //Можно создать запись в логе
      console.log(author + ' ' + text);
      //Показываем цитату
      showNotification(author, text);
    }
  };
  req.open("GET", "http://api.forismatic.com/api/1.0/?method=getQuote&format=json&key=" + Math.random()*1000000 + "&lang=" + localStorage['lang'], true);
  req.send(null);
}
//Хелпер для показа всплывающего окна
function showNotification(title, text)
{
  var notification = webkitNotifications.createNotification(
    '',
    title,
    text
  );
  notification.show();
  //Убираем окно через 15 секунд
  window.setInterval(function() {
    notification.cancel();
  }, 15000);
}
//Глобальная переменная для сохранения setInterval
var interval;
//Функция для запуска, которая через выставленное время в настройках будет запускать функцию main. Также запускается при измении времени обновления
function init() {
  if ( ! localStorage['refresh'])
    return;
  window.clearInterval(interval)
  interval = window.setInterval(function() {
    main();
  }, localStorage['refresh'] * 60000);
  console.log(localStorage['refresh'] * 60000);
}
{% endcodeblock %}

Файл, который выполняется при запуске плагина.


**background.html**

{% codeblock %}
<!DOCTYPE html>
<html>
<head>
<meta charset=utf-8 />
<script src="functions.js"></script>
<script>

//Поставить дефолтные значения при первом запуске
if( ! localStorage['refresh'])
{
  localStorage['refresh'] = 30;
}
if( ! localStorage['lang'])
{
  //Получаем язык, используемый в браузере
  var lang = chrome.i18n.getMessage("@@ui_locale");
  if (lang == 'ru')
    localStorage['lang'] = "ru";
  else
    localStorage['lang'] = "en";
}

//Добавляем listener, для приёма вызова со страницы опций, чтобы обновить время обновления цитат
chrome.extension.onRequest.addListener(
  function(request, sender, sendResponse) {
    //Проверка, что данные пришли со страницы опций этого же плагина и параметр do равен update
    if (sender.tab.url == chrome.extension.getURL(«options.html») && request.do == "update")
   {
     //Показываем цитату
     main();
      init();
      console.log('Update refresh time from options !');
    }
  }
);
//Показываем цитату при запуске
main();

init();
</script>
</head>
</html>
{% endcodeblock %}

Настройки плагина


**options.html**

{% codeblock %}
<!DOCTYPE html>
<html>
<meta charset=utf-8 />
<head><title>Options</title></head>
<script src="functions.js"></script>
<script type="text/javascript">

//Сохраняем опции
function save_options()
{
  localStorage['lang'] = document.getElementById("lang").value;
  localStorage['refresh'] = parseFloat(document.getElementById("refresh").value);

  //Показываем пользователю, что настройки сохранены
  var status = document.getElementById("status");
  status.innerHTML = chrome.i18n.getMessage("options_saved");
  setTimeout(function() {
    status.innerHTML = "";
  }, 1750);

  //Посылаем запрос на background.html
  chrome.extension.sendRequest({do: "update"});
}

//Восстанавливаем значения из localStorage
function restore_options()
{
  //Выставляем язык
  document.getElementById("locale_refresh").innerHTML = chrome.i18n.getMessage("refresh");
  document.getElementById("locale_minutes").innerHTML = chrome.i18n.getMessage("minutes");
  document.getElementById("locale_language").innerHTML = chrome.i18n.getMessage("language");
  document.getElementById("locale_save").value = chrome.i18n.getMessage("save");
  document.title = chrome.i18n.getMessage("options");

  //Выставляем значения
  //Можно поставить:
  //document.getElementById("lang").value = localStorage["lang"] == undefined ? 'en' : localStorage["lang"];
  //Но в background.html уже выставлены значения по-умолчанию
  document.getElementById("lang").value = localStorage["lang"];
  document.getElementById("refresh").value = localStorage["refresh"];
}
</script>
<body onload="restore_options()">
<form action="" onsubmit="save_options();return false;">
<span id="locale_refresh">Time refresh</span>: <input name="refresh" id="refresh" size="1" /> <span id="locale_minutes">in minutes</span> <br />
<span id="locale_language">Language</span>:
  <select name="lang" id="lang">
    <option value="ru">Русский</option>
    <option value="en">English</option>
  </select>
<br />
<input type="submit" value="Save" id="locale_save"/>
</form>
<div id="status"></div>
</body>
</html>
{% endcodeblock %}

Cкрипт, который помогает упаковывать расширение:


**zip.sh**

{% codeblock %}
#!/bin/sh
zip -r chrome-ext-forismatic.zip ./* -x ".git" -x "zip.sh"
{% endcodeblock %}

Теперь можно запустить плагин в браузере: Tools » Расширения » Загрузить распакованное расширение Должно появиться всплывающее окно с цитатой. Можно зайти в настройки, сменить язык. При сохранении, должная появиться цитата на другом языке.

После создания и тестирования необходимо выложить плагин. Заходим на страницу: https://chrome.google.com/extensions/developer/dashboard?hl=ru, загружаем архив с плагином, указываем нужные параметры (скриншоты, разделы) и нажимаем Publish changes и наше приложение уже на странице плагинов и на webstore.

