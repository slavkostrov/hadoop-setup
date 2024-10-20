#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 hostnames.txt"
    exit 1
fi

HOSTNAMES_FILE="$1"
MAIN_USER="team"

# настраиваем текущую ноду
echo "Setup current node"
bash update-hosts.sh "$HOSTNAMES_FILE"
bash create-user.sh | tail -n1 > "/home/hadoop/.ssh/authorized_keys"

current_hostname=$(hostname)
current_ip=$(hostname -I | awk '{print $1}')

# собираем список всех хостов
declare -a hosts
while read -r ip name; do
    if [[ "$name" != "$current_hostname" && "$ip" != "$current_ip" && "$name" != "" ]]; then
        hosts+=("$ip")
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
    sshpass -p "$ssh_password" scp create-user.sh "$HOSTNAMES_FILE" $MAIN_USER@"$host":/
    sshpass -p "$ssh_password" ssh $MAIN_USER@"$host" 'bash /update-hosts.sh $HOSTNAMES_FILE'

    # нв выходе записываем public ssh ключ с удаленного хоста на локальный хост
    sshpass -p "$ssh_password" ssh $MAIN_USER@"$host" 'bash /create-user.sh' | tail -n1 >> "/home/hadoop/.ssh/authorized_keys"

done

for host in "${hosts[@]}"; do
    copy_ssh_key "$host"
done
