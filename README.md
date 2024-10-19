# hadoop-setup
Набор инструкций по настройке компонент Hadoop кластера

- [hadoop-setup](#hadoop-setup)
  - [Требования](#требования)
  - [Установка Hadoop](#установка-hadoop)
    - [SSH](#ssh)
    - [JAVA](#java)
  - [Настройка YARN](#настройка-yarn)

## Требования

- Наличие установленного Linux (инструкция будет рассмотрена на примере Ubuntu 24.04.1, но сильных отличий быть не должно).
- Пользователь с root правами.


## Установка Hadoop

### SSH

Необходимо иметь установленные необходимые для SSH соединения пакеты, обычно для этого достаточно выполнить:

```bash
sudo apt install ssh pdsh openssh-server openssh-client  
```

### JAVA

Необходимо установить Java подходящей для Hadoop версией:
- узнать версию можно по [ссылке](https://cwiki.apache.org/confluence/display/HADOOP/Hadoop+Java+Versions);
- проверить установку можно командой `java -version`.

Команда установки зависит от выбранной версии, Java 8 версии можно установить командой:

```bash
sudo apt install openjdk-8-jdk openjdk-8-jre
```

## Настройка YARN

