---
tags:
- javascript
- iframe
date: 2012-02-02T00:00:00Z
title: Редирект при вставки сайта через iframe
slug: redirect-iframe
aliases: [redirect-iframe]
---

Довольно долго бился c запрещением вставки сайта в iframe с указанием белого списка сайтов, которые могу это сделать


```
if (top != self) {
    var white_list = ['yandex.ru', 'google.com'];
    var isFriend = false;
    var hostname = document.referrer.split("/")[2].split(":")[0];
    for (var i=0; i < white_list.length; i++) {
        if (hostname == white_list[i] || hostname == "www." + white_list[i]) {
            isFriend = true;
            break;
        }
    }
    if ( ! isFriend ) {
        window.top.location = window.location.href;
    }
}
```
