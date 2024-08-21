#!/usr/bin/env bash
set -e

if ! [ -x "$(command -v ansible)" ]; then
  yum install ansible -y
fi

ansible-playbook -i ~/git/.dotfiles/inventory/hosts.yml ~/git/.dotfiles/plays/deploy.yml --ask-become-pass --diff

#if command -v terminal-notifier 1>/dev/null 2>&1; then
#  terminal-notifier -title "dotfiles: Bootstrap complete" -message "Successfully set up environment."
#fi
