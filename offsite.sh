#! /bin/bash

# Copyright 2017 Jason Spohn 

## Define the location and name of the log files.
STATUS=/SCRIPTS/offsite_status.log
RUNNING=/SCRIPTS/offsite_running.log

##Rotate the logs.
function rotate {
if [ -s "$RUNNING" ]
	then mv offsite_running.log "`date`_offsite_running.log" ; 
	else touch $RUNNING
fi
if [ -s "$STATUS" ] 
	then mv offsite_status.log "`date`_offsite_status.log" ;
	else touch $STATUS
fi
find *.log -type f -mtime 7 | xargs rm -f
}

## Check to make sure the disk is not already present. If it is log it.
function run {
echo "STARTING SCRIPT @ `date`/n" >> $STATUS
if [ -d "/mnt/offsite/pc" ]
	then echo "`date` Disk was already mounted/present:" >> $STATUS ;
		echo `date` `df -h | grep sdd` >> $STATUS ; backup
	else echo "`date` No disk is present./n" >> $STATUS ; offsite1
fi
}

## Mount the disk and output if it was "OFFSITE1" or "OFFSITE2".
## NOTE: the disks labels are 'hard coded' into the script. Also, make sure you label the disks accrodingly. If no label is found, the script will default to /dev/sdd1 as its mount point.
function offsite1 {
mount -nf -L OFFSITE1 /mnt/offsite 2>/dev/null
if [ $? -eq 0 ]
        then mount -L OFFSITE1 /mnt/offsite
		echo "`date` Mounted disk: OFFSITE1" >> $STATUS ; backup
        else offsite2
fi
}
function offsite2 {
mount -nf -L OFFSITE2 /mnt/offsite 2>/dev/null
if [ $? -eq 0 ]
        then mount -L OFFSITE2 /mnt/offsite
		echo "`date` Mounted disk: OFFSITE2" >> $STATUS ; backup
        else offsite3
fi
}
function offsite3 {
mount -nf -L OFFSITE3 /mnt/offsite 2>/dev/null
if [ $? -eq 0 ]
	then mount -L OFFSITE3 /mnt/offsite
		echo "`date` Mounted disk: OFFSITE3" >> $STATUS ; backup
	else mount_generic 
fi
}
function mount_generic {
mount -nf /dev/sdd1 /mnt/offsite 2>/dev/null
if [ $? -eq 0 ]
        then mount /dev/sdd1 /mnt/offsite
		echo "`date` Mounted disk with no label:" >> $STATUS ; 
		echo `date` `df -h | grep sdd` >> $STATUS ; backup
        else echo "`date` Cannot mount any disks! Goodbye!" >> $STATUS ; exit 1
fi
}

## Perform backup.
function backup {
echo "
`date` Backup started"  >> $STATUS
echo "`date` START" >> $RUNNING
rsync -aHh --delete --stats "/var/lib/backuppc/" "/mnt/offsite/" >> $RUNNING
if [ $? -eq 0 ]
        then echo "`date` Backup was completed SUCCESSFULLY" >> $STATUS ;
		echo "`date` END" >> $RUNNING
        else echo "`date` BACKUP FAILED!" >> $STATUS
fi
}

## Sleep between running the backup and unmounting the disk.
function snooze {
sleep 400 #Use '5' for testing purposes; value should be '400'
}

## Unmount the disk.
function cleanup {
umount /mnt/offsite
if [ $? -eq 0 ]
	then echo "`date` Disk was unmounted SUCCESSFULLY" >> $STATUS
	else echo "`date` COULD NOT UNMOUNT DISK! It may be busy, attempting to unmount the disk lazy style!" >> $STATUS
fi
# Do a lazy unmount if the disk is busy.
# Note: There are some problems with this part of the script.
# 	The disk does not always umount even with the -l.
#	I am not sure why this is happening. 
if [ $? -ne 0 ]
	then sleep 400 ; umount -l /mnt/offsite # This sleep seems to fix the above noted problem. 
	else echo "`date` ALL DONE" >> $STATUS 
fi
if [ -d "/mnt/offsite/pc" ]
	then sleep 1200 ; umount /mnt/offsite
fi
if [ -d "/mnt/offsite/pc" ]
	then echo "`date` SOMETHING WENT WRONG! The directory is still present." >> $STATUS
fi
}

## End the script.
function end {
echo "
`date` SCRIPT FINISHED!" >> $STATUS
}

## Email the important parts of the logs to the admin.
function mail {
# Note: the addresses are hard coded into this area. 
tail -n 8 /SCRIPTS/offsite_status.log > email_log.temp
grep -i -e 'literal data' -e 'start' offsite_running.log  | tail -n1 >> email_log.temp
echo "
HERE ARE THE LOGS FOR THE NIGHTLY BACKUP:" >> email_log.temp
/usr/share/backuppc/bin/BackupPC_zcat /var/lib/backuppc/log/LOG.0.z | egrep -i 'computer01|computer02' >> email_log.temp 
egrep -i 'cpool|computer01' /var/lib/backuppc/log/LOG >> email_log.temp
/usr/sbin/ssmtp your@email.com < email_log.temp
# /usr/sbin/ssmtp your@email.com < email_log.temp 
rm email_log.temp
}

## Copy the configurations for the BackupPC server to: /mnt/offsite/config_backup/backuppc
function config_backup {
cp -r /etc/backuppc /mnt/offsite/config_backup/
}

## Run the script.
# rotate 		# This is not working correctly. So just comment it out.
run
config_backup
snooze
cleanup
end
mail
