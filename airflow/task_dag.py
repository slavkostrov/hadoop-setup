import datetime

from airflow.models.dag import DAG
from airflow.decorators import task
from pyspark.sql import functions as F, SparkSession


WORKING_PREFIX = "/user/hadoop"
DAG_CONFIG = dict(
    dag_id="TASK_process_raw_data",
    start_date=datetime.datetime(2024, 12, 20),
    catchup=False,
    schedule=None,
    tags=["airflow-task"],
)


def create_spark(application_name: str) -> SparkSession:
    """Create spark session.

    Args:
        application_name: name of spark application

    Returns:
        Created spark session
    """
    spark = (
        SparkSession
        .builder
        .appName(application_name)
        .config("spark.master", "yarn")
        .config("spark.sql.catalogImplementation", "hive")
        .config("spark.sql.hive.metastore.version", "2.3.9")
        .config("spark.hadoop.hive.metastore.uris", "thrift://team-1-jn:9083")
        .enableHiveSupport()
        .config("hive.exec.dynamic.partition", "true")
        .config("hive.exec.dynamic.partition.mode", "nonstrict")
        .config("hive.exec.max.dynamic.partitions", "5000")
        .getOrCreate()
    )
    return spark


@task(task_id="preprocess_data")
def preprocess_data(working_prefix: str = "/user/hadoop"):
    """Read source file and preprocess data.

    Args:
        working_prefix: working directory
    """
    spark = create_spark("airflow-task")
    result_df = (
        spark.read.csv(f"{working_prefix}/raw_data.csv", header=True, inferSchema=True)
        .withColumn("datesold", F.to_date("datesold"))
        .withColumn("sold_year", F.year("datesold"))
        .filter(F.col("datesold") > "2012-01-01")
    )
    result_df.write.saveAsTable(f"AIRFLOW_TASK_preprocessed_data", mode="overwrite", partitionBy="sold_year")
    spark.stop()


@task(task_id="aggregate_daily_stats")
def aggregate_daily_stats(date_column: str = "sold_year"):
    """Aggregate sold estate by date and get selling statistics.

    Args:
        working_prefix: working directory
        data_column: date column in spark dataframe
    """
    spark = create_spark("airflow-task")
    result_df = (
        spark.table("AIRFLOW_TASK_preprocessed_data")
        .groupBy(date_column)
        .agg(
            F.countDistinct("postcode").alias("uniq_sold"),
            F.mean("price").alias("average_price"),
            F.min("price").alias("min_price"),
            F.max("price").alias("max_price"),
            F.mode("propertyType").alias("most_common_property_type")
        )
    )
    result_df.write.saveAsTable(f"AIRFLOW_TASK_daily_stats", mode="overwrite", partitionBy="sold_year")
    spark.stop()

with DAG(**DAG_CONFIG):
    preprocess_task = preprocess_data(working_prefix=WORKING_PREFIX)
    aggregate_task = aggregate_daily_stats()

    preprocess_task >> aggregate_task

