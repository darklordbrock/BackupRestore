#!/bin/bash

export M="MacBackups"

export bkVolume="/tmp/$M"

export serial=`system_profiler | grep "Serial Number (system)" | awk '{print $4}'`

#Stop the machine from sleeping for 24 Hours
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
	mail -s "Restored Failed for `hostname` at `date "+%Y.%m.%d %H:%M:%S"`" ds-techs@uwm.edu ds-fte@uwm.edu <<EOF

	Hello,

	The restore for `hostname` failed. The Samba Shared did not mount. 

	Thank you,
	Backup Process.

EOF
	exit 1	
fi

######
#code to restore the user dirs
######

killall caffeinate

exit 0

