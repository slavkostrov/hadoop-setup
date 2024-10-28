#!/bin/bash

set -e

# === настройка HADOOP_HOME и JAVA_HOME в .profile ===
# определяем путь для Hadoop
HADOOP_HOME="/home/hadoop/hadoop-3.4.0"

# определяем путь для Java
JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

# добавляем переменные в .profile
echo "export HADOOP_HOME=$HADOOP_HOME" >> ~/.profile
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.profile
echo "export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin" >> ~/.profile

source ~/.profile

echo "Переменные HADOOP_HOME, JAVA_HOME и PATH успешно добавлены в .profile"
echo "-------------------------------------------"

# === добавление переменной JAVA_HOME в hadoop-env.sh ===
# определяем путь к файлу hadoop-env.sh
HADOOP_ENV_FILE="$HADOOP_HOME/etc/hadoop/hadoop-env.sh"

# допускаем, что в файле hadoop-env.sh всегда есть закомменченная переменная JAVA_HOME,
# поэтому только добавляем новую.
echo "JAVA_HOME=$JAVA_HOME" >> "$HADOOP_ENV_FILE"

echo "Переменная JAVA_HOME успешно добавлена в $HADOOP_ENV_FILE"
echo "-------------------------------------------"

# === настройка core-site.xml ===
# запрашиваем у пользователя ввод имени NameNode
read -p "Введите имя NameNode для добавления в core-site.xml (например, <team-00-nn>): " NAMENODE_NAME

# полный адрес NameNode
NAMENODE_ADDRESS="hdfs://$NAMENODE_NAME:9000"

# определяем путь к файлу core-site.xml
CORE_SITE_FILE="$HADOOP_HOME/etc/hadoop/core-site.xml"

# удаляем существующий конфиг с содержимым в core-site.xml
sed -i '/<configuration>/,/<\/configuration>/d' "$CORE_SITE_FILE"

# добавляем параметр fs.defaultFS в core-site.xml
cat <<EOL >> "$CORE_SITE_FILE"
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>$NAMENODE_ADDRESS</value>
    </property>
</configuration>
EOL

echo "-------------------------------------------"

# === настройка hdfs-site.xml ===
# определяем путь к файлу hdfs-site.xml
HDFS_SITE_FILE="$HADOOP_HOME/etc/hadoop/hdfs-site.xml"

# удаляем существующий конфиг с содержимым в hdfs-site.xml
sed -i '/<configuration>/,/<\/configuration>/d' "$HDFS_SITE_FILE"

# добавляем параметр репликации в hdfs-site.xml
cat <<EOL >> "$HDFS_SITE_FILE"
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
</configuration>
EOL

echo "-------------------------------------------"

# === настройка workers ===
# определяем путь к файлу workers
WORKERS_FILE="$HADOOP_HOME/etc/hadoop/workers"

# очищаем содержимое файла workers
echo "" > "$WORKERS_FILE"

# запрашиваем ввод адресов NameNode и DataNodes
echo "Введите адреса NameNode и DataNodes в формате <team-00-nn> для добавления в workers (введите пустую строку для завершения ввода):"

# цикл для ввода адресов
while true; do
    read -p "Введите адрес ноды: " NODE
    # если введена пустая строка, прекращаем ввод
    if [ -z "$NODE" ]; then
        break
    fi
    # добавляем адрес workers
    echo "$NODE" >> "$WORKERS_FILE"
done

echo "-------------------------------------------"

echo "Настройка завершена!"

