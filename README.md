# hadoop-setup
Набор инструкций по настройке компонент Hadoop кластера

- [hadoop-setup](#hadoop-setup)
  - [Требования](#требования)
  - [Установка Hadoop](#установка-hadoop)
    - [SSH](#ssh)
    - [JAVA](#java)
    - [Создание пользователя](#создание-пользователя)
    - [Скачивание дистрибутива Hadoop](#скачивание-дистрибутива-hadoop)
    - [Заполнение хостов](#заполнение-хостов)
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

### Создание пользователя

Для дальнейшего удобства предлагается создать пользователя с именем `hadoop`.

Для каждого из потенциальных узлов кластера:
1. Подключитесь к узлу по ssh.
2. Создайте пользователя `hadoop` с надежным паролем.
3. Сгенерируйте ssh ключ для пользователя `hadoop`.

Все перечисленные шаги оформлены в виде скрипта [create-user.sh](./scripts/create-user.sh), поэтому остаётся выполнить:

```bash
bash ./scripts/create-user.sh
```

__Важно:__ для всех последующих действий необходимо использовать пользователя `hadoop`.

### Скачивание дистрибутива Hadoop

Выберите желаемую версию Hadoop по [ссылке](https://dlcdn.apache.org/hadoop/common/) (__важно:__ учитывайте совместимость с установленной версией Java). Для примера рассмотрим версию 3.4.0, которой соответствует путь `https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz`, команда для скачивания:

```bash
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
```

Далее необходимо распаковать скачанный архив с помощью комманды:

```bash
tar -xvzf hadoop-3.4.0.tar.gz
```

### Заполнение хостов

Создайте файл `hostnames.txt` с описанием всех узлов кластера вида:

```txt
ip1 hostname1
ip2 hostname2
ip3 hostname3
```

На каждом узле запустите скрипт [update-hosts.sh](./scripts/update-hosts.sh), который заполнит `/etc/hosts/:

```bash
bash ./scripts/update-hosts.sh hostnames.txt
```

## Настройка YARN

