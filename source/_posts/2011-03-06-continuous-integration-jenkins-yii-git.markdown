---
layout: post
title: "Непрерывная интеграция: jenkins + yii + git"
date: 2011-03-06 18:24
comments: true
categories: 
- jenkins
- php
- yii
- hudson
- git
---

Услышав шумиху про некую систему интеграционного тестирования hudson, который переименовали в jenkins, я захотел узнать что это и как это можно использовать. Для чего собственно он нужен? В кратце: он вытягивает последнюю версию из git/svn-репозитория и выполняет определённые действия (тестирует, выкладывает на другой сервер, делает отчёты). Всё это происходит автоматически: можно задать время, когда будет выполнятся задания. Можно почитать про [пример использования jenkins](http://habrahabr.ru/blogs/testing/108928/).

Задача такая: Выполнение unit тестов для yii с отображением покрытия кода

Все действия проводятся на сервере debian squeeze от root.

### Установка jenkins

{% codeblock %}
echo "deb http://pkg.jenkins-ci.org/debian binary/" > /etc/apt/sources.list.d/jenkins.list
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
aptitude update
aptitude install jenkins
{% endcodeblock %}


По адресу http://serverName:8080/ должен открыться jenkins.

### Установка плагинов

{% codeblock %}
cd /tmp
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
{% endcodeblock %}

Если от jenkins нужно, чтобы выполнял unit-тесты и делал code coverage, то достаточно установить несколько плагинов, но на самом деле их очень много.

{% codeblock %}
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin xunit && \
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin clover && \
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin git
{% endcodeblock %}

Перезапускаем jenkins:

{% codeblock %}
java -jar jenkins-cli.jar -s http://localhost:8080 safe-restart
{% endcodeblock %}


### Настройка проекта

Создаём проект. Открываем Новая задача → Имя: Yii. Выбираем "Создать задачу со свободной конфигурацией" → Сохранить.

Меняем файл [protected/tests/phpunit.xml](https://github.com/stamm/jenkins-yii/raw/master/phpunit.xml)
{% codeblock %}
<phpunit bootstrap="bootstrap.php"
   colors="false"
   convertErrorsToExceptions="true"
   convertNoticesToExceptions="true"
   convertWarningsToExceptions="true"
   stopOnFailure="false">

  <selenium>
    <browser name="Internet Explorer" browser="*iexplore" />
    <browser name="Firefox" browser="*firefox" />
  </selenium>

  <logging>
    <log type="coverage-html" target="../../build/coverage" title="prj"
     charset="UTF-8" yui="true" highlight="true"
     lowUpperBound="35" highLowerBound="70"/>
    <log type="coverage-clover" target="../../build/logs/clover.xml"/>
    <log type="junit" target="../../build/logs/junit.xml" logIncompleteSkipped="false"/>
  </logging>
</phpunit>
{% endcodeblock %}


../../build - должен указывать на папку build в корневой папке репозитория, создавать её не нужно.

Теперь создаём конфиги, скачивая из https://github.com/Stamm/jenkins-yii/:

* [config.xml](https://github.com/stamm/jenkins-yii/raw/master/config.xml)
* [build.xml](https://github.com/stamm/jenkins-yii/raw/master/build.xml)

{% codeblock %}
rm /var/lib/jenkins/jobs/yii/config.xml
sudo -u jenkins wget -O /var/lib/jenkins/jobs/yii/config.xml --no-check-certificate https://github.com/Stamm/jenkins-yii/raw/master/config.xml
sudo -u jenkins mkdir /var/lib/jenkins/jobs/yii/workspace
sudo -u jenkins wget -O /var/lib/jenkins/jobs/yii/workspace/build.xml --no-check-certificate https://github.com/Stamm/jenkins-yii/raw/master/build.xml
{% endcodeblock %}

Чтобы наши конфиги подхватились идём в настройки jenkins и кликаем по ссылке "Пересчитать настройки из файла". В настройках проекта yii указываем git репозиторий до нашего проекта. Можно даже указать локальный путь, но должны быть права для пользователя jenkins. Добавляем [файл теста](https://github.com/stamm/jenkins-yii/raw/master/ExampleTest.xml) в protected/unit/

Теперь запускаем сборку. Вот как примерно это выглядит.

![jenkis board](/images/continuous-integration-jenkins-yii-git/jenkins-board.png)

### Уведомления по email

В конфиге jenkins указываем параметры для подключения к SMTP. Если настроен sendmail или exim, то нужно указать только от кого отсылать письмо. И теперь в настройках проекта yii указываем кому слать письмо об упавших тестах.

### Авто-сборка

Можно настроить, чтобы сборки проводились автоматически. Для этого в настройках проекта yii ставим галку у Собирать периодически и в появившемся тестовом поле указываем время запуска в формате cron. Или сделать hook в git:

{% codeblock %}
#!/bin/sh

echo "Running jenkins"
wget http://serverName:8080/job/yii/build > /dev/null 2>&1
{% endcodeblock %}

P.S. Я показал только малую часть того, что может делать jenkins. Он может создавать документацию по коду, проверять на наличие дублирования в коде, проверять стиль кодирования и многое, многое другое. Примеры более сложных конфигов [config.xml](https://github.com/sebastianbergmann/php-jenkins-template/raw/master/config.xml) и [build.xml](https://github.com/sebastianbergmann/php-object-freezer/raw/master/build.xml)

Используемые ссылки:

* http://www.rustyrobot.org/2011/02/continuous-integration.html
* http://jenkins-php.org/
* http://blog.jepamedia.org/2009/10/28/continuous-integration-for-php-with-hudson/
* http://habrahabr.ru/blogs/testing/108928/