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
email_report="1"

# email address to send mail to 
mail_to="suttipong@immpres.com"

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

# if the loggile should be deleted
cleanup_log="1"

##################################
# End configuration
##################################

file="$archive_file_prefix-$date"
archive_file="$archive_file_prefix-$date.tgz"
LOGFILE=$backup_dir/$archive_file-`date +%H%M`.log       # Logfile Name
LOGERR=$backup_dir/$archive_file-`date +%H%M`.error       # Logfile Name

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

# create required directories
mkdir -p $backup_dir/{daily,weekly,monthly,$archive_file} || error 'failed to create $backup_dir directories'

# Get current month and week day number
month_day=`date +"%d"`
week_day=`date +"%u"`

# IO redirection for logging.
touch $LOGFILE
exec 6>&1           # Link file descriptor #6 with stdout.
                    # Saves stdout.
exec > $LOGFILE     # stdout replaced with file $LOGFILE.

touch $LOGERR
exec 7>&2           # Link file descriptor #7 with stderr.
                    # Saves stderr.
exec 2> $LOGERR     # stderr replaced with file $LOGERR.

echo Backup of Files - $backup_target
echo ----------------------------------------------------------------------
echo Backup Start `date`
echo ----------------------------------------------------------------------


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

# copy files to the tmp directory before using tar
cp -r $backup_target $backup_dir/$archive_file

# backup the files using tar
cd $backup_dir 
tar -zcvf $backup_type/$file $archive_file || error 'failed to create $archive_file archive file'

# Cleanup
rm -rf $backup_dir/$archive_file || error 'failed to delete tmp directory'

# delete old files
find $backup_dir/daily/ -maxdepth 1 -mtime +$rotation_lookup -type f -exec rm -rv {} \; || error 'failed to delete daily archive file'
find $backup_dir/weekly/ -maxdepth 1 -mtime +$rotation_lookup -type f -exec rm -rv {} \; || error 'failed to create weekly archive file'
find $backup_dir/monthly/ -maxdepth 1 -mtime +$rotation_lookup -type f -exec rm -rv {} \; || error 'failed to create monthly archive file'

echo ----------------------------------------------------------------------
echo Backup End Time `date`
echo ----------------------------------------------------------------------

echo Total disk space used for backup storage.
echo Size - Location
echo `du -hs "$backup_dir"`
echo
echo ======================================================================

if [ $email_report -eq "1" ]; then
    if [ -s "$LOGERR" ]; then
        cat "$LOGERR" | mail -s "ERRORS REPORTED: Backup Log for $archive_file - $date" $mail_to
    else
        cat "$LOGFILE" | mail -s "Backup Log for $archive_file - $date" $mail_to
    fi
fi

STATUS=0
if [ -s "$LOGERR" ]; then
    STATUS=1
fi

# Clean up Logfile
if [ $cleanup_log -eq "1" ]; then
rm -f "$LOGFILE" "$LOGERR"
fi

exit $STATUS

