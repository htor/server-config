#!/usr/bin/env bash

set -e

print() {
    echo -e "\033[1;36m$@\033[0m"
}

prompt() {
    echo -en "\033[1;32m$@\033[0m"
}

if (( $UID != 0 ))
then
    print "Need to be root. Exiting..."
    exit 1
fi

prompt "Enter hostname: "
read hostname
prompt "Enter user name for new user: "
read username
prompt "Enter public IPv4: "
read ipv4
prompt "Enter public IPv6: "
read ipv6
prompt "Enter the FQDN: "
read domain_name
prompt "Your Github user name (for SSH public key retrieval): "
read github_username

print "Configuring locales..."
locale-gen en_US.UTF-8
cat > /etc/default/locale << EOF
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
EOF
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

print "Setting hostname..."
hostnamectl set-hostname $hostname

print "Updating /etc/hosts..."
echo "$ipv4 $domain_name $hostname" >> /etc/hosts
echo "$ipv6 $domain_name $hostname" >> /etc/hosts

print "Setting the timezone to Europe/Oslo..."
timedatectl set-timezone 'Europe/Oslo'

print "Removing bloat..."
>| /etc/issue
>| /etc/motd

print "Updating system..."
apt-get update
apt-get -y upgrade

print "Installing needed packages..."
for package in sudo curl git vim
do
    apt-get install -y $package
done

print "Creating new user $username with sudo privileges..."
useradd -m -G sudo,www-data -s /bin/bash $username

print "Setting up ssh directory and authorized keys for user $username..."
mkdir /home/$username/.ssh
touch /home/$username/.ssh/authorized_keys
chmod 700 /home/$username/.ssh
chmod 600 /home/$username/.ssh/authorized_keys
curl -O https://github.com/$github_username.keys
cat $github_username.keys >> /home/$username/.ssh/authorized_keys
rm $github_username.keys

print "Configuring SSH settings..."
echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
echo 'Port 4321' >> /etc/ssh/sshd_config
echo 'PrintLastLog no' >> /etc/ssh/sshd_config
echo 'ClientAliveInterval 300' >> /etc/ssh/sshd_config
echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config
systemctl restart ssh

# firewall
#apt-get install ufw; 
#ufw ufw default deny incoming; 
#ufw default allow outgoing:
#ufw allow 4321/tcp
#ufw allow 80/tcp		
#ufw allow 443/tcp
#systemctl enable ufw
#systemctl start ufw

print "Setting up config files for user $username..."
cat > /home/$username/.vimrc << EOF
syntax on
set number
EOF
cp /home/$username/.vimrc ~

cat >> /home/$username/.bashrc << EOF
alias ls='ls --color=auto'
alias ll='ls -l'
alias grep='grep --color=auto'
PS1='\u@\h \w '
EOF

cat >> /home/$username/.bash_profile << EOF
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
EOF

print "Creating directory structure for web server..."
mkdir -p /var/{www,repos,backups}
chown www-data:www-data /var/{www,repos,backups}
chmod g+w /var/{www,repos,backups}

print "Setting permissions for user $username..."
chown -R $username:$username /home/$username

print "Changing root password..."
passwd

print "Changing password for user $username..."
passwd $username

print "Done configuring this server."
print "Please log out and log back in with username: $username, address: $ipv4 and port 4321 to start using it"
