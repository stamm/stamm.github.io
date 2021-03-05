---
date: "2010-07-28 03:00:00"
slug: "debian-3-setting-iptables-forward-nat-firewall"
aliases: ["debian-3-setting-iptables-forward-nat-firewall"]
tags: [ "debian", "iptables", "firewall", "nat" ]
title: "Debian. Часть 3. Настройка iptables: NAT, фаервол"
---
                                                 Фаервол нам нужен для ограничения подключения из вне, NATа, а также проброса портов. Для удоства написал скрипт на bash. Вставляем в файл /etc/init.d/rc.firewall

```
#!/bin/bash

IPTABLES="/sbin/iptables"

############### Config #######
LNETS="eth1 eth2 wlan0"

DESKTOP="192.168.1.1"
DESKTOP_OPEN_PORT="8010 9000"

DESKTOP2="192.168.2.1"
DESKTOP2_OPEN_PORT="9003"

HOME_MASKS="192.168.1.0/24 192.168.2.0/24 192.168.3.0/24"

PROVIDER="eth0"
PROVIDER_IP="10.0.4.59"
PROVIDER_MASK="10.0.0.0/8"
INET="ppp+"
WHITE_IP="77.77.77.77"

OPEN_PORTS="22,80"
###################
echo 1 > /proc/sys/net/ipv4/conf/default/rp_filter
echo 1 > /proc/sys/net/ipv4/ip_forward
modprobe ip_conntrack
modprobe ip_conntrack_ftp
modprobe nf_nat_pptp
modprobe nf_conntrack_pptp
modprobe nf_conntrack_proto_gre
modprobe nf_nat_proto_gre
modprobe iptable_nat
modprobe ip_nat_ftp
modprobe ipt_LOG

$IPTABLES -P INPUT ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -P FORWARD DROP

$IPTABLES -F
$IPTABLES -X
$IPTABLES -t nat -F PREROUTING
$IPTABLES -t nat -F POSTROUTING

############ DELETE IF ALL WORKING FINE ###### 
#$IPTABLES -A INPUT -j ACCEPT
#####################################

#mtu for vpn magick command, mega debian epic fail
$IPTABLES -o $INET -A FORWARD -p tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 800:1536 -j TCPMSS --clamp-mss-to-pmtu

# DENY SECTIONS
$IPTABLES -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
$IPTABLES -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j DROP

# local interface, allow all
$IPTABLES -A INPUT -i lo -j ACCEPT

# ALLOW PACKETS IF CONNECTION ESTABLISHED
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# access from white ip
$IPTABLES -A INPUT -s $WHITE_IP -j ACCEPT

# access from home net
for i in $HOME_MASKS; do
$IPTABLES -A INPUT -s $i -j ACCEPT
done
# defence for ssh for server
$IPTABLES -A INPUT -p tcp -m state --state NEW --dport 22 -m recent --update --seconds 20 -j DROP 
$IPTABLES -A INPUT -p tcp -m state --state NEW --dport 22 -m recent --set -j ACCEPT

# open ports for server
$IPTABLES -A INPUT -p tcp --syn -m multiport --destination-ports $OPEN_PORTS -j ACCEPT


######### FORWARD ##########
$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
#forward each home eth to provider eth and ppp+
for i in $LNETS; do
  $IPTABLES -A FORWARD -i $INET -o $i -j ACCEPT
  $IPTABLES -A FORWARD -i $i -o $INET -j ACCEPT
  $IPTABLES -A FORWARD -i $i -o $PROVIDER -j ACCEPT
  #forward each home eth to other home eth
  for j in $LNETS; do
    if [ "$i" != "$j" ] ; then
      $IPTABLES -A FORWARD -i $i -o $j -j ACCEPT
      $IPTABLES -A FORWARD -i $j -o $i -j ACCEPT
    fi
  done
done

###########################

######### LOCAL NAT ########
for i in $HOME_MASKS; do
  $IPTABLES -t nat -A POSTROUTING -s $i -d $PROVIDER_MASK -j SNAT --to-source $PROVIDER_IP
done
############################

######### INET NAT #########
for i in $HOME_MASKS; do
  $IPTABLES -t nat -A POSTROUTING -s $i -j SNAT --to-source $WHITE_IP
done 
############################

########## FORWARD PORTS #########
for i in $DESKTOP_OPEN_PORT; do
  $IPTABLES -t nat -A PREROUTING -p tcp --dport $i -j DNAT --to $DESKTOP:$i
  $IPTABLES -A FORWARD -p tcp -d $DESKTOP --dport $i -j ACCEPT
done

for i in $DESKTOP2_OPEN_PORT; do
  $IPTABLES -t nat -A PREROUTING -p tcp --dport $i -j DNAT --to $DESKTOP2:$i
  $IPTABLES -A FORWARD -p tcp -d $DESKTOP2 --dport $i -j ACCEPT
done

# ssh for destop with defence
$IPTABLES -t nat -A PREROUTING -p tcp --dport 12345 -j DNAT --to $DESKTOP:22
$IPTABLES -A FORWARD -p tcp -m state -d $DESKTOP --state NEW --dport 12345 -m recent --update --seconds 20 -j DROP
$IPTABLES -A FORWARD -p tcp -m state -d $DESKTOP --state NEW --dport 12345 -m recent --set -j ACCEPT   

# ping
$IPTABLES -A INPUT -p ICMP --icmp-type 8 -j ACCEPT
# deny other ICMP packets
$IPTABLES -A INPUT -p icmp -j DROP

# other reject
$IPTABLES -A INPUT -j DROP $IPTABLES -A FORWARD -j DROP

```



Делаем скрипт исполняемым:

```
chmod +x /etc/init.d/rc.firewall
```

И прописываем в автозагрузку

```
update-rc.d rc.firewall defaults
```

По сути в нём всё лаконично закоментированно, но iptables – та ещё магия. В скрипте почти все настройки вынесены. Скрипт разрешает форвардинг между всеми интерфейсами, включает NAT, разрешает пинги до сервера. Всё что явно не разрешено, то запрещено. Бонусом есть защита ssh от брута, форвардинг ssh с порта 12345 на 22 порт домашнего компьютера, форвардинг портов на внутренние компьютеры (разделяются пробелом) Там найдёте магическую строку с моим негативом. Дебиан почему-то не может поставить MTU для ppp. Всё бы ничего, но некоторые сайты не открываются (nix.ru, mail.ru). Как говорят знакомые админы баг тянется ещё с etch. Отписал баг-репорт, ничего внятного так и не ответили. В Ubuntu 9.10, когда настраивал VPN скриптом, всё с mtu было нормально. Благодарю нашего админа за предоставление конфигов и помощи в настройках Теперь у всех домашних компьютеров есть интернет и настроен фаервол. Следующие статьи будут о полезных программах, настройке веб-сервера.

[← Часть 2](/post/debian-2-setting-network-dhcp-bind9-vpn) | [Часть 4 →](/post/debian-4-configure-web-server-nginx-apache-mysql-postgresql)
