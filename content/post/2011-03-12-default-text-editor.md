---
tags: [debian]
date: 2011-03-12T00:00:00Z
title: Установить текстовый редактор по-умолчанию
slug: default-text-editor
aliases: [default-text-editor]
---

Установить mcedit текстовым редактором по-умолчанию в системе:

```
sudo update-alternatives --set editor /usr/bin/mcedit
```

Выбрать редактор из списка:

```
sudo update-alternatives --config editor
```


