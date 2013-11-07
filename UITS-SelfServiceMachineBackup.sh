#!/bin/bash

###
#Script Designed by Ian Gunther and Kyle Brockman
#While working at the University of Wisconsin-Milwaukee
###

export TIME=`date "+%Y.%m.%d"`

export FULLTIME=`date "+%Y.%m.%d %H:%M:%S"`

export M="MacBackups"

export bkVolume="/tmp/$M"

export serial=`system_profiler | grep "Serial Number (system)" | awk '{print $4}'`

export BACKUP=$TIME-$serial-`hostname`

# create a named pipe
rm -f /tmp/hpipe
mkfifo /tmp/hpipe

# create a background job which takes its input from the named pipe
/Applications/Utilities/CocoaDialog.app/Contents/MacOS/CocoaDialog progressbar \
--indeterminate --title "Machine Backup For UITS Desktop Support" \
--text "Backing Up..." < /tmp/hpipe &

# associate file descriptor 3 with that pipe and send a character through the pipe
exec 3<> /tmp/hpipe
echo -n . >&3

#Stop the machine from sleeping
caffeinate &

#Make the mount point if it does not already present.
if [[ ! -d "$bkVolume" ]]; then
	mkdir $bkVolume
fi

#Umount anything that might be mounted to the backup point 
umount $bkVolume

sleep 10

#mount the backup share
mount_smbfs //server.local/$M $bkVolume

sleep 10


if mount | grep $bkVolume; then
	echo "SAMBA is Mounted"
else
	echo "Samba is NOT MOUNTED"
	# now turn off the progress bar by closing file descriptor 3
	exec 3>&-
	# wait for all background jobs to exit
	wait
	rm -f /tmp/hpipe
	exit 1
fi

#make the backup of the drive
hdiutil create $bkVolume/AutoDelete/$BACKUP.dmg -verbose -format UDBZ -nocrossdev -srcfolder /

#scan the image for restore
#asr imagescan --source $bkVolume/$BACKUP --verbose

#check the backup
hdiutil verify $bkVolume/AutoDelete/$BACKUP.dmg

if [[ $? == 0 ]]; then
	echo "Backup is good"
else
	mail -s "Backup Failed for `hostname` at `date "+%Y.%m.%d %H:%M:%S"`" ds-techs@uwm.edu ds-fte@uwm.edu <<EOF

	Hello,

	The backup for `hostname` failed.

	Thank you,
	Backup Process.

EOF

fi
# now turn off the progress bar by closing file descriptor 3
exec 3>&-

# wait for all background jobs to exit
rm -f /tmp/hpipe

#Email Techs the backup is completed 

mail -s "Backup Complete for `hostname` at `date "+%Y.%m.%d %H:%M:%S"`" ds-techs@uwm.edu ds-fte@uwm.edu <<EOF

Hello,

The backup for `hostname` is complete and ready to be picked up to be re-imaged.

It started at `echo $FULLTIME` and ended at `date "+%Y.%m.%d %H:%M:%S"`.

Total backup size is `ls -lah /tmp/MacBackups/AutoDelete/$BACKUP.dmg | awk '{ print $5 }'`.

Thank you,
Backup Process.

EOF

killall caffeinate

exit 0