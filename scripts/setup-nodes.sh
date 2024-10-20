#!/bin/bash

set -e

HOSTNAMES_FILE="hostnames.txt"
MAIN_USER="team"

DIST_NAME="hadoop-3.4.0.tar.gz"
DIST_LINK="https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/$DIST_NAME"

# настраиваем текущую ноду
echo "Setup current node"
bash update-hosts.sh "$HOSTNAMES_FILE"
bash create-user.sh | tail -n1 > "/home/hadoop/.ssh/authorized_keys"

# скачиваем дистрибутив hadoop
echo "Download hadoop dist..."
sudo wget -P /home/hadoop "$DIST_LINK" -q --show-progress
echo "Extract hadoop dist..."
sudo tar -xzf /home/hadoop/$DIST_NAME -C /home/hadoop/ --checkpoint=.100 --checkpoint-action=dot

current_hostname=$(hostname)
current_ip=$(hostname -I | awk '{print $1}')

# собираем список всех хостов
declare -a hosts
while read -r ip name; do
    if [[ "$name" != "$current_hostname" && "$ip" != "$current_ip" && "$name" != "" ]]; then
        hosts+=("$name")
    fi
done < /etc/hosts

# вводим пароль для хостов
read -sp "Enter password for SSH/SCP: " ssh_password
echo

# настраиваем удаленно каждый хост
# при этом сохраняем публичные ключи
for host in "${hosts[@]}"; do
    echo "Processing host: $host"

    # копируем все нужные файлы
    sshpass -p "$ssh_password" scp create-user.sh "$HOSTNAMES_FILE" $MAIN_USER@$host:/
    sshpass -p "$ssh_password" ssh $MAIN_USER@$host "bash /update-hosts.sh $HOSTNAMES_FILE"

    # нв выходе записываем public ssh ключ с удаленного хоста на локальный хост
    sshpass -p "$ssh_password" ssh $MAIN_USER@$host 'bash /create-user.sh' | tail -n1 >> "/home/hadoop/.ssh/authorized_keys"

    # копируем дистрибутив скаченный
    sshpass -p "$ssh_password" scp "$DIST_NAME" $MAIN_USER@$host:/home/hadoop

    # распаковываем
    sshpass -p "$ssh_password" ssh $MAIN_USER@$host "sudo tar -xzf /home/hadoop/$DIST_NAME -C /home/hadoop/ --checkpoint=.100 --checkpoint-action=dot"

done

for host in "${hosts[@]}"; do
    copy_ssh_key "$host"
done
