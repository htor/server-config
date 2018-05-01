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

print "Updating the system..."
apt-get update
apt-get -y upgrade

print "Installing Apache..."
apt-get -y install apache2
prompt "Enter user name for user to add to www-data: "
read username
print "Adding user $username to group www-data..."
gpasswd -a $username www-data

print "Backing up /etc/apache2/apache2.conf to /etc/apache2/apache2.conf.bak"
cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak

print "Configuring Apache..."

cat > /etc/apache2/mods-available/mpm_prefork.conf << EOF
# prefork MPM
# StartServers: number of server processes to start
# MinSpareServers: minimum number of server processes which are kept spare
# MaxSpareServers: maximum number of server processes which are kept spare
# MaxRequestWorkers: maximum number of server processes allowed to start
# MaxConnectionsPerChild: maximum number of requests a server process serves

<IfModule mpm_prefork_module>
        StartServers              2
        MinSpareServers           6
        MaxSpareServers           12
        MaxRequestWorkers         30
        MaxConnectionsPerChild    3000
</IfModule>
EOF

print "Disabling default Apache page..."
a2dissite 000-default

print "Configuring Apache modules..."
a2dismod mpm_event
a2enmod mpm_prefork
a2enmod headers
a2enmod expires
a2enmod rewrite
a2enmod proxy_http
a2enmod deflate
a2enmod setenvif
a2enmod filter
a2enmod mime
a2enmod ssl

print "Installing MySQL..."
apt-get -y install mysql-server

print "Configuring MySQL..."
sed -ri '/^#?key_buffer .+/d' /etc/mysql/my.cnf
echo 'table_open_cache = 32M' >> /etc/mysql/my.cnf
echo 'key_buffer_size = 32M' >> /etc/mysql/my.cnf
echo 'max_connections = 75' >> /etc/mysql/my.cnf
echo 'max_allowed_packet = 1M' >> /etc/mysql/my.cnf
echo 'thread_stack = 128K' >> /etc/mysql/my.cnf

print "Securing MySQL installation..."
mysql_secure_installation
systemctl restart mysql

print "Installing PHP..."
apt-get -y install php5 php5-mysql php5-curl php-pear libapache2-mod-php5 php5-gd

print "Configuring PHP..."
sed -ri 's#^(; |;)?error_reporting = .+#error_reporting = E_COMPILE_ERROR|E_RECOVERABLE_ERROR|E_ERROR|E_CORE_ERROR#g' /etc/php5/apache2/php.ini
sed -ri 's#^(; |;)?error_log = .+#error_log = /var/log/php/error.log#g' /etc/php5/apache2/php.ini
sed -ri 's#^;?max_input_time = .+#max_input_time = 30#g' /etc/php5/apache2/php.ini
mkdir -p /var/log/php
chown www-data /var/log/php

print "Setting permissions for www-data..."
chown -R www-data:www-data /var/www
chmod -R g+w /var/www

print "Restarting Apache..."
systemctl restart apache2

print "LAMP is now installed and configured. Please log out and log back in"
