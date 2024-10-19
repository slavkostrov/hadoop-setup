#!/bin/bash

# путь до известных ключей текщей ноды
PUBLIC_KEY="/home/hadoop/.ssh/authorized_keys"
# проверяем что файл существует
if [ ! -f "$PUBLIC_KEY" ]; then
  echo "Public key not found at $PUBLIC_KEY"
  exit 1
fi

# функция для копирования ssh ключей
copy_ssh_key() {
  local host=$1
  echo "Copying SSH key to $host..."
  scp "$PUBLIC_KEY" "$host:/home/hadoop/.ssh/"
  echo "SSH key copied to $host successfully."
}

# проверяем, что переданы хосты
if [ $# -eq 0 ]; then
  echo "No hostnames provided. Usage: $0 host1 host2 ... hostN"
  exit 1
fi

# для каждого хоста копируем паблик ключи
for host in "$@"; do
  copy_ssh_key "$host"
done

exit 0
