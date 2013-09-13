---
layout: post
title: "Редирект при вставки сайта через iframe"
date: 2012-02-02 19:17
comments: true
categories: 
- javascript
- iframe
---

Довольно долго бился c запрещением вставки сайта в iframe с указанием белого списка сайтов, которые могу это сделать


{% codeblock lang:js %}
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
{% endcodeblock %}