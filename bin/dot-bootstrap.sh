#!/usr/bin/env bash
set -e

if [ -f /etc/redhat-release ] && ! [ -x "$(command -v ansible)" ]; then
  yum install ansible -y
elif [ -f /etc/debian_version ] && ! [ -x "$(command -v ansible)" ]; then
  apt update && apt install ansible -y
elif [ -f /etc/arch-release ] && ! [ -x "$(command -v ansible)" ]; then
  pacman -Sy ansible --noconfirm
fi

ansible-playbook -i ~/git/.dotfiles/inventory/hosts.yml ~/git/.dotfiles/plays/dep.yml --ask-become-pass --diff
