#!/bin/bash

set -e

echo "Create hadoop user..."

sudo adduser --gecos "" hadoop
sudo -i -u hadoop bash << EOF

echo "Generate ssh key for hadoop user"
yes | ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_rsa

echo "Copy public ssh key for next steps"
cat /home/hadoop/.ssh/id_rsa

exit 0
