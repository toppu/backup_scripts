#!/bin/bash
#
# script to backup Mongo database
# version 0.1
# 2014-10-31
#
# keep backup daily (last 7 days), weekly (last 5 weeks) and monthly

##################################
# Start configuration
##################################

#-----------------------
# Mongo settings
#-----------------------

# connectivity cedentials (if authentication is on)
MONGO_USER=""
MONGO_PASSWD=""

# server information
MONGO_HOST=""
MONGO_PORT=""

# database name
MONGO_DB=""

#-----------------------
# Email settings
#-----------------------

# send success or failure e-mails with details.
EMAIL_REPORT="1"

# email address to send mail to 
MAIL_TO=""

#-----------------------
# General settings
#-----------------------

# backup directory
BACKUP_DIR="/backups/mongodb"

# choose compression type. (gzip or bzip2)
COMPRESS="gzip"

# if the compressed folder should be deleted after compression has compressed
CLEANUP_COMP="1"

# if the loggile should be deleted
CLEANUP_LOG="1"

# which day do you do weekly backups (1 to 7 where 1 is Monday)
DOWEEKLY=5

##################################
# End configuration
##################################



##################################
# Start script
##################################
#PATH=/usr/local/bin:/usr/bin:/bin
DATE=`date +%Y-%m-%d_%Hh%Mm`                      # Datestamp e.g 2002-09-21
DOW=`date +%A`                                    # Day of the week e.g. Monday
DNOW=`date +%u`                                   # Day number of the week 1 to 7 where 1 represents Monday
DOM=`date +%d`                                    # Date of the Month e.g. 27
M=`date +%B`                                      # Month e.g January
W=`date +%V`                                      # Week Number e.g 37
LOGFILE=$BACKUPDIR/$DBHOST-`date +%H%M`.log       # Logfile Name
LOGERR=$BACKUP_DIR/ERRORS_$MONGO_HOST-`date +%H%M`.log # Logfile Name
OPT=""                                            # OPT string for use with mongodump
export LC_ALL=C

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

#
# dump database using mongodump
#
function do_backup () {
    mongodump --host $MONGO_HOST --port $MONGO_PORT --out=$1 $OPT
    [ -e "$1" ] && return 0
    echo "ERROR: mongodump failed to create backup: $1" >&2
    return 1
}

#
# compression
#
function do_compress () {
    SUFFIX=""
    dir=$(dirname $1)
    file=$(basename $1)
    if [ -n "$COMPRESS" ]; then
        [ "$COMPRESS" = "gzip" ] && SUFFIX=".tgz"
        [ "$COMPRESS" = "bzip2" ] && SUFFIX=".tar.bz2"
        echo Tar and $COMPRESS to "$file$SUFFIX"
        cd "$dir" && tar -cf - "$file" | $COMPRESS -c > "$file$SUFFIX"
        cd - >/dev/null || return 1
    else
        echo "No compression option set!"
    fi
 
    if [ $CLEANUP_COMP -eq "1" ]; then
        echo Cleaning up folder at "$1"
        rm -rf "$1"
    fi

    return 0
}

# need to use a username/password?
if [ "$MONGO_USER" ]; then
    OPT="$OPT --username=$MONGO_USER --password=$MONGO_PASSWD --db=$MONGO_DB"
fi

# create required directories
mkdir -p $BACKUP_DIR/{daily,weekly,monthly} || error 'failed to create $BACKUP_DIR directories'

# IO redirection for logging.
touch $LOGFILE
exec 6>&1           # Link file descriptor #6 with stdout.
                    # Saves stdout.
exec > $LOGFILE     # stdout replaced with file $LOGFILE.

touch $LOGERR
exec 7>&2           # Link file descriptor #7 with stderr.
                    # Saves stderr.
exec 2> $LOGERR     # stderr replaced with file $LOGERR.

echo Backup of Database Server - $HOST on $MONGO_HOST
echo ----------------------------------------------------------------------
echo Backup Start `date`
echo ----------------------------------------------------------------------

# monthly backup
if [ $DOM = "01" ]; then
    echo Monthly Backup
    FILE="$BACKUP_DIR/monthly/$DATE.$M"

# weekly backup
elif [ $DNOW = $DOWEEKLY ]; then
    echo Weekly Backup
    echo
    echo Rotating 5 weeks Backups...
    if [ "$W" -le 05 ]; then
        REMW=`expr 48 + $W`
    elif [ "$W" -lt 15 ]; then
        REMW=0`expr $W - 5`
    else
        REMW=`expr $W - 5`
    fi
    rm -f $BACKUP_DIR/weekly/week.$REMW.*
    echo
    FILE="$BACKUP_DIR/weekly/week.$W.$DATE"

# daily backup
else
    echo Daily Backup
    echo Rotating last weeks Backup...
    echo
    rm -f $BACKUP_DIR/daily/*.$DOW.*
    echo
    FILE="$BACKUP_DIR/daily/$DATE.$DOW"
fi

# call a function to dump and compress database
do_backup $FILE && do_compress $FILE

echo ----------------------------------------------------------------------
echo Backup End Time `date`
echo ----------------------------------------------------------------------

echo Total disk space used for backup storage.
echo Size - Location
echo `du -hs "$BACKUP_DIR"`
echo
echo ======================================================================

if [ $EMAIL_REPORT -eq "1" ]; then
    if [ -s "$LOGERR" ]; then
        cat "$LOGERR" | mail -s "ERRORS REPORTED: Mongo Backup Log for $MONGO_HOST - $DATE" $MAIL_TO
    else
        cat "$LOGFILE" | mail -s "Mongo Backup Log for $MONGO_HOST - $DATE" $MAIL_TO
    fi
fi

STATUS=0
if [ -s "$LOGERR" ]; then
    STATUS=1
fi

# Clean up Logfile
if [ $CLEANUP_LOG -eq "1" ]; then
rm -f "$LOGFILE" "$LOGERR"
fi

exit $STATUS

##################################
# End script
##################################
