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
    - [Добавление переменных окружения и настройка файловой системы](#добавление-переменных-окружения-и-настройка-файловой-системы)
    - [Запуск кластера](#запуск-кластера)
    - [Настройка nginx](#настройка-nginx)
  - [Настройка YARN](#настройка-yarn)
    - [Конфигурация YARN и History Server](#конфигурация-yarn-и-history-server)
    - [Настройка nginx для YARN и History Server](#настройка-nginx-для-yarn-и-history-server)

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
2. Создайте пользователя `hadoop` с надежным паролем (`sudo adduser --gecos "" hadoop`).
3. Сгенерируйте ssh ключ для пользователя `hadoop` (`sudo -u hadoop ssh-keygen -t ed25519 -N "" -f /home/hadoop/.ssh/id_rsa`), сохраните его.

Все перечисленные шаги оформлены в виде скрипта [create-user.sh](./scripts/create-user.sh), поэтому остаётся выполнить:

```bash
bash ./scripts/create-user.sh
```

__Важно:__ для всех последующих действий необходимо использовать пользователя `hadoop`.
__Важно:__ для удобства все полученные ssh ключи со всех узлов кластера рекоммендуется положить на все узлы, чтобы они "знали" друг друга, сделать это можно записав эти ключи в файл `/home/hadoop/.ssh/authorized_keys`.

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

Данный скрипт заменит содержимое файлы `/etc/hosts/` на содержимое файла `hostnames.txt`, при необходимости можно сделать то же самое вручную.

### Добавление переменных окружения и настройка файловой системы

Рассмотрим два варианта настройки: автоматический и ручной.

- #### Автоматический

  На NameNode и DataNodes необходимо запустить скрипт [setup_env.sh](./scripts/setup_env.sh), который добавит все необходимые переменные и настроит файловую систему (файлы `core-site.xml`, `hdfs-site.xml` и `workers`):

  ```bash
  bash ./scripts/setup_env.sh
  ```

- #### Ручной

  На NameNode и DataNodes необходимо установить переменные окружения HADOOP, JAVA и PATH.

  1\) На NameNode открыть файл `~/.profile` с помощью консольного текстового редактора (например, Vim или Nano):
    ```bash
    nano ~/.profile
    ```
    и вставить туда 3 переменные окружения (путь к Java можно найти через команды `which java` и `readlink -f <which java>`.
    В нашем случае путь - /usr/lib/jvm/java-11-openjdk-amd64/).
    ```bash
    export HADOOP_HOME=/home/hadoop/hadoop-3.4.0
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
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
  После добавления переменных окружения на NameNode и DataNodes нужно добавить переменную JAVA_HOME в конфигурационный файл `hadoop-env.sh`.

  2\) Переходим в директорию, в котором находится файл:
    ```bash
    cd hadoop-3.4.0/etc/hadoop
    ```
    и открываем файл с помощью консольного текстового редактора:
    ```bash
    nano hadoop-env.sh
    ```
    В файл добавляем нашу переменную `JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/`.
    После копируем файл `hadoop-env.sh` на оставшиеся DataNodes с помощью команды:
    ```bash
    scp hadoop-env.sh <your-node-name>:/home/hadoop/hadoop-3.4.0/etc/hadoop
    ```
  Настраиваем файловую систему.
  
  3\) Находясь в директории `hadoop-3.4.0/etc/hadoop`, с помощью консольного текстового редактора открываем файл `core-site.xml` и добавляем конфиг:
    ```bash
    nano core-site.xml
    ```
    ```bash
    <configuration>
      <property>
        <name>fs.defaultFS</name>
        <value>hdfs://<team-00-nn>:9000</value>
      </property>
    </configuration>
    ```
    
  4\) Открываем файл `hdfs-site.xml` и добавляем конфиг:
    ```bash
    nano hdfs-site.xml
    ```
    ```bash
    <configuration>
      <property>
        <name>dfs.replication</name>
        <value>3</value>
      </property>
    </configuration>
    ```
    
  5\) Открываем файл `workers`, удаляем localhost и добавляем туда адреса наших NameNode и всех DataNodes в формате <team-00-nn>:
    ```bash
    nano workers
    ```
    ```bash
    team-00-nn
    team-00-dn-01
    team-00-dn-02
    ...
    ```
    
  6\) Копируем заполненные файлы `core-site.xml`, `hdfs-site.xml` и `workers` на оставшиеся DataNodes:
    ```bash
    scp core-site.xml <your-node-name>:/home/hadoop/hadoop-3.4.0/etc/hadoop
    scp hdfs-site.xml <your-node-name>:/home/hadoop/hadoop-3.4.0/etc/hadoop
    scp workers <your-node-name>:/home/hadoop/hadoop-3.4.0/etc/hadoop
    ```

### Запуск кластера

Используя пользователя `hadoop` зайдите в директорию с дистрибутивом и выполните форматирование неймноды:

```bash
bin/hdfs namenode -format
```

В случае успешного выполнения команды все готово к запуску кластера, для этого из той же директории выполните:

```bash
sbin/start-dfs.sh
```

Для проверки, что на каждом из кластеров запущено всё, что нужно, можно выполнить команду:

```
jps
```

Для NameNode будет несколько сервисов (name node, secondary name node и data node), для DataNode будет только data node.

### Настройка nginx

Для того, чтобы иметь возможность видеть интерфейсы кластера в публичной сети, можно пробросить их через jump-node, которая в свою очередь может обратиться к любом узлу кластера. Для этого необходимо, скопировать конфиг nginx:

```bash
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/nn
```

Где `nn` - NameNode, для DataNode можно указать другое название.

Далее, заполнить конфиг `/etc/nginx/sites-available/nn` с помощью любого редактора:

```
# Заменить:
listen 80 default_server;
listen [::]:80 default_server;

# На:
listen 9870 default_server;
# listen [::]:80 default_server;
```

А также:

```
# Заменить:
try_files $uri $uri/ =404;

# На:
proxy_pass http://{node-hostname}:9870;
```

Порт 9870 подходит для NameNode, для DataNode необходимо использовать порт 9864, в остальном шаги остаются теми же.

__Важно:__ поскольку DataNode у нас несколько, в секции `listen 9870 default_server;` нужно указывать разные порты.

## Настройка YARN

### Конфигурация YARN и History Server

__Пререквизиты__:

Для нод кластера:
- Развернут `HDFS`

Для пользователя `hadoop` на jump-ноде:
- Настроены глобальные переменные `HADOOP_HOME`, `JAVA_HOME`. Последняя прокинута в `$HADOOP_HOME/etc/hadoop/hadoop-env.sh`
- Актуальные хосты указаны в `/etc/hosts` в формате (`ip`, `name`)
- Доступны права на запись в директорию `$HADOOP_HOME`
- Скачан скрипт `scripts/yarn-setup.sh`

__Порядок действий__:

1. Убедиться, что все пререквизиты выполнены
2. Зайти на jump-ноду в пользователя `hadoop`
3. Запустить скрипт `scripts/yarn-setup.sh`, в процессе необходимо ввести пароль для трансфера данных по SSH (выполняется конфигурация и копируется на все ноды кластера)
4. Перейти на `NameNode` в пользователя `hadoop`
5. Выполнить скрипт `$HADOOP_HOME/sbin/start-yarn.sh`
6. Выполнить команду `mapred --daemon start historyserver`
7. Убедиться, что после команды `jps` стали выводиться: для `NameNode` - (`ResourceManager`, `JobHistoryServer`, `NodeManager`), для `DataNodes` - `NodeManager`

### Настройка nginx для YARN и History Server

__Пререквизиты__:

- В директориях `/etc/nginx/sites-available/` и `/etc/nginx/sites-enabled/` отсутствуют файлы `yarn` и `hserver`
- Скачан скрипт `scripts/nginx-yarn.sh`

__Порядок действий__:

1. Убедиться, что все пререквизиты выполнены
2. Зайти на jump-ноду в основного пользователя с правами sudo
3. Запустить скрипт `scripts/nginx-yarn.sh`, в процессе необходимо ввести хост jump-ноды и пароль для прав sudo (выполняется создание nginx файлов для доступа к `yarn` и `historyserver`)
4. Выполнить команду `sudo systemctl reload nginx` и перезайти на ноду
5. Проверить что доступны: `YARN` по адресу `http://<jump-node-host>:8088`, `JobHistoryServer` - по адресу `http://<jump-node-host>:19888`
