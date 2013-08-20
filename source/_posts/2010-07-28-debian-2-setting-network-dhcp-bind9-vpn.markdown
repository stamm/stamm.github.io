---
layout: post
title: "Debian. Часть 2. Настройка сети: dhcp, bind9, vpn, wifi-точка на карте dlink dwa-520"
date: 2010-07-28 00:50
comments: true
categories: 
- dhcp
- bind
- network
- debian
---
После установки, сперва настроим локальную сеть провайдера и vpn для интернета. Напоминаю схема сети:

![Схема сети](/images/debian-1-install/schema.png)

Локальная сеть провайдера будет на интерфейсе eth0. Внутренняя сеть на интерфейсах eth1 и eth2.

Сами настройки сети находятся в файле: /etc/network/interfaces

Настройки сети провайдера: ip: 10.0.4.59, маска: 255.255.255.0, шлюз: 10.0.4.254, dns: 10.0.0.1 и 10.0.0.10

В домашней сети у сервера будут ip 192.168.1.254 и 192.168.2.254

{% codeblock %}
nano /etc/network/interfaces
{% endcodeblock %}

{% codeblock %}
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
   address 10.0.4.59
   netmask 255.255.255.0
   network 10.0.4.0
   broadcast 10.0.4.255
   gateway 10.0.4.254
   dns-nameservers 10.0.0.1 10.0.0.10

auto eth1
iface eth1 inet static
   address 192.168.1.254
   netmask 255.255.255.0
   network 192.168.1.0
   broadcast 192.168.1.255
   gateway 192.168.1.254

auto eth2
iface eth2 inet static
   address 192.168.2.254
   netmask 255.255.255.0
   network 192.168.2.0
   broadcast 192.168.2.255
   gateway 192.168.2.254

auto wlan0
iface wlan0 inet static
   address 192.168.3.254
   netmask 255.255.255.0
   gateway 192.168.3.254
{% endcodeblock %}

Перезагружаем сеть

{% codeblock %}
invoke-rc.d networking restart
{% endcodeblock %}

По команде ifconfig должно быть примерно следующее:

{% codeblock %}
eth0 Link encap:Ethernet  HWaddr 00:22:00:e2:0b:2f
inet addr:10.0.4.59  Bcast:10.0.4.255  Mask:255.255.255.0
inet6 addr: fe80::222:b0ff:fee2:b2f/64 Scope:Link
UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
RX packets:34344719 errors:0 dropped:0 overruns:0 frame:0
TX packets:28907703 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:1000
RX bytes:1153177468 (1.0 GiB)  TX bytes:3724435420 (3.4 GiB)
Interrupt:16 Base address:0xc400

eth1 Link encap:Ethernet  HWaddr 00:e0:0c:c0:c2:49
inet addr:192.168.1.254  Bcast:192.168.1.255  Mask:255.255.255.0
inet6 addr: fe80::2e0:4cff:fec0:c249/64 Scope:Link
UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
RX packets:333947 errors:0 dropped:0 overruns:0 frame:0
TX packets:397715 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:1000
RX bytes:35492580 (33.8 MiB)  TX bytes:466529275 (444.9 MiB)
Interrupt:22

eth2 Link encap:Ethernet  HWaddr 00:15:09:3c:d3:8f
inet addr:192.168.2.254  Bcast:192.168.2.255  Mask:255.255.255.0
inet6 addr: fe80::215:e9ff:fe3c:d38f/64 Scope:Link
UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
RX packets:21667974 errors:0 dropped:0 overruns:0 frame:0
TX packets:29063568 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:1000
RX bytes:902706969 (860.8 MiB)  TX bytes:90195099 (86.0 MiB)
Interrupt:17 Base address:0xc000

lo Link encap:Local Loopback
inet addr:127.0.0.1  Mask:255.0.0.0
inet6 addr: ::1/128 Scope:Host
UP LOOPBACK RUNNING  MTU:16436  Metric:1
RX packets:598219 errors:0 dropped:0 overruns:0 frame:0
TX packets:598219 errors:0 dropped:0 overruns:0 carrier:0
collisions:0 txqueuelen:0
RX bytes:117103916 (111.6 MiB)  TX bytes:117103916 (111.6 MiB)
{% endcodeblock %}

Втыкаем патч корд в сервер в сетевую карту eth1, а другой конец в главный десктоп. Пока что настройте на десктопе вручную сеть: ip: 192.168.1.1, маска: 255.255.255.0, шлюз 192.168.1.254.

Не всегда известно у сетевой карты интерфейс. Попробуйте с компьютера попинговать 192.168.1.254, если не пингуется, вставляйте в другую сетевуху до того момента, когда пинги появятся. Для удобства можно измененить названия интерфейсов (eth0, eth1, eth2 и т.д.) для сетевых карт. Для этого поправьте файл /etc/udev/rules.d/70-persistent-net.rules

Ставим пакеты ssh-server для удалённого управления сервером и pptp-linux для интернета. Во время установки не вынимайте CD диск с установщиком – на нём находятся эти пакеты.

{% codeblock %}
aptitude install openssh-server pptp-linux
{% endcodeblock %}

Теперь можно зайти на сервер по ssh с десктопа. На компьютере у меня Ubuntu 10.04, поэтому я захожу на сервер командой:

{% codeblock %}
ssh root@192.168.1.254
{% endcodeblock %}

Принимаем rsa ключ и вводим пароль. Всё, мы на сервере.

Создаём настройки для vpn:
{% codeblock %}
nano /etc/ppp/peers/tvoynet
{% endcodeblock %}

Настройки для vpn-соединения такие: сервер: vpn.tvoynet.ru, шифрование 128 бит

{% codeblock %}
pty "pptp vpn.tvoynet.ru --nolaunchpppd --nobuffer --loglevel 0"
mtu 1492
mru 1492
connect /bin/true
name ЛОГИН
remotename PPTP
require-mppe-128

#Авто-переподнятие vpn
persist
#Количество попыток для переподнятия
maxfail 0
#Время между попытками переподнятия
holdoff 20
lcp-echo-interval 10
lcp-echo-failure 4
defaultroute
replacedefaultroute

lock
noauth
nodeflate
nobsdcomp
persist
{% endcodeblock %}

В конфигурации указано следующее: если через 40 секунд (4 раза по 10 секунд) не будет доступен интернет, то будет переподниматься vpn-соединение с промежутками 20 секунд до тех пор, пока соединение не подниметься. Записываем пароль в файл /etc/ppp/chap-secrets:

{% codeblock %}
ЛОГИН PPTP ПАРОЛЬ
{% endcodeblock %}

Интернет подключается по команде

{% codeblock %}
pon tvoynet
{% endcodeblock %}

Отключается:

{% codeblock %}
poff tvoynet
{% endcodeblock %}

Добавляем маршруты для локальных ресурсов (и на всякий случай убираем дефолтные маршруты в домашних подсетях) и подключение к интернету при загрузке. В файл /etc/rc.local вставляем до строки exit 0

{% codeblock %}
route del default dev eth1
route del default dev eth2
route add -net 10.0.0.0 netmask 255.0.0.0 gw 10.0.4.254 eth0
pon tvoynet
{% endcodeblock %}

Перезагружаем сервер для проверки: shutdown -r now. Должен появиться интерфейс ppp0. Как обычно проверяем наличие интернета пингом до ya.ru

Интернет есть, теперь обновляемся.

Запускаем aptitude. Нажимаем U (это эквивалентно aptitude update) для обновления списка пакетов. Если будут обновления, полявиться раздел: Upgradable Packages (n). Выбираем этот раздел и нажимаем +(плюс). Далее нажимаем g, выведуться все пакеты для обновления, удаления, установки. Можно отменить обновление какого-либо пакета, выбрав его и нажав :(двоеточие). И снова нажимаем g для обновления.

Нужно установить сервер dhcp для раздачи автоматических настроек для домашних компьютеров, а также DNS-сервер bind9.

В aptitude нажимаем .(точка в английской раскладке, левее правого шифта) – это вызовет поиск. Вводим dhcp3 и нажимаем n до тех пор, пока не найдём пакет dhcp3-server, нажимаем +(плюс). Далее опять вызываем поиск, вводим ^bind9$ (^ – означает начало строки, $ – конец строки), т.е. мы ищем по полному совпадению, ставим и его.

Настраиваем DHCP.

Файл /etc/dhcp3/dhcpd.conf

{% codeblock %}
ddns-update-style none;
default-lease-time 31536000;
max-lease-time 31536000;
authoritative;
log-facility local7;

subnet 192.168.1.0 netmask 255.255.255.0 {
   option domain-name "";
   option domain-name-servers 192.168.1.254;
   option routers 192.168.1.254;
   range 192.168.1.50 192.168.1.150;
}

subnet 192.168.2.0 netmask 255.255.255.0 {
   option domain-name "";
   option domain-name-servers 192.168.2.254;
   option routers 192.168.2.254;
   range 192.168.2.50 192.168.2.150;
}

subnet 192.168.3.0 netmask 255.255.255.0 {
   option domain-name "";
   option domain-name-servers 192.168.3.254;
   option routers 192.168.3.254;
   range 192.168.3.50 192.168.3.150;
}

host stamm-desktop {
   hardware ethernet 00:1a:1d:9f:46:91;
   fixed-address 192.168.1.1;
}

{% endcodeblock %}

Последний абзац означает привязку ip адреса 192.168.1.1 к mac-адресу 00:1a:1d:9f:46:91 для хоста stamm-desktop. Аналогично добавляем для других домашних компьютеров. Чтобы узнать mac адрес других компьютеров в сети, наберите arp.

Меняем файл /etc/default/dhcp3-server для установки прослушивающих интерфейсов для DHCP сервера

{% codeblock %}
INTERFACES="eth1 eth2 wlan0"
{% endcodeblock %}

Рестартуем dhcp сервер:

{% codeblock %}
invoke-rc.d dhcp3-server restart
{% endcodeblock %}

Теперь очередь за bind9 /etc/bind/named.conf.options

{% codeblock %}
options {
   directory "/var/cache/bind";

   forwarders {
       10.0.0.1;
       10.0.0.10;
   };

   auth-nxdomain no;    # conform to RFC1035
   listen-on-v6 { none; };
};
{% endcodeblock %}

Этим мы просто форвардим запросы на другие dns-сервера. В данном случае 10.0.0.1 и 10.0.0.10

Рестартуем bind9:

{% codeblock %}
invoke-rc.d bind9 restart
{% endcodeblock %}

Теперь убираем ручные настройки на компьютере, должен присвоиться адрес 192.168.1.1. Теперь можно подключить второй компьютер.

Есть несколько инструкций по настройке wi-fi карты dlink DWA-520, например, Ubuntu 9.04 По команде

{% codeblock %}
lspci -v
{% endcodeblock %}

Выдаёт информацию по карте:

{% codeblock %}
01:06.0 Ethernet controller: Atheros Communications Inc. Atheros AR5001X+ Wireless Network Adapter (rev 01)
Subsystem: D-Link System Inc Device 3a73
Flags: bus master, medium devsel, latency 168, IRQ 16
Memory at e4000000 (32-bit, non-prefetchable) [size=64K]
Capabilities: [44] Power Management version 2
Kernel driver in use: ath5k
{% endcodeblock %}

Устанавливаем hostapd

{% codeblock %}
aptitude install hostapd
{% endcodeblock %}

Редактируем файл /etc/hostapd/hostapd.conf

{% codeblock %}
interface=wlan0
driver=nl80211
#Названии точки доступа
ssid=Server1
hw_mode=g
channel=2

macaddr_acl=0

auth_algs=1
ignore_broadcast_ssid=0

wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=SuperParol
wpa_pairwise=TKIP
rsn_pairwise=TKIP
{% endcodeblock %}

Редактируем файл /etc/default/hostapd

{% codeblock %}
RUN_DAEMON="yes"
DAEMON_CONF="/etc/hostapd/hostapd.conf"
{% endcodeblock %}

Пока без NAT компьютеры не могут выходить в интернет. Читайте в следующей статье. Учтите, ваш сервер доступен из-вне. На него можно законектиься по ssh через интернет – будьте осторожны. Нужно настроить фаервол. В следующей статье мы как раз этим и займёмся.

[← Часть 1](/debian-1-install) | [Часть 3 →](/debian-3-setting-iptables-forward-nat-firewall) 
