#!/bin/bash

set -e
USER="hadoop"
echo "Create hadoop user..."

# создаем пользователя hadoop
id "$USER" &>/dev/null || sudo adduser --gecos "" "$USER"

# переключаемся на пользователя hadoop
echo "Generate ssh key for hadoop user"

# генерируем ssh ключ для юзера hadoop
yes | sudo -u $USER ssh-keygen -t ed25519 -N "" -f /home/$USER/.ssh/id_rsa

echo "Copy public ssh key for next steps"

# выводим public ssh ключ в stdout
sudo -u $USER cat /home/$USER/.ssh/id_rsa.pub

exit 0
