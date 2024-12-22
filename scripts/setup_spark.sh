#!/bin/bash

# Параметры
HADOOP_HOME=/home/hadoop/hadoop-3.4.0
SPARK_HOME=/home/hadoop/spark-3.5.3-bin-hadoop3
HDFS_INPUT_DIR="/home/hadoop/input"
HDFS_OUTPUT_DIR="/home/hadoop/output/transformed_data"
LOCAL_TEST_FILE="testfile.txt"

echo "=== Настройка кластера Hadoop и YARN ==="

# 1.1 Запуск HDFS и YARN
echo "Запуск HDFS..."
$HADOOP_HOME/sbin/start-dfs.sh
sleep 5

echo "Проверка работы HDFS..."
$HADOOP_HOME/bin/hdfs dfsadmin -report

echo "Запуск YARN..."
$HADOOP_HOME/sbin/start-yarn.sh
sleep 5

echo "Проверка работы YARN..."
$HADOOP_HOME/bin/yarn node -list

# 2. Настройка HDFS
echo "=== Настройка HDFS ==="

# 2.1 Создание входной директории и загрузка данных
echo "Создание директории в HDFS..."
$HADOOP_HOME/bin/hdfs dfs -mkdir -p $HDFS_INPUT_DIR

echo "Создание тестового файла..."
echo -e "id,name,age,salary\n1,John,28,4000\n2,Jane,35,5000\n3,Mike,40,6000" > $LOCAL_TEST_FILE

echo "Загрузка тестового файла в HDFS..."
$HADOOP_HOME/bin/hdfs dfs -put $LOCAL_TEST_FILE $HDFS_INPUT_DIR

echo "Проверка содержимого HDFS..."
$HADOOP_HOME/bin/hdfs dfs -ls $HDFS_INPUT_DIR

# 3. Установка и настройка Spark
echo "=== Убедимся, что Spark настроен ==="

export PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH

echo "Проверка версии Spark..."
spark-submit --version

# 4. Запуск PySpark и выполнение задач
echo "=== Запуск PySpark ==="

pyspark_script=$(cat <<EOF
from pyspark.sql import SparkSession
from pyspark.sql.functions import split, col
from pyspark.sql.types import IntegerType, DoubleType

# Создание Spark-сессии
spark = SparkSession.builder \
    .appName("DataTransformations") \
    .master("yarn") \
    .getOrCreate()

# Чтение данных из HDFS
data = spark.read.text("$HDFS_INPUT_DIR/testfile.txt")

# Разделение данных на столбцы
transformed_data = data.withColumn("value", split(data["value"], ",")) \
    .selectExpr("value[0] as id", 
                "value[1] as name", 
                "value[2] as age", 
                "value[3] as salary")

# Преобразование типов данных
transformed_data = transformed_data \
    .withColumn("id", transformed_data["id"].cast(IntegerType())) \
    .withColumn("age", transformed_data["age"].cast(IntegerType())) \
    .withColumn("salary", transformed_data["salary"].cast(DoubleType()))

# Фильтрация данных
filtered_data = transformed_data.filter(transformed_data["age"] > 30)

# Добавление нового столбца
taxed_data = filtered_data.withColumn("tax", col("salary") * 0.1)

# Сортировка данных
sorted_data = taxed_data.orderBy(col("age").desc())

# Сохранение данных в HDFS
sorted_data.write.mode("overwrite").csv("$HDFS_OUTPUT_DIR")
EOF
)

echo "Запуск PySpark задачи..."
echo "$pyspark_script" | pyspark --master yarn --deploy-mode client

# 5. Проверка результатов
echo "=== Проверка результатов ==="

echo "Содержимое директории HDFS с результатами:"
$HADOOP_HOME/bin/hdfs dfs -ls $HDFS_OUTPUT_DIR

