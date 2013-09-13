---
layout: post
title: "Ускорение скорости работы grep в Mac OS X"
date: 2012-11-28 19:40
comments: true
categories: 
- mac
- grep
---

На монитор попала статья о том, что [grep от gnu быстрее стандартного маковского grep'а в 10 раз](http://jlebar.com/2012/11/28/GNU_grep_is_10x_faster_than_Mac_grep.html)

Решил проверить у себя. На файле, размером в 720 Мб grep стал быстрей в 36 раз! Неплохо.

{% codeblock%}
$ brew install grep
$ time /usr/bin/grep "GET /out" nginx-access_log.2 | wc -l
140858
/usr/bin/grep "GET /out" nginx-access_log.2 26.49s user 0.28s system 97% cpu 27.443 total wc -l 0.03s user 0.02s system 0% cpu 27.443 total

$ tmp time grep "GET /out" nginx-access_log.2 | wc -l
140858
grep "GET /out" nginx-access_log.2 0.58s user 0.15s system 98% cpu 0.748 total wc -l 0.03s user 0.01s system 6% cpu 0.747 total
{% endcodeblock %}