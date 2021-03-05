---
date: "2010-08-20"
slug: "apt-pinning-packages-stable-testing-unstable-experimental"
aliases: ["apt-pinning-packages-stable-testing-unstable-experimental"]
tags: ["debian", "apt", "aptitude"]
title: "Apt: управление приоритетами пакетов из stable, testing, unstable, experimental"
---

Есть несколько "виртуальных" релизов у debian: stable - на текущий момент это 5 версия (lenny), testing - squeeze (когда он будет выпущен, то перейдёт в релиз stable). Unstable и experimental - экспериментальные релизы, не для продакшена!. Пакет проходит путь из experimental => unstable => testing => stable. Иногда бывают ситуации, когда нужно установить пакеты поновее. Можно, конечно, скачать отдельно deb-пакет и установить его, но в этом случае одни минусы: возможно требуются удовлетворения зависимостей и лишаемся обновлений. А можно рулить приоритетами пакетов в зависимости от релиза (stable, testing, unstable, experimental).

Создаём файлы в /etc/apt/sources.list.d

testing.list

```
deb http://ftp.debian.org/debian/ testing main non-free contrib
deb-src http://ftp.debian.org/debian/ testing main non-free contrib
deb http://security.debian.org/ testing/updates main contrib non-free
deb-src http://security.debian.org/ testing/updates main contrib non-free
```

unstable.list

```
deb http://ftp.debian.org/debian/ sid main non-free contrib
deb-src http://ftp.debian.org/debian/ sid main non-free contrib
```

experimental.list

```
deb http://ftp.debian.org/debian/ experimental main non-free contrib
deb-src http://ftp.debian.org/debian/ experimental main non-free contrib
```

Теперь настраиваем приоритеты в файле /etc/apt/preferences:

```
Package: *
Pin: release a=stable
Pin-Priority: 200

Package: *
Pin: release a=testing
Pin-Priority: 201

Package: *
Pin: release a=unstable
Pin-Priority: 199

Package: *
Pin: release a=experimental
Pin-Priority: 198
```

Этот конфиг означает, что пакеты будут искаться в такой последовательности: testing => stable => unstable => experimental. Вместо Package: * можно указать конкретные пакеты, но, к сожалению, нельзя указать маску пакетов.

Установка пакета и попытка решить зависимости из unstable:

```
aptitude -t unstable install <package>
```

Установка пакета и попытка решить зависимости из релиза с наивысшим приоритетом:

```
aptitude install <package>/unstable
```

Ссылки по теме: http://www.debian.org/doc/manuals/apt-howto/ch-apt-get.ru.html
