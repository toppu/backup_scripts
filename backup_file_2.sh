#!/bin/bash
#
# version 0.1
# 2014-12-15
#
#@author Suttipong Mungkala based on  
#@fork from @Julius Zaromskis(http://nicaw.wordpress.com/2013/04/18/bash-backup-rotation-script/)
#@description File backup rotation

##################################
# Start configuration
##################################

#-----------------------
# Email settings
#-----------------------

# send success or failure e-mails with details.
email_report="1"

# email address to send mail to 
mail_to="suttipong@immpres.com"

#-----------------------
# General settings
#-----------------------
# Storage folder where to move backup files
# Must contain backup.monthly backup.weekly backup.daily folders
#storage=/backups/test

# Source folder where files are backed
#source=$storage/incoming

# what to backup
backup_target="/etc/postfix /etc/dovecot /etc/apache2 /etc/nginx /etc/php5"

# backup directory
backup_dir="/backups/files"

# which day do you do weekly backups (1 to 7 where 1 is Monday)
doweekly=6

# backup date
date=`date +%Y-%m-%d_%Hh%Mm`

# backup archive file
archive_file="etc-$date.tgz"

##################################
# End configuration
##################################


# Get current month and week day number
month_day=`date +"%d"`
week_day=`date +"%u"`

# Optional check if source files exist. Email if failed.
#if [ ! -f $source/archive.tgz ]; then
#ls -l $source/ | mail your@email.com -s "[backup script] Daily backup failed! Please check for missing files."
#fi

# It is logical to run this script daily. We take files from source folder and move them to
# appropriate destination folder

# first day of a month
if [ "$month_day" -eq 1 ] ; then
  destination=monthly
else
  # On weekly basis
  if [ "$week_day" -eq "$doweekly" ] ; then
    destination=weekly
  else
    # On any regular day do
    destination=daily
  fi
fi

# backup the files using tar.
tar czf $backup_dir/$destination/$archive_file $backup_target

# daily - keep for 14 days
find $backup_dir/daily/ -maxdepth 1 -mtime +14 -type d -exec rm -rv {} \;

# weekly - keep for 60 days
find $backup_dir/weekly/ -maxdepth 1 -mtime +60 -type d -exec rm -rv {} \;

# monthly - keep for 300 days
find $$backup_dir/monthly/ -maxdepth 1 -mtime +300 -type d -exec rm -rv {} \;

