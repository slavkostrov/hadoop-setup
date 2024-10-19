#!/bin/bash

set -e

echo "Create hadoop user..."

# создаем пользователя hadoop
sudo adduser --gecos "" hadoop

# переключаемся на пользователя hadoop
echo "Generate ssh key for hadoop user"

# генерируем ssh ключ для юзера hadoop
yes | sudo -u hadoop ssh-keygen -t ed25519 -N "" -f /home/hadoop/.ssh/id_rsa

echo "Copy public ssh key for next steps"

# выводим public ssh ключ в stdout
sudo -u hadoop cat /home/hadoop/.ssh/id_rsa.pub

exit 0
