#!/bin/bash

# определяем путь к Java
JAVA_HOME=$(readlink -f $(which java))

# определяем путь к файлу hadoop-env.sh
HADOOP_ENV_FILE="/home/hadoop/hadoop-3.4.0/etc/hadoop/hadoop-env.sh"

# допускаем, что в файле hadoop-env.sh всегда есть закомменченная переменная JAVA_HOME,
# поэтому только добавляем новую.
echo "JAVA_HOME=$JAVA_HOME" >> "$HADOOP_ENV_FILE"

echo "Переменная JAVA_HOME успешно добавлена в $HADOOP_ENV_FILE"
