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

На каждом узле запустите скрипт [update-hosts.sh](./scripts/update-hosts.sh), который заполнит `/etc/hosts/`:

```bash
bash ./scripts/update-hosts.sh hostnames.txt
```

### Добавление переменных окружения

На NameNode и DataNodes необходимо установить переменные окружения HADOOP, JAVA и PATH. Сделать это можно двумя способами:
1) (ручной) На NameNode открыть файл `~/.profile` с помощью консольного текстового редактора (например, Vim или Nano):
   ```bash
   nano ~/.profile
   ```
   и вставить туда 3 переменные окружения (путь к Java можно найти через команды `which java` и `readlink -f <which java>`.
   В нашем случае путь - /usr/lib/jvm/java-11-openjdk-amd64/bin/java).
   ```bash
   export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/bin/java
   export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
   ```
   Также необходимо активировать наши переменные с помощью команды:
   ```bash
   source ~/.profile 
   ```
   После копируем файл `~/.profile` на оставшиеся DataNodes с помощью команды:
   ```bash
   scp ~/.profile <your-node-name>:/home/hadoop
   ```
2) (автоматический) Запустить скрипт [setup_env](./scripts/setup_env.sh) на NameNode и DataNodes:
   ```bash
   bash ./scripts/setup_env.sh
   ```
После добавления переменных окружения на NameNode и DataNodes нужно добавить переменную JAVA_HOME в конфигурационный файл `hadoop-env.sh`. Сделать это можно двумя способами:
1) (ручной) Переходим в директорию, в котором находится файл:
   ```bash
   cd hadoop-3.4.0/etc/hadoop
   ```
   и открываем файл с помощью консольного текстового редактора:
   ```bash
   nano hadoop-env.sh
   ```
   В файл добавляем нашу переменную `JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/bin/java`.
   После копируем файл `hadoop-env.sh` на оставшиеся DataNodes с помощью команды:
   ```bash
   scp hadoop-env.sh <your-node-name>:/home/hadoop/hadoop-3.4.0/etc/hadoop
   ```

2) (автоматический) Запустить скрипт [set_java_home](./scripts/set_java_home.sh) на NameNode и DataNodes:
   ```bash
   bash ./scripts/set_java_home.sh
   ```
## Настройка YARN

