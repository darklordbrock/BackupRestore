#!/bin/bash

###
#Script Designed by Ian Gunther and Kyle Brockman
#While working at the University of Wisconsin-Milwaukee
###

if [ "$(whoami)" != "root" ]; then
	echo "Sorry, you are not root."
	exit 1
fi

export TIME=`date "+%Y.%m.%d"`

export FULLTIME=`date "+%Y.%m.%d %H:%M:%S"`

export M="MacBackups"

export bkVolume="/tmp/$M"

export serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`

export BACKUP=$TIME-$serial-`hostname`

# Determine OS version
osvers=$(sw_vers -productVersion | awk -F. '{print $2}')
sw_vers=$(sw_vers -productVersion)

if [[ ${osvers} -ge 9 ]]; then
	if [[ ${sw_vers} = "10.9" ]]; then
		echo "[default]" >> /etc/nsmb.conf ; echo "smb_neg=smb1_only" >> /etc/nsmb.conf
	elif [[ ${sw_vers} = "10.9.1" ]]; then
		echo "test 10.9.1"
		exit 1
	fi
else
	echo "not os 10.9"
fi

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
hdiutil create $bkVolume/AutoDelete/$BACKUP.dmg -format UDBZ -nocrossdev -srcfolder /

#scan the image for restore
asr imagescan --source $bkVolume/$BACKUP --verbose

#check the backup
hdiutil verify $bkVolume/AutoDelete/$BACKUP.dmg

if [[ $? == 0 ]]; then
	echo "Backup is good"
	
	#Email Techs the backup is completed 
	mail -s "Backup Complete for `hostname` at `date "+%Y.%m.%d %H:%M:%S"`" ds-techs@uwm.edu ds-fte@uwm.edu <<EOF

	Hello,

	The backup for `hostname` is complete and ready to be picked up to be re-imaged.

	It started at `echo $FULLTIME` and ended at `date "+%Y.%m.%d %H:%M:%S"`.

	Total backup size is `ls -lah /tmp/MacBackups/AutoDelete/$BACKUP.dmg | awk '{ print $5 }'`.

	Thank you,
	Backup Process.

EOF
	
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

#Allow the machine to sleep again
killall caffeinate

exit 0