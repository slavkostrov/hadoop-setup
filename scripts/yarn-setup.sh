#!/bin/bash

set -e

MAPRED_CONF_FILEPATH="$HADOOP_HOME/etc/hadoop/mapred-site.xml"
YARN_CONF_FILEPATH="$HADOOP_HOME/etc/hadoop/yarn-site.xml"

HOSTNAMES_FILE="../../hostnames.txt"

NGINX_YARN_AVAILABLE_CONF_PATH="/etc/nginx/sites-available/yarn"
NGINX_YARN_ENABLED_CONF_PATH="/etc/nginx/sites-enabled/yarn"
NGINX_HSERVER_AVAILABLE_CONF_PATH="/etc/nginx/sites-available/hserver"
NGINX_HSERVER_ENABLED_CONF_PATH="/etc/nginx/sites-enabled/hserver"


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
<configuration>
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
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG.TZ,HADOOP_MAPRED_HOME</value>
    </property>
<configuration>
EOL


# Copy configuration files to all cluster nodes

# Get all cluster nodes
echo "Preparing to transfer conf file to all cluster nodes..."

bash update-hosts.sh "$HOSTNAMES_FILE"

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
    sshpass -p "$ssh_password" scp $MAPRED_CONF_FILE $host:$HADOOP_HOME/etc/hadoop
    sshpass -p "$ssh_password" scp $YARN_CONF_FILE $host:$HADOOP_HOME/etc/hadoop
    echo "Host $host: transfer is done"

done


# Setup nginx

echo "Setting up nginx for yarn and historyserver"
read -p "Enter namenode host: " NAMENODE_HOST
read -sp "Enter password for sudo: " sudo_password

if [ -f "$NGINX_YARN_AVAILABLE_CONF_PATH" ]; then
  echo "File $NGINX_YARN_AVAILABLE_CONF_PATH already exists"
  exit 1
fi

if [ -f "$NGINX_HSERVER_AVAILABLE_CONF_PATH" ]; then
  echo "File $NGINX_HSERVER_AVAILABLE_CONF_PATH already exists"
  exit 1
fi

# yarn
echo $sudo_password | sudo -S cp /etc/nginx/sites-avaialable/default $NGINX_YARN_AVAILABLE_CONF_PATH
echo $sudo_password | sudo -S sed -i -e 's/80/8088/g' -e '/\[::\]/d' -e "0,/try_files/s/.*try_files.*/\t\tproxy_pass http:\/\/$NAMENODE_HOST:8088;/" $NGINX_YARN_AVAILABLE_CONF_PATH
echo $sudo_password | sudo -S ln -s $NGINX_YARN_AVAILABLE_CONF_PATH $NGINX_YARN_ENABLED_CONF_PATH

# history server
echo $sudo_password | sudo -S cp /etc/nginx/sites-avaialable/default $NGINX_HSERVER_AVAILABLE_CONF_PATH
echo $sudo_password | sudo -S sed -i -e 's/80/19888/g' -e '/\[::\]/d' -e "0,/try_files/s/.*try_files.*/\t\tproxy_pass http:\/\/$NAMENODE_HOST:19888;/" $NGINX_HSERVER_AVAILABLE_CONF_PATH
echo $sudo_password | sudo -S ln -s $NGINX_HSERVER_AVAILABLE_CONF_PATH $NGINX_HSERVER_ENABLED_CONF_PATH

echo "Nginx setup is succesful, reload nginx with `sudo systemctl reload nginx`"

exit 0
