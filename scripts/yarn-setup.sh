#!/bin/bash

set -e

MAPRED_CONF_FILEPATH="$HADOOP_HOME/etc/hadoop/mapred-site.xml"
YARN_CONF_FILEPATH="$HADOOP_HOME/etc/hadoop/yarn-site.xml"

# mapred-site.xml

# remove old configuration
echo "Setting up mapred-site.xml"
sed -i '/<configuration>/,/<\/configuration>/d' "$MAPRED_CONF_FILEPATH"

# define new configuration
cat <<EOL >> "$MAPRED_CONF_FILEPATH"
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
EOL


# yarn-site.xml

# remove old configuration
echo "Setting up yarn-site.xml"
sed -i '/<configuration>/,/<\/configuration>/d' "$YARN_CONF_FILEPATH"

# define new configuration
cat <<EOL >> "$YARN_CONF_FILEPATH"
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>
EOL


# Copy configuration files to all cluster nodes

# Get all cluster nodes
echo "Preparing to transfer conf file to all cluster nodes..."

current_hostname=$(hostname)
current_ip=$(hostname -I | awk '{print $1}')

declare -a hosts
while read -r ip name; do
    if [[ "$name" != "$current_hostname" && "$ip" != "$current_ip" && "$name" != "" ]]; then
        hosts+=("$name")
    fi
done < /etc/hosts

# Get password to transfer data
read -sp "Enter password for SSH/SCP: " ssh_password
echo

# Transfer data to all hosts
echo "Start data transfer"
for host in "${hosts[@]}"; do
    # Copy files
    echo transfer "$MAPRED_CONF_FILEPATH" to "$host:$HADOOP_HOME/etc/hadoop"
    sshpass -p "$ssh_password" scp "$MAPRED_CONF_FILEPATH" "$host:$HADOOP_HOME/etc/hadoop"

    echo transfer "$YARN_CONF_FILEPATH" to "$host:$HADOOP_HOME/etc/hadoop"
    sshpass -p "$ssh_password" scp "$YARN_CONF_FILEPATH" "$host:$HADOOP_HOME/etc/hadoop"

    echo "Host $host: transfer is done"

done

echo "Yarn setup is succesfull!"

exit 0
