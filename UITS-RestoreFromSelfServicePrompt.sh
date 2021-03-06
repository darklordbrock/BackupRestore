#!/bin/bash

export M="MacBackups"

export bkVolume="/tmp/$M"

export serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`

export restore="/tmp/restore"

CD="/Applications/Utilities/CocoaDialog.app/Contents/MacOS/CocoaDialog"

#Stop the machine from sleeping
caffeinate &

#Make the mount point if it does not already present.
if [[ ! -d "$bkVolume" ]]; then
	mkdir $bkVolume
fi

#Umount anything that might be mounted to the backup point 
umount $bkVolume

sleep 2

#mount the backup share
mount_smbfs //server.local/$M $bkVolume

sleep 3


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

#####
#check if connected to AD
#####

ADWORK=`id brockma9`
if [[ "$ADWORK" == "id: brockma9: no such user" ]]; then

    echo "This machine is not connected to AD"
	
    exit 1
else
	
    echo "Connected to AD and moving on. Nothing to see here, move along."

fi

#####
#end of check if connected to AD
#####

######
#code to restore the user dirs
######

mkdir $restore

BackupList=`ls $bkVolume/AutoDelete/ | grep -v ".DS_Store"`

dropdown=`$CD standard-dropdown --title "Choose a Backup" --string-output --no-newline --text "Please choose a baskup to restore" --items $BackupList`

pickBK=`echo $dropdown | awk '{ print $2 }'`

echo $pickBK

#attach the backup
hdiutil attach $bkVolume/AutoDelete/$pickBK -mountpoint $restore



USERZ=`ls $restore/Users/ | grep -v ".localized" | grep -v "ladmin" | grep -v "Shared"`

for U in $USERZ; do
	#Making the new home folder for the AD user account
	/System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n $U
	/usr/sbin/createhomedir -c -u $U
	sleep 2
	
	if [[ ! -d "/Users/$U" ]]; then
		echo "Home Directory failed to be made."
		exit 1
	else
		
		#copy the files to the new home folder 
		cp -Rfp $restore/Users/$U/* /Users/$U/
		
		#Set Permissions on the home folders
		#sets owner and group to user and staff
		chown -R $U:staff /Users/$U
		#sets the folder to let the staff users in but no access
		chmod 740 /Users/$U
		#sets the user to have full access to the home dir and no one else.
		chmod -R 700 /Users/$U/*
		#Access to the public folder
		chmod 777 /Users/$U/Public 
	fi		
done	

hdiutil detach $restore

######
#code of code to restore the user dirs
######

#reset the autodelete. 
touch $bkVolume/AutoDelete/$pickBK

#allow the machine to sleep again
killall caffeinate

exit 0