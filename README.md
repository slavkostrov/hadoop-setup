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
  - [Настройка Hive](#настройка-hive)
    - [Конфигурация Hive](#конфигурация-hive)
    - [Создание базы данных и таблиц в Hive](#создание-базы-данных-и-таблиц-в-hive)
  - [Настройка Apache Spark](#настройка-apache-spark-под-управлением-yarn-для-чтения-трансформации-и-записи-данных)
      - [Настройка кластера Hadoop и YARN](#1-настройка-кластера-hadoop-и-yarn)
      - [Настройка HDFS](#2-настройка-hdfs)
      - [Установка и настройка Spark](#3-установка-и-настройка-spark)
      - [Запуск сессии Apache Spark под управлением YARN](#4-запуск-сессии-apache-spark-под-управлением-yarn)
      - [Чтение данных из HDFS и трансформации](#5-чтение-данных-из-hdfs-и-трансформации)
  - [Настройка Airflow](#настройка-airflow)



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

## Настройка HIVE

### Конфигурация HIVE

__Пререквизиты__:

Для нод кластера:
- Развернут `HDFS`

Для пользователя `hadoop` на jump-ноде:
- Настроены глобальные переменные `HADOOP_HOME`, `JAVA_HOME`. Последняя прокинута в `$HADOOP_HOME/etc/hadoop/hadoop-env.sh`
- Актуальные хосты указаны в `/etc/hosts` в формате (`ip`, `name`)
- Доступны права на запись в директорию `$HADOOP_HOME`
- Скачан скрипт `scripts/hive-setup.sh`

__Создание директорий на HDFS__:
1. На name node под юзером hadoop последовательно создать директории и выдать права на их чтение и запись:
```bash
hdfs dfs -mkdir /tmp
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse
```

__Настройка postgresql для Hive__:
1. Качаем дистрибутив PostgreSQL, запустив в консоли 
```bash
sudo apt install postgresql postgresql-contrib
```
2. Заходим под юзером postgres 
```bash
sudo -i -u postgres
```
3. Запускаем командную строку, выполнив `psql`
4. Создаем датабазу и юзера для Hive, передавая ему все права и базу во владение:
```sql
CREATE DATABASE metastore;
CREATE USER hive with password 'hive';
GRANT ALL PRIVILEGES ON DATABASE "metastore" to hive;
ALTER DATABASE metastore OWNER TO hive;
```
и выходим из командной строки `\q` и юзера `exit`.
5. На jump node открываем 
```bash
sudo nano /etc/hosts
``` 
и вписываем туда ip и название `127.0.0.1 localhost`.
6. Заходим в конфиг postgresql 
```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```
и после строчки `# IPv4 local connections:` вписываем:
```bash
host    all             all             192.168.1.1/24          scram-sha-256
```
7. Перезапускаем postgresql 
```bash
sudo systemctl restart postgresql
```

__Порядок действий для установки__:

1. Качаем дистрибутив Apache Hive, запустив в консоли 
```bash
wget https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz
```
2. Распаковываем его 
```bash
tar -xzvf apache-hive-4.0.1-bin.tar.gz
```
3. Скрипт `hive-setup.sh` кладем в `apache-hive-4.0.1-bin`, запустив 
```bash
mv hive-setup.sh apache-hive-4.0.1-bin/hive-setup.sh
```
4. Переходим в директорию дистрибутива `cd apache-hive-4.0.1-bin`
5. Запускаем скрипт `hive-setup.sh`
```bash
source hive-setup.sh
```
6. Для того, чтобы воспользоваться Hive, запускаем команду 
```bash
beeline -u jdbc:hive2://{jumpnode_name}:10000
```

### Создание базы данных и таблиц в Hive

__Работа в Hive__: 

0. Предварительно скачаем кусочек данных для загрузки в Hive в home директории:
```bash
git clone https://github.com/slavkostrov/hadoop-setup/tree/master
```
переходим в папку `hadoop-3.4.0/sbin` создадим новую директорию на hdfs и положим туда файлы:
```bash
hdfs dfs -mkdir /user/data
hdfs dfs -copyFromLocal /home/hadoop/hadoop-setup/sample_data/raw_sales.csv /user/data/
```
1. Для работы в Hive нужно запустить клиент `beeline`, который представляет собой консоль для SQL команд:
```bash
beeline -u jdbc:hive2://{jumpnode_name}:10000
```
2. Создадим датабазу и таблицу, выполнив последовательно:
```sql
CREATE DATABASE test;
```
```sql
CREATE TABLE IF NOT EXISTS test.houses_ts (
  datesold timestamp,
  postcode int,
  price int,
  propertyType string,
  bedrooms int
) COMMENT 'house sales' 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
STORED AS textfile
tblproperties("skip.header.line.count"="1");
```
```sql
LOAD DATA INPATH '/user/data/raw_sales.csv' INTO TABLE test.houses_ts;
```
3. Далее полученную таблицу трансформируем в партиционированную:
```sql
CREATE TABLE test.houses_partitioned
PARTITIONED BY (datesold)
AS SELECT * FROM test.houses_ts;
```
## Настройка Apache Spark под управлением YARN для чтения, трансформации и записи данных

### 1. Настройка кластера Hadoop и YARN

#### **1.1 Запустим необходимые процессы на узлах**

##### **На NameNode (team-12-nn):**
1. Запустим HDFS (NameNode, SecondaryNameNode, DataNode):
   ```bash
   $HADOOP_HOME/sbin/start-dfs.sh
   ```
   Убедимся, что все компоненты HDFS запущены:
   ```bash
   jps
   ```
   Необходимо увидеть `NameNode`, `SecondaryNameNode`, `DataNode`.

2. Запустим ResourceManager:
   ```bash
   $HADOOP_HOME/sbin/start-yarn.sh
   ```
   Убедимся, что ResourceManager работает:
   ```bash
   jps
   ```
   Необходимо увидеть `ResourceManager`.

##### **На DataNodes (team-1-dn-0 и team-1-dn-1):**
1. Запустим NodeManager:
   ```bash
   $HADOOP_HOME/sbin/yarn-daemon.sh start nodemanager
   ```
2. Убедимся, что NodeManager работает:
   ```bash
   jps
   ```
   Увидим `NodeManager`.

##### **На Jump Node (team-12-jn):**
- Запустим NodeManager:
   ```bash
   $HADOOP_HOME/sbin/yarn-daemon.sh start nodemanager
   ```

---

#### **1.2 Проверим статус YARN**
1. Выполним команду на NameNode:
   ```bash
   yarn node -list
   ```
   Убедимся, что все узлы отображаются в статусе `RUNNING`.

2. Проверим, что порт ResourceManager (8088) открыт:
   ```bash
   netstat -tuln | grep 8088
   ```

---

### **2. Настройка HDFS**

#### **2.1 Убедимся, что HDFS настроен и запущен**

1. **Проверим конфигурацию файлов Hadoop**:
   - Перейдем в директорию `$HADOOP_HOME/etc/hadoop`:
     ```bash
     cd $HADOOP_HOME/etc/hadoop
     ```
   - Проверим файл `core-site.xml`. Убедимся, что параметр `fs.defaultFS` указывает на правильный URI нашего NameNode (например, `hdfs://team-1-nn:9000`):
     ```xml
     <configuration>
         <property>
             <name>fs.defaultFS</name>
             <value>hdfs://team-1-nn:9000</value>
         </property>
     </configuration>
     ```

2. **Запустим HDFS**:
   - На NameNode выполним команду:
     ```bash
     $HADOOP_HOME/sbin/start-dfs.sh
     ```
   - Убедимся, что процессы HDFS запущены:
     ```bash
     jps
     ```
     Должны быть видны:
     - `NameNode`
     - `SecondaryNameNode`
     - `DataNode`

3. **Проверим доступность NameNode**:
   - Убедимся, что порт NameNode (9870) открыт:
     ```bash
     netstat -tuln | grep 9870
     ```
   - Проверим веб-интерфейс HDFS, настроим SSH-туннель для перенаправления порта:
     ```bash
     ssh -L 9870:localhost:9870 hadoop@team-12-nn
     ```
   - Затем откроем в браузере:
     ```
     http://localhost:9870
     ```

---

#### **2.2 Проверим доступность HDFS из командной строки**

1. **Проверим содержимое HDFS**:
   - Выполним команду на NameNode:
     ```bash
     hdfs dfs -ls /
     ```
   - Убедимся, что отображается список директорий в корне HDFS.

2. **Создадим тестовую директорию в HDFS**:
   - На NameNode выполним:
     ```bash
     hdfs dfs -mkdir -p /user/hadoop/input
     ```
   - Убедимся, что директория создана:
     ```bash
     hdfs dfs -ls /user/hadoop
     ```

3. **Загрузим файл в HDFS**:
   - Подготовим тестовый файл на локальной машине:
     ```bash
     echo "Hello, HDFS!" > testfile.txt
     ```
   - Загрузим файл в HDFS:
     ```bash
     hdfs dfs -put testfile.txt /user/hadoop/input
     ```
   - Убедимся, что файл загружен:
     ```bash
     hdfs dfs -ls /user/hadoop/input
     ```

4. **Прочитаем содержимое файла из HDFS**:
   - Выполним команду:
     ```bash
     hdfs dfs -cat /user/hadoop/input/testfile.txt
     ```

---

#### **2.3 Убедимся, что HDFS доступен из Spark**

1. **Запустим PySpark с YARN**:
   - Перейдем в директорию, где установлен Spark:
     ```bash
     cd $SPARK_HOME
     ```
   - Запустим PySpark:
     ```bash
     pyspark --master yarn --deploy-mode client
     ```

2. **Подключимся к HDFS из PySpark**:
   - В интерактивной сессии PySpark выполним:
     ```python
     from pyspark.sql import SparkSession

     spark = SparkSession.builder \
         .appName("ConnectToHDFS") \
         .getOrCreate()

     # Прочитаем файл из HDFS
     data = spark.read.text("hdfs://team-1-nn:9000/user/hadoop/input/testfile.txt")
     data.show()
     ```

3. **Убедимся, что данные успешно читаются**:
   - Увидим содержимое файла в выводе PySpark:
     ```
     +------------+
     |       value|
     +------------+
     |Hello, HDFS!|
     +------------+
     ```

---

### **3. Установка и настройка Spark**

#### **3.1 Убедимся, что Spark установлен**
1. Проверим переменные окружения:
   ```bash
   echo $SPARK_HOME
   ```
   Если не настроено:
   ```bash
   export SPARK_HOME=/home/hadoop/spark-3.5.3-bin-hadoop3
   export PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
   ```
   Добавим эти строки в файл `~/.bashrc` и выполним:
   ```bash
   source ~/.bashrc
   ```
2. Прокинем необходимые джарники
   ```bash
   cp /home/hadoop/apache-hive-4.0.0-alpha-2-bin/lib/guava-19.0.jar /home/hadoop/spark-3.5.3-bin-hadoop3/jars/
   ```
3. Проверим, что Spark работает:
   ```bash
   spark-submit --version
   ```

### **4. Запуск сессии Apache Spark под управлением YARN**

---

#### **4.1 Запустите PySpark**

1. Убедимся, что все необходимые процессы Hadoop и YARN запущены:
   ```bash
   $HADOOP_HOME/sbin/start-dfs.sh
   $HADOOP_HOME/sbin/start-yarn.sh
   ```

2. Перейдем в директорию, где установлен Spark:
   ```bash
   cd $SPARK_HOME
   ```

3. Запустим PySpark с использованием YARN:
   ```bash
   pyspark --master yarn --deploy-mode client
   ```

4. Убедимся, что PySpark запущен, и вы видите приглашение Python:
   ```python
   >>>
   ```

5. Проверим работоспособность, выполнив базовую команду:
   ```python
   spark.version
   ```

---

### **5. Чтение данных из HDFS и трансформации**

#### **5.1 Прочитаем данные из HDFS**

1. В интерактивной сессии PySpark выполним:
   ```python
   from pyspark.sql import SparkSession

   spark = SparkSession.builder \
       .appName("DataTransformations") \
       .getOrCreate()

   # Чтение данных из HDFS
   data = spark.read.text("hdfs://team-1-nn:9000/user/hadoop/input/testfile.txt")
   data.show()
   ```

2. **Пример данных**:
   Если файл содержит строки:
   ```
   id,name,age,salary
   1,John,28,4000
   2,Jane,35,5000
   3,Mike,40,6000
   ```

---

#### **5.2 Проведем трансформации**

1. **Разделим данные на столбцы**:
   ```python
   from pyspark.sql.functions import split

   # Разделение строки на столбцы
   columns = ["id", "name", "age", "salary"]
   transformed_data = data.withColumn("value", split(data["value"], ",")) \
                          .selectExpr("value[0] as id", 
                                      "value[1] as name", 
                                      "value[2] as age", 
                                      "value[3] as salary")
   transformed_data.show()
   ```

2. **Преобразуем типы данных**:
   ```python
   from pyspark.sql.types import IntegerType, DoubleType

   transformed_data = transformed_data \
       .withColumn("id", transformed_data["id"].cast(IntegerType())) \
       .withColumn("age", transformed_data["age"].cast(IntegerType())) \
       .withColumn("salary", transformed_data["salary"].cast(DoubleType()))
   transformed_data.printSchema()
   transformed_data.show()
   ```

3. **Фильтруем данные**:
   ```python
   filtered_data = transformed_data.filter(transformed_data["age"] > 30)
   filtered_data.show()
   ```

4. **Добавим новый столбец**:
   ```python
   from pyspark.sql.functions import col

   taxed_data = filtered_data.withColumn("tax", col("salary") * 0.1)
   taxed_data.show()
   ```

5. **Сгруппируем и подсчитаем данные**:
   ```python
   grouped_data = taxed_data.groupBy("name").sum("salary")
   grouped_data.show()
   ```

6. **Сортируем данные**:
   ```python
   sorted_data = taxed_data.orderBy(col("age").desc())
   sorted_data.show()
   ```

---

### **6. Сохранение данных**

#### **6.1 Сохраним данные в HDFS**

1. Сохраним обработанные данные:
   ```python
   sorted_data.write.mode("overwrite").csv("hdfs://team-1-nn:9000/user/hadoop/output/transformed_data")
   ```

2. Убедимся, что данные сохранены:
   ```bash
   hdfs dfs -ls /user/hadoop/output/transformed_data
   ```

---

#### **6.2 Сохраним данные в Hive (если настроено)**

1. Если Hive настроен, выполним:
   ```python
   grouped_data.write.format("hive").saveAsTable("result_table")
   ```

2. Проверим таблицу в Hive CLI:
   ```bash
   hive
   ```
   Выполним запрос:
   ```sql
   SELECT * FROM result_table;
   ```

---

### **7. Проверка результатов**

#### **7.1 Проверка данных в HDFS**

1. На NameNode выполним:
   ```bash
   hdfs dfs -ls /user/hadoop/output/transformed_data
   ```

2. Прочитаем файл:
   ```bash
   hdfs dfs -cat /user/hadoop/output/transformed_data/part-00000-*
   ```

#### **7.2 Проверка данных в Hive**

1. Подключимся к Hive CLI:
   ```bash
   hive
   ```

2. Выполним запрос:
   ```sql
   SELECT * FROM result_table;
   ```

## Настройка Airflow

__Пререквизиты__:
1. Настроен Spark с Yarn
2. Запущен Hive Metastore (`hive --service metastore`)

__Алгоритм запуска__:
1. Авторизуемся в hadoop пользователя на джамп ноде
   ```bash
   sudo -i -u hadoop
   ```
2. Создаем и активируем виртуальное окружение под Airflow
   ```bash
   python3 -m venv airflow_venv
   source airflow_venv/bin/activate
   ```
3. Выставляем переменные окружения, в нашем случае выставим `AIRFLOW_HOME` в `/home/hadoop/airflow-task/airflow`
   ```bash
   export AIRFLOW_HOME=/home/hadoop/airflow-task/airflow
   ```
4. Подгружаем необходимые пакеты через pip
   ```bash
   pip install "apache-airflow[celery]==2.10.3" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.3/constraints-3.12.txt"
   pip install pyspark
   ```
6. Запускаем Airflow
   ```bash
   airflow standalone
   ```
7. Подменяем директорию с дагами в `airflow.cfg`. В файле `$AIRFLOW_HOME/airflow.cfg` подменяем `dags_folder = /home/hadoop/hadoop-setup/airflow`
8. Перезапускаем Airflow, в списке дагов должен появиться `TASK_process_raw_data`
9. Активируем и запускаем даг в UI (Trigger DAG)
10. После успешной отработки можно посмотреть на результаты вычислений, обе выходные таблицы партиционированы
```bash
   hdfs dfs -ls /user/hive/warehouse/
```
---
