#!/bin/bash

## OFFSITE RSYNC SCRIPT
##---------------------------------------------------------------------
## This script copies over the complete dataset of the backuppc 
## server (\\ubuntu-02) and should be run on that server. It will
## copy the dataset over to the offsite server (\\atari911-offsite)
##
## The main thing here is that the \\ubuntu-02 server initiates the
## transfer and not the offsite machine allowing for the change of 
## this script to point to a new/different offsite server if need be. 
## 

## VARIABLES
##---------------------------------------------------------------------
LOGFILE=/home/atari911/logfileOffsite.log
ARCHIVE=/home/atari911/offsitelogs/
DEBUG=/home/atari911/offsitelogs/debug.log
OFFSTSRVR="atari911-offsite.spohnhome.com"
EMAILLOG=/home/atari911/offsitelogs/email.log

## CREATE LOG FILE
##---------------------------------------------------------------------
function logrotate {
if [ -d "$ARCHIVE" ]
        then echo "`date` Rotating Logs.../n" >> $DEBUG
        else mkdir $ARCHIVE
fi

if [ -a "$LOGFILE" ]
        then mv $LOGFILE "$ARCHIVE`date`_offsiteLogs.old"
           touch $LOGFILE ;
        else touch $LOGFILE

}

## CHECK TO SEE IF THE SERVER IS AVAILABLE
##---------------------------------------------------------------------
function ping {
count=$9 ping -c 1 $OFFSTSRVR | grep icmp* | wc -l )
 if [ $count -eq 0 ]
		then echo "`date` Could not ping the offsite server!/n" >> $DEBUG
		else echo "`date` Found the offsite server... Proceeding./n" >> $DEBUG ; run
}

## FUNCTION TO RUN THE BACKUPS
##---------------------------------------------------------------------
## This is the function that gets called if the ping succeeds in the 
## 'ping' function. Basically this runs the content below this area.
## Everything above this function should be logging and debugging only.
function run {
etc
varlib
email

}

## TRANSFER OF THE BACKUPPC CONFIGURATION DIRECTORY TO OFFSITE
##---------------------------------------------------------------------
## Experamental but implemented transfer of the configuration files for
## hosts so that they show up in 'backuppc' running on server 
## \\atari911-offsite. 
## Notice the excludes! The 'htpasswd' is especially important
## as the web server authentication will break (user backuppc logging)
## into the server via the CGI interface) because the hash will be 
## different. The 'config.pl' file is also important as there is a 
## change made in the config on the offsite side that tells the server
## not to actually do backups of clients while maintaining the usefull
## ability to do restores directly from the offsite server. 
function etc {
rsync -ahH -z --delete -og --stats --exclude 'config.pl' --exclude 'htpasswd' --chown=backuppc:backuppc /etc/backuppc/ backuppc@atari911-offsite:/etc/backuppc/ >> $LOGFILE

}

## TRANSFER THE ACTUAL DATA TO OFFSITE
##--------------------------------------------------------------------- 
## The main command that will run the backup to \\atari911-offsite.
## Note:
## --chown - This arg is used to maintain the user:group on the offsite
## server side, otherwise the UID of the user:group can be mis-applied
## if the numbers are doifferent on the different server.
function varlib {
rsync -ahH -z --delete -og --stats --chown=backuppc:backuppc /var/lib/backuppc/ backuppc@atari911-offiste:/var/lib/backuppc/ >> $LOGFILE

}

## EMAIL LOGS
##---------------------------------------------------------------------
function email{
echo "Here are the logs for the offsite backup:/n" >> $EMAILLOG
/usr/sbin/ssmtp atari911@gmail.com < $EMAILLOG

}

## OTHER ISSUES THAT NEED TO BE ADDRESSED
##=====================================================================

## ISSUE USING 'sudo'
##---------------------------------------------------------------------
## There were problems with running this with sudo which where solved
## by running the script in a crontab which runs as root. 
## Howerver, I still added '/usr/bin/rsync' to reqire no password so
## that I can run the command locally using sudo without a password.

## CERTIFICATE USAGE AND SSH OVER RSYNC
##---------------------------------------------------------------------
## For some reson I am having trouble with getting the certificate 
## based SSH authentication to work when running SSH through the rsync 
## command. When I attempt to log into the machine using the same user 
## (backuppc), I am able to SSH into the machine no problem without the
## need for a password.

