#!/bin/bash
#
# sample script to backup configuation files
# version 0.1
# 2014-12-15
# @fork from https://help.ubuntu.com/lts/serverguide/backup-shellscripts.html
#
# keep backup 

# What to backup
BACKUP_FILES="/etc/postfix /etc/dovecot /etc/apache2 /etc/nginx /etc/php5"

# Where to back up to
BACKUP_DIR="/backups/files"

# Create archive filename.
DAY=`date +%Y-%m-%d_%Hh%Mm`
HOSTNAME="hostname -s"
ARCHIVE_FILE="$HOSTNAME-$DAY.tgz"

# Print start status message.
echo "Backing up $BACKUP_FILES= to $BACKUP_DIR/$ARCHIVE_FILE"
date
echo

# Backup the files using tar.
tar czf $BACKUP_DIR/$ARCHIVE_FILE $BACKUP_FILES

# Print end status message.
echo
echo "Backup finished"
date

# Long listing of files in $BACKUP_DIR to check file sizes.
ls -lh $BACKUP_DIR
