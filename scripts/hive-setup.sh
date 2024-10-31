#!/bin/bash

set -e

# export HIVE_HOME=/home/hadoop/apache-hive-4.0.1-bin
export HIVE_HOME=$(pwd)
export HIVE_CONF_DIR=$HIVE_HOME/conf
export HIVE_AUX_JAR_PATH=$HIVE_HOME/lib/*
export PATH=$HIVE_HOME/bin:$PATH
HIVE_CONF_FILEPATH="$HIVE_HOME/conf/hive-site-2.xml"

# creating hive-site.xml
echo "Setting up hive-site.xml"
touch $HIVE_CONF_DIR/hive-site-2.xml

# define new configuration
cat <<EOL >> "$HIVE_CONF_FILEPATH"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    <property>
        <name>hive.server2.authentication</name>
        <value>NONE</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:postgresql://127.0.0.1:5432/metastore</value>
    </property>
    <property>
        <name>hive.server2.thrift.port</name>
        <value>10000</value>
    </property>
    <property>
            <name>javax.jdo.option.ConnectionDriverName</name>
            <value>org.postgresql.Driver</value>
    </property>
    <property>
            <name>javax.jdo.option.ConnectionUserName</name>
            <value>hive</value>
    </property>
    <property>
            <name>javax.jdo.option.ConnectionPassword</name>
            <value>hive</value>
    </property>
</configuration>
EOL

echo "Start building Hive"
bin/schematool -dbType postgres -initSchema

echo "Launching Hive"
hive --hiveconf hive.server2.enable.doAs=false --hiveconf hive.security.authorization.enabled=false --service hiveserver2 1>> /tmp/hs2.log 2>> /tmp/hs2.log &
