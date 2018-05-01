#!/usr/bin/env bash

set -e
DATABASE_NAME='database'
BACKUP_DIR=/var/backups/example
BACKUP_FILE=$BACKUP_DIR/$DATABASE_NAME-$(date +"%d-%m-%y").bson
mongodump -d $DATABASE_NAME -o $BACKUP_DIR
mv $BACKUP_DIR/$DATABASE_NAME $BACKUP_FILE
gzip -r $BACKUP_FILE
chown -R www-data:www-data $BACKUP_FILE
chmod -R ug+w $BACKUP_FILE
