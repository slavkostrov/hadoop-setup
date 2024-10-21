#!/bin/bash

# определяем путь для Hadoop
HADOOP_HOME="/home/hadoop/hadoop-3.4.0"

# определяем путь для Java
JAVA_HOME=$(readlink -f $(which java))

# добавляем переменные в .profile
echo "export HADOOP_HOME=$HADOOP_HOME" >> ~/.profile
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.profile
echo "export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin" >> ~/.profile

source ~/.profile

echo "Переменные HADOOP_HOME, JAVA_HOME и PATH успешно добавлены в .profile"
