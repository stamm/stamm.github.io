---
tags:
- bacula
- debian
- backup
date: 2011-11-27T00:00:00Z
title: 'Bacula - резервное копирование: быстро, бесплатно, без смс'
slug: bacula-backup
aliases: [bacula-backup]
---

Не секрет, что админы делятся на 2 типа: кто ещё не делает бэкапы и кто их уже делает. Я совсем недавно перешёл на сторону светлых админов, хочу поделиться реально работающими конфигами. Теперь седина пропала и мои волосы вновь мягкие и шелковистые =)

Использовать буду систему под названием [bacula](http://www.bacula.org/). Соответственно всё проверялось и работает под ОС GNU/Debian 6.

В интернете [видел](http://habrahabr.ru/blogs/sysadm/86526/) много [довольно](http://www.ignix.ru/book/freebsd/daemon/bacula) [полных](http://bog.pp.ru/work/bacula.html) мануалов, где описывается конфигурация. Я описывать почти ничего не буду, просто приведу рабочие конфиги и скажу что копировать, чтобы начать бэкапить с ещё одного сервера. Можно считать статью предназначенной для тех, кто не осилил man, ну или хочет съэкономить своё время и получить работающую систему резервирования "побыстрее".

Имеется 2 машины

* home.zagirov.name (1.1.1.1) - сам сервер bacula (bacula director и storage director), mysql + www
* www.zagirov.name (2.2.2.2) - mysql + www

Для mysql будем использовать собственный скрипт, который запускает [xtrabackup](http://www.percona.com/software/percona-xtrabackup/).

Устанавливаем на обоих серверах sudo (чтобы запускать бэкапилку базы от рута через sudo) и file director

```
aptitude install sudo bacula-fd openssh-server
```

А на сервере, который будет хранить все бэкапы (home.zagirov.name - 1.1.1.1) установим ещё bacula director и storage director:

```
aptitude install bacula-director-mysql bacula-sd-mysql bacula-console
```

Выполняем на обоих серверах:

```
usermod -s /bin/bash bacula
```

Выполняем на home.zagirov.name (1.1.1.1)

```
su - bacula
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
ssh-keygen -b 4096 -t rsa -f bacula -N ""
chmod 400 ~/.ssh/*
```

Добавляем правило для пользователя bacula запускать xtrabackup под sudo без запрашивания пароля.

```
echo "bacula ALL=NOPASSWD: /usr/bin/xtrabackup" > /etc/sudoers.d/bacula
```

Создаём файлы для создания бэкапов. Храниться они будут централизовано на сервере бэкапов, а запускаться на удалённых машинах будут через sudo bash -s

**/etc/bacula/scripts/xtrabackup.sh**

```
#!/bin/sh

DIR="/bacula/create/xtrabackup"
if [ -d "$DIR" ]; then
  rm -r $DIR
fi
mkdir -p $DIR

sudo xtrabackup --defaults-file=/etc/mysql/my.cnf --datadir=/var/lib/mysql \
 --target-dir=$DIR --backup
```

**/etc/bacula/scripts/xtrabackup_rm.sh**

```
#!/bin/sh

DIR="/bacula/create/xtrabackup"
rm -r $DIR
```

home.zagirov.name: **/etc/bacula/bacula-dir.conf**

```
Director {
  Name = home.zagirov.name-dir
  DIRport = 9101
  QueryFile = "/etc/bacula/scripts/query.sql"
  WorkingDirectory = "/var/lib/bacula"
  PidDirectory = "/var/run/bacula"
  Maximum Concurrent Jobs = 1
  Password = "password-director"
  Messages = Daemon
  DirAddress = 1.1.1.1
}

Catalog {
  Name = MyCatalog
  dbname = "bacula"; DB Address = ""; dbuser = "bacula"; dbpassword = "password_for_db"
}

Console {
  Name = home.zagirov.name-mon
  Password = "password-console"
  CommandACL = status, .status
}


Messages {
  Name = Daemon
  mailcommand = "/usr/lib/bacula/bsmtp -h localhost -f \"\(Bacula\) \<%r\>\" -s \"Bacula daemon message\" %r"
  mail = root@localhost = all, !skipped            
  console = all, !skipped, !saved
  append = "/var/lib/bacula/log" = all, !skipped
}

Messages {
  Name = Standard
  mailcommand = "/usr/lib/bacula/bsmtp -h localhost -f \"\(Bacula\) \<%r\>\" -s \"Bacula: %t %e of %c %l\" %r"
  operatorcommand = "/usr/lib/bacula/bsmtp -h localhost -f \"\(Bacula\) \<%r\>\" -s \"Bacula: Intervention needed for %j\" %r"
  mail = rustam@zagirov.name = all, !skipped            
  operator = rustam@zagirov.name = mount
  console = all, !skipped, !saved
  append = "/var/lib/bacula/log" = all, !skipped
  catalog = all
}

Storage {
  Name = File
  Address = 1.1.1.1
  SDPort = 9103
  Password = "password-storage"
  Device = FileStorage
  Media Type = File
}

#Расписания
Schedule {
  Name = "WeeklyCycle"
  Run = Full 1st sun at 02:05
  Run = Differential 2nd-5th sun at 02:05
  Run = Incremental mon-sat at 02:05
}

Schedule {
  Name = "WeeklyCycleAfterBackup"
  Run = Full sun-sat at 02:10
}


Pool {
  Name = Default
  Pool Type = Backup
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Retention = 365 days         # one year
}

Pool {
  Name = File
  Pool Type = Backup
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Retention = 365 days         # one year
  Maximum Volume Jobs = 1
  Maximum Volume Bytes = 10G          # Limit Volume size to something reasonable
  Maximum Volumes = 100               # Limit number of Volumes in Pool
}


# Scratch pool definition
Pool {
  Name = Scratch
  Pool Type = Backup
}



@/etc/bacula/client_home.zagirov.name.conf
@/etc/bacula/client_www.zagirov.name.conf
```

home.zagirov.name: **/etc/bacula/client_home.zagirov.name.conf**

```
### backup for home.zagirov.name


Client {
  Name = home.zagirov.name-fd
  Address = 1.1.1.1
  FDPort = 9102
  Catalog = MyCatalog
  Password = "password-fd-home.zagirov.name"
  File Retention = 30 days            # 30 days
  Job Retention = 6 months            # six months
  AutoPrune = yes                     # Prune expired Jobs/Files
}


JobDefs {
  Name = "DefaultJob"
  Type = Backup
  Level = Incremental
  Client = home.zagirov.name-fd
  Schedule = "WeeklyCycle"
  Storage = File
  Messages = Standard
  Pool = File
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

Job {
  Name = "RestoreFiles"
  Type = Restore
  Client=home.zagirov.name-fd
  FileSet="home.zagirov.name-www"
  Storage = File
  Pool = Default
  Messages = Standard
  Where = /bacula/restore/
}


Job {
  Name = "BackupCatalog"
  JobDefs = "DefaultJob"
  Level = Full
  FileSet="Catalog"
  Schedule = "WeeklyCycleAfterBackup"
  RunBeforeJob = "/etc/bacula/scripts/make_catalog_backup.pl MyCatalog"
  RunAfterJob  = "/etc/bacula/scripts/delete_catalog_backup"
  Write Bootstrap = "/var/lib/bacula/%n.bsr"
  Priority = 11
}

FileSet {
  Name = "Catalog"
  Include {
    Options {
      signature = MD5
    }
    File = "/var/lib/bacula/bacula.sql"
  }
}


Job {
  Name = "home.zagirov.name-www"
  JobDefs = "DefaultJob"
  FileSet = "home.zagirov.name-www"
}


FileSet {
  Name = "home.zagirov.name-www"
  Include {
    Options {
      signature = MD5
    }
    File = /var/www
  }
}



Job {
  Name = "home.zagirov.name-MySQL"
  JobDefs = "DefaultJob"
  Level = Full
  FileSet="home.zagirov.name-MySQL"
  Schedule = "WeeklyCycle"
  RunBeforeJob = "/etc/bacula/scripts/xtrabackup.sh"
  RunAfterJob  = "/etc/bacula/scripts/xtrabackup_rm.sh"
  Write Bootstrap = "/var/lib/bacula/%n.bsr"
  Priority = 11                   # run after main backup
}

FileSet {
  Name = "home.zagirov.name-MySQL"
  Include {
    Options {
      signature = MD5
    }
    File = "/bacula/create/xtrabackup"
  }
}
```

home.zagirov.name: **/etc/bacula/client_www.zagirov.name.conf**

```
### backup from www.zagirov.name

Client {
  Name = www.zagirov.name-fd
  Address = 2.2.2.2
  FDPort = 9102
  Catalog = MyCatalog
  Password = "password-fd-www.zagirov.name"
  File Retention = 30 days            # 30 days
  Job Retention = 6 months            # six months
  AutoPrune = yes                     # Prune expired Jobs/Files
}

JobDefs {
  Name = "DefaultJob-www.zagirov.name"
  Type = Backup
  Level = Incremental
  Client = www.zagirov.name-fd
  Schedule = "WeeklyCycle"
  Storage = File
  Messages = Standard
  Pool = File
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

Job {
  Name = "Restore-www.zagirov.name"
  Type = Restore
  Client=www.zagirov.name-fd
  FileSet="www.zagirov.name"
  Storage = File
  Pool = Default
  Messages = Standard
  Where = /bacula/restore/
}



Job {
  Name = "www.zagirov.name-www"
  JobDefs = "DefaultJob-www.zagirov.name"
  FileSet = "www.zagirov.name-www"
}


FileSet {
  Name = "www.zagirov.name-www"
  Include {
    Options {
      signature = MD5
    }
    File = /var/www/www.zagirov.name/www
  }
}



Job {
  Name = "www.zagirov.name-MySQL"
  JobDefs = "DefaultJob-www.zagirov.name"
  Level = Full
  FileSet="www.zagirov.name-MySQL"
  Schedule = "WeeklyCycle"
  RunBeforeJob = "ssh -i /var/lib/bacula/.ssh/bacula bacula-www.zagirov.name 'sudo bash -s' </etc/bacula/scripts/xtrabackup.sh"
  RunAfterJob  = "ssh -i /var/lib/bacula/.ssh/bacula bacula-www.zagirov.name 'sudo bash -s' < /etc/bacula/scripts/xtrabackup_rm.sh"
  Write Bootstrap = "/var/lib/bacula/%n.bsr"
  Priority = 11
}

FileSet {
  Name = "www.zagirov.name-MySQL"
  Include {
    Options {
      signature = MD5
      compression = GZIP
    }
    File = "/bacula/create/xtrabackup"
  }
}
```

home.zagirov.name: **bacula-sd.conf**

```
Storage {
  Name = home.zagirov.name-sd
  SDPort = 9103
  WorkingDirectory = "/var/lib/bacula"
  Pid Directory = "/var/run/bacula"
  Maximum Concurrent Jobs = 20
  SDAddress = 1.1.1.1
}

Director {
  Name = home.zagirov.name-dir
  Password = "password-storage"
}

Director {
  Name = home.zagirov.name-mon
  Password = "password-mon"
  Monitor = yes
}

Device {
  Name = FileStorage
  Media Type = File
  Archive Device = /bacula/
  LabelMedia = yes;                   # lets Bacula label unlabeled media
  Random Access = Yes;
  AutomaticMount = yes;               # when device opened, read it
  RemovableMedia = no;
  AlwaysOpen = no;
}

Messages {
  Name = Standard
  director = home.zagirov.name-dir = all
}
```

home.zagirov.name: **/etc/bacula/bacula-fd.conf**

```
Director {
  Name = home.zagirov.name-dir
  Password = "password-fd-home.zagirov.name"
}

Director {
  Name = home.zagirov.name-mon
  Password = "password-mon-fd-home.zagirov.name"
  Monitor = yes
}


FileDaemon {
  Name = home.zagirov.name-fd
  FDport = 9102
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /var/run/bacula
  Maximum Concurrent Jobs = 20
  FDAddress = 1.1.1.1
}

Messages {
  Name = Standard
  director = home.zagirov.name-dir = all, !skipped, !restored
}
```

home.zagirov.name: **/etc/bacula/bconsole.conf**

```
Director {
  Name = localhost-dir
  DIRport = 9101
  address = 1.1.1.1
  Password = "password-director"
}
```

А на удалённом настраиваем только fd

www.zagirov.name: **/etc/bacula/bacula-fd.conf**

```
Director {
  Name = home.zagirov.name-dir
  Password = "password-fd-www.zagirov.name"
}

Director {
  Name = stamm-server-mon
  Password = "password-mon-fd-www.zagirov.name"
  Monitor = yes
}

FileDaemon {
  Name = www.zagirov-name-fd
  FDport = 9102
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /var/run/bacula
  Maximum Concurrent Jobs = 20
  FDAddress = 109.234.152.187
}

Messages {
  Name = Standard
  director = home.zagirov.name-dir = all, !skipped, !restored
}
```

Внимание!

Не забываем поменять пароли на свои!

Запускаем в консоле bconsole

```
*label
Automatically selected Storage: File
Enter new Volume name: backup
Defined Pools:
     1: Default
     2: File
     3: Scratch
Select the Pool (1-3): 2
Connecting to Storage daemon File at 95.31.29.182:9103 ...
Sending label command for Volume "backup" Slot 0 ...
3000 OK label. VolBytes=210 DVD=0 Volume="backup" Device="FileStorage" (/bacula/)
Catalog record for Volume "backup", Slot 0  successfully created.
Requesting to mount FileStorage ...
3906 File device "FileStorage" (/bacula/) is always mounted.
```

Восстановление происходит тоже через команду bconsole. Например, мы захотели восстановить файлы веб-сайта с www.zagirov.name на home.zagirov.name:

```
*restore
Automatically selected Catalog: MyCatalog
Using Catalog "MyCatalog"

First you select one or more JobIds that contain files
to be restored. You will be presented several methods
of specifying the JobIds. Then you will be allowed to
select which files from those JobIds are to be restored.

To select the JobIds, you have the following choices:
     1: List last 20 Jobs run
     2: List Jobs where a given File is saved
     3: Enter list of comma separated JobIds to select
     4: Enter SQL list command
     5: Select the most recent backup for a client
     6: Select backup for a client before a specified time
     7: Enter a list of files to restore
     8: Enter a list of files to restore before a specified time
     9: Find the JobIds of the most recent backup for a client
    10: Find the JobIds for a backup for a client before a specified time
    11: Enter a list of directories to restore for found JobIds
    12: Select full restore to a specified Job date
    13: Cancel
Select item:  (1-13): 5
Defined Clients:
     1: home.zagirov.name-fd
     2: www.zagirov.name-fd
Select the Client (1-2): 2
The defined FileSet resources are:
     1: www.zagirov.name
     2: www.zagirov.name-MySQL
Select FileSet resource (1-2): 1
+-------+-------+----------+------------+---------------------+------------+
| JobId | Level | JobFiles | JobBytes   | StartTime           | VolumeName |
+-------+-------+----------+------------+---------------------+------------+
|    66 | F     |    3,327 | 32,960,325 | 2011-11-19 03:47:28 | Backup     |
|   138 | D     |        7 |  5,973,688 | 2011-11-27 02:08:41 | Backup     |
+-------+-------+----------+------------+---------------------+------------+
You have selected the following JobIds: 66,138

Building directory tree for JobId(s) 66,138 ...  ++++++++++++++++++++++++++++++++++++++++++++
2,959 files inserted into the tree.

You are now entering file selection mode where you add (mark) and
remove (unmark) files to be restored. No files are initially added, unless
you used the "all" keyword on the command line.
Enter "done" to leave this mode.

cwd is: /
$ add *
3,327 files marked.
$ done
Bootstrap records written to /var/lib/bacula/home.zagirov.name-dir.restore.1.bsr

The job will require the following
   Volume(s)                 Storage(s)                SD Device(s)
===========================================================================
   
    Backup                    File                      FileStorage              

Volumes marked with "*" are online.


3,327 files selected to be restored.

The defined Restore Job resources are:
     1: home.zagirov.name-restore
     2: www.zagirov.name-restore
Select Restore Job (1-2): 1
Run Restore job
JobName:         home.zagirov.name-restore
Bootstrap:       /var/lib/bacula/home.zagirov.name-dir.restore.1.bsr
Where:           /bacula/restore/
Replace:         always
FileSet:         home.zagirov.name-105
Backup Client:   www.zagirov.name-fd
Restore Client:  www.zagirov.name-fd
Storage:         File
When:            2011-11-27 02:56:27
Catalog:         MyCatalog
Priority:        10
Plugin Options:  *None*
OK to run? (yes/mod/no): y
Job queued. JobId=143
You have messages.
```

Для добавления нового сервера необходимо добавить в конфиг bacula director инклуд нового файла, который будет содержать следующие директивы:

* **Client**, в который прописываем имя, ip и пароль
* **JobDefs** - исходный джоб, от которого все будут наследоваться
* **Job** восстановления впринципе не обязательно прописывать, но это удобно, когда нужно восстанавливать прямо на нужный сервер
* **Job** и **FileSet** - собственно сам джоб и список файлов для этого джоба
Думаю, теперь bacula кажется не такой уж и страшной как в начале?

Ссылки:

* http://habrahabr.ru/blogs/sysadm/86526/
* http://bog.pp.ru/work/bacula.html
* http://www.ignix.ru/book/freebsd/daemon/bacula
* http://habrahabr.ru/blogs/sysadm/111555/
