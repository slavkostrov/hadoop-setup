#!/bin/bash

set -e

echo "Create hadoop user..."

# создаем пользователя hadoop
sudo adduser --gecos "" hadoop
# переключаемся на пользователя hadoop
sudo -i -u hadoop bash -c '
echo "Generate ssh key for hadoop user"
# Generate ssh key for user hadoop
yes | ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_rsa

echo "Copy public ssh key for next steps"
# Output public ssh key to stdout
cat ~/.ssh/id_rsa.pub
'

exit 0
