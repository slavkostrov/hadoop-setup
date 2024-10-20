#!/bin/bash

set -e
# проверяем, что передан файл с хостами
if [ -z "$1" ]; then
  echo "Usage: $0 <file_with_hosts>"
  exit 1
fi

# проверяем, что файл существует
if [ ! -f "$1" ]; then
  echo "Error: File '$1' not found!"
  exit 1
fi

# сохраняем бэкап исходного файла
sudo cp /etc/hosts /etc/hosts.bak
# заменяем hosts
sudo cp "$1" /etc/hosts

# завершаем
if [ $? -eq 0 ]; then
  echo "/etc/hosts replaced successfully."
  exit 0
else
  echo "Got error while updating /etc/hosts."
  exit 1
fi
