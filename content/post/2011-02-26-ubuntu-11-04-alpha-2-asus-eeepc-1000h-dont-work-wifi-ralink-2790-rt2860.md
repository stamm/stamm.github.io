---
tags:
- asus
- wi-fi
- ubuntu
date: 2011-02-26T00:00:00Z
slug: ubuntu-11-04-alpha-2-asus-eeepc-1000h-dont-work-wifi-ralink-2790-rt2860
title: "Ubuntu 11.04 alpha 2. Asus EeePC 1000H. Не работает wifi RaLink 2790 (RT2860)"
---

Нашёл как исправить баг с глючащим wifi в моём нетбуке Asus EeePC 1000H. Карточка RaLink 2790 (RT2860). Нетбук подключался к wifi, получал ip-адрес по DHCP, но ничего не работало. Потом разрывалось соединение и заново подключалось с тем же печальным эффектом. Решение подсмотрел тут. Комманда lspci -vv выдала

```
01:00.0 Network controller: RaLink RT2860
Subsystem: RaLink Device 2790
Control: I/O+ Mem+ BusMaster+ SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx-
Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast &gt;TAbort- &lt;TAbort- &lt;MAbort- &gt;SERR- &lt;PERR- INTx-
Latency: 0, Cache Line Size: 32 bytes
Interrupt: pin A routed to IRQ 19
Region 0: Memory at fbef0000 (32-bit, non-prefetchable) [size=64K]
Capabilities: &lt;access denied&gt;
Kernel driver in use: rt2800pci
Kernel modules: rt2860sta, rt2800pci
```

Нужно отключить модуль rt2800pci и использовать модуль rt2860. Добавляем в конец файла /etc/modprobe.d/blacklist.conf:

```
blacklist rt2800pci
```
