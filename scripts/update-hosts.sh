#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <file_with_hosts>"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "Error: File '$1' not found!"
  exit 1
fi

sudo cp /etc/hosts /etc/hosts.bak
sudo cp "$1" /etc/hosts

if [ $? -eq 0 ]; then
  echo "/etc/hosts replaced successfully."
  exit 0
else
  echo "Got error while updating /etc/hosts."
  exit 1
fi
