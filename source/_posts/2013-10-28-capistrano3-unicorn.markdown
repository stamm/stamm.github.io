---
layout: post
title: "Управление unicorn в capistrano 3"
date: 2013-10-28 17:54
comments: true
categories:
- unicorn
- capistrano
- ruby
---

Вышла новая версия [capistrano](http://www.capistranorb.com/) под номером 3.

Главные изменения:

* Под капотом теперь [SSHKit](https://github.com/leehambley/sshkit/), и можно использовать разные фишки [dsl](https://github.com/leehambley/sshkit/blob/master/EXAMPLES.md).
В частности появился метод test, которым можно проверить возврат и выполнить в зависимости от этого разные комманды.
Что позволило избавится от выполнения такого: "[ -f ] && unicorn; true"
* Модульность: bundler, rbenv, rvm, maintenance. Даже рельсовые assets и migration развели, можно подключать по отдельности. Идут по пути рельс: подключаешь только то, что тебе нужно.
* Теперь поддержка multistage из коробки
* Новые опции linked_files и linked_dirs
* Сломали --dry-run. К справедливости, это [баг](https://github.com/leehambley/sshkit/issues/39) SSHKit, но неприятненько


Собственно переписанные правила для unicorn'а:

Capfile:

```ruby
require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/bundler'
Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }
```

deploy.rb:

```ruby
namespace :deploy do

  desc 'Restart application'
  task :restart do
    invoke 'deploy:unicorn:restart'
  end
end

namespace :unicorn do
  pid_path = "#{release_path}/tmp/pids"
  unicorn_pid = "#{pid_path}/unicorn.pid"

  def run_unicorn
    execute "#{fetch(:bundle_binstubs)}/unicorn", "-c #{release_path}/config/unicorn.rb -D -E #{fetch(:stage)}"
  end

  desc 'Start unicorn'
  task :start do
    on roles(:app) do
      run_unicorn
    end
  end

  desc 'Stop unicorn'
  task :stop do
    on roles(:app) do
      if test "[ -f #{unicorn_pid} ]"
        execute :kill, "-QUIT `cat #{unicorn_pid}`"
        #execute :rm, unicorn_pid
      end
    end
  end

  task :force_stop do


  desc 'Restart unicorn'
  task :restart do
    on roles(:app) do
      if test "[ -f #{unicorn_pid} ]"
        execute :kill, "-USR2 `cat #{unicorn_pid}`"
      else
        run_unicorn
      end
    end
  end
end
```