---
layout: post
title: "Как установить ruby 2.0.0-p0"
date: 2013-02-24 18:56
comments: true
categories:
- ruby
- rails
---


Сегодня [вышел ruby 2.0.0](http://habrahabr.ru/post/170513/) и я думаю [скоро](https://twitter.com/dhh/status/305678189261377536) выйдет [rails 4](http://habrahabr.ru/company/engineyard/blog/170473/).

Если у вас возникли следующие ошибки, то установка простой коммандой rvm install ruby-2.0.0-p0 не получится:

{% codeblock %}
Error running 'env CFLAGS=-O3 -march=corei7 -O2 -pipe ./configure --disable-install-doc --prefix=/Users/stamm/.rvm/rubies/ruby-2.0.0-p0 --with-opt-dir=/usr/local/opt/libyaml:/usr/local/opt/readline:/usr/local/opt/libxml2:/usr/local/opt/libxslt:/usr/local/opt/libksba:/usr/local/opt/openssl:/usr/local/opt/curl-ca-bundle:/usr/local/opt/sqlite --disable-shared', please read /Users/stamm/.rvm/log/ruby-2.0.0-p0/configure.log 
There has been an error while running configure. Halting the installation. 
{% endcodeblock %}

Или ошибка при запуске bundle install:

{% codeblock %}
/Users/stamm/.rvm/rubies/ruby-2.0.0-p0/lib/ruby/2.0.0/net/http.rb:917:in `connect': SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed (OpenSSL::SSL::SSLError) 
{% endcodeblock %}

Чтобы избавиться от этих ошибок, нужно поставить openssl и gcc:

{% codeblock %}
rvm pkg install openssl
brew install gcc
{% endcodeblock %}

И переустановить с нужными флагами:

{% codeblock %}
rvm reinstall ruby-2.0.0-p0 --with-gcc=gcc-4.7 --with-openssl-dir=$rvm_path/usr
{% endcodeblock %}

Ruby 2.0.0 требуется bundler 1.3, который ещё не вышел. Его можно 
поставить:

{% codeblock %}
gem install --pre bundler
{% endcodeblock %}