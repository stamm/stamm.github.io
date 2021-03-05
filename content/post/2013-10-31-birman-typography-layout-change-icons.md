---
tags:
- mac
date: 2013-10-31T00:00:00Z
title: 'Mac: заменить иконки у типографской раскладки Бирмана'
slug: birman-typography-layout-change-icons
aliases: [birman-typography-layout-change-icons]
---

Использую типографскую раскладку от Ильи Бирмана, но мне не нравятся иконки в виде серпа и молота.

<!--more-->

Я заменил их на нормальные флаги.

На той неделе переустанавливал с нуля Mavericks. Поэтому пришлось вспоминать как делал это в прошлый раз.
Опять искал нужные иконки, путь, где нужно их сохранить.

В итоге написал простенький скрипт, который делает всё за вас:

```
  curl -fsSL https://github.com/stamm/birman_layout_normal_icons/raw/master/change.sh | bash
```

Исходники: https://github.com/stamm/birman_layout_normal_icons
