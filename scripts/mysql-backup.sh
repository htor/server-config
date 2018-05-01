#!/usr/bin/env bash

set -e
BACKUP_FILE=/var/backups/example-$(date +"%d-%m-%y").sql.gz
mysqldump -u htor -p"password" database | gzip > $BACKUP_FILE
chown www-data:www-data $BACKUP_FILE
chmod ug+w $BACKUP_FILE
