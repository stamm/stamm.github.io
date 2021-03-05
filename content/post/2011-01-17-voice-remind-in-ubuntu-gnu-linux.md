---
date: "2011-01-17"
slug: "voice-remind-in-ubuntu-gnu-linux"
aliases: ["voice-remind-in-ubuntu-gnu-linux"]
tags: ["linux", "bash", "ubuntu"]
title: "Голосовое напоминание в Ubuntu Gnu/Linux"
---

Сидя за компом забываешь кое-что сделать, например, выключить плиту. В линуксе это можно реализовать так:

```
echo "нужная комманда" | at 07:00
```

Примеры: Сказать голосом через 10 минут, что нужно выключить плиту:

```
$ echo "espeak -v ru 'Выключи плиту'" | at `date -d '+10 minute' +%H:%M`
```

Пора выходить:

```
$ echo "espeak -v ru 'Пока выходить'" | at 20:00
```

Весело получается ;)
