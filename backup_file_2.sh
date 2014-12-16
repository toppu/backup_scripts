#!/bin/bash
#
# version 0.1
# 2014-12-15
#
#@author dentsuboy.bm at gmail.com 
#@fork from @Julius Zaromskis(http://nicaw.wordpress.com/2013/04/18/bash-backup-rotation-script/)
#@description File backup rotation

##################################
# Start configuration
##################################

#-----------------------
# Email settings
#-----------------------

# send success or failure e-mails with details.
#email_report="1"

# email address to send mail to 
#mail_to="suttipong@immpres.com"

#-----------------------
# General settings
#-----------------------

# what to backup (each folder is separated by space)
backup_target="/etc/postfix /etc/dovecot /etc/apache2 /etc/nginx /etc/php5"

# backup directory
backup_dir="/backups/files"

# number of days the daily backup keep
rotation_day=7

# number of weeks the weekly backup keep
rotation_week=4

# number of months the monthly backup keep
rotation_month=3

# which day do you do weekly backups (1 to 7 where 1 is Monday)
doweekly=6

# backup date
date=`date +%Y-%m-%d`

# backup archive file (archive_file-date.tgz format)
archive_file_prefix="etc"

##################################
# End configuration
##################################


# backup archive file (!dont edit this parameter)
archive_file="$archive_file_prefix-$date.tgz"

# 
# show error message if a command failed
#
function error () {
    if [ -n "$1" ]; then
        echo $1
        exit 1
    fi
    exit 0
}

STATUS=0

# create required directories
mkdir -p $backup_dir/{daily,weekly,monthly} || error 'failed to create $backup_dir directories'

# Get current month and week day number
month_day=`date +"%d"`
week_day=`date +"%u"`

# Optional check if source files exist. Email if failed.
#if [ ! -f $source/archive.tgz ]; then
#ls -l $source/ | mail your@email.com -s "[backup script] Daily backup failed! Please check for missing files."
#fi

# It is logical to run this script daily. 
# first day of a month
if [ "$month_day" -eq 1 ] ; then
  backup_type=monthly
  rotation_lookup=$rotation_month
else
  # On weekly basis
  if [ "$week_day" -eq "$doweekly" ] ; then
    backup_type=weekly
    rotation_lookup=$rotation_week
  else
    # On any regular day do
    backup_type=daily
    rotation_lookup=$rotation_day
  fi
fi

# backup the files using tar
tar czf $backup_dir/$backup_type/$archive_file $backup_target || error 'failed to create $archive_file archive file'

# delete old files
find $backup_dir/daily/ -maxdepth 1 -mtime +$rotation_lookup -type f -exec rm -rv {} \; || error 'failed to delete daily archive file'
find $backup_dir/weekly/ -maxdepth 1 -mtime +$rotation_lookup -type f -exec rm -rv {} \; || error 'failed to create weekly archive file'
find $backup_dir/monthly/ -maxdepth 1 -mtime +$rotation_lookup -type f -exec rm -rv {} \; || error 'failed to create monthly archive file'

