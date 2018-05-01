#!/usr/bin/env bash

set -e

print() {
    echo -e "\033[1;36m$@\033[0m"
}

prompt() {
    echo -en "\033[1;32m$@\033[0m"
}

prompt "Your Github user name (for SSH public key retrieval): "
read github_username

curl -O https://github.com/$github_username.keys
cat $github_username.keys >> ~/.ssh/authorized_keys
rm $github_username.keys
