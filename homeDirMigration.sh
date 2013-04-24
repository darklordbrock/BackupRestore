#!/bin/bash

BACKUP=`cat /private/var/db/.uitsRestoreID`

if [[ "$BACKUP" == "" ]]; then
	echo "No Backup to restore"
	exit 0
else
	
	#check if connected to AD
	ADWORK=`id brockma9`
	if [[ "$ADWORK" == "id: brockma9: no such user" ]]; then
		echo "This machine is not connected to AD"
		exit 1
	else
		echo "Connected to AD and moving on. Nothing to see here, move along."
	fi
	
	
	#Find the users that were on the machine
	USERZ=`ls /Users/Shared/$BACKUP/ | grep -v ".localized" | grep -v ".BACKUP.plist" | grep -v ".plist"  | sed 's/-HOME.tar//g'`

	for U in $USERZ; do
		#Making the new home folder for the AD user account
		/System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n $U
		/usr/sbin/createhomedir -c -u $U
		sleep 2
		
		if [[ ! -d "/Users/$U" ]]; then
			echo "Home Directory failed to be made."
			exit 1
		else
			#expand tar of the user to tmp
			mkdir /tmp/$U
			tar -xzf /Users/Shared/$BACKUP/$U-HOME.tar -C /tmp/$U
			
			#copy the files to the new home folder 
			FILEZ=`ls -a /tmp/$U/*/*/Users/$U/`
			for F in $FILEZ; do
				#Copy the files into the home dir
				cp -Rfp /tmp/$U/*/*/Users/$U/$F /Users/$U/
				#Security remove the files from the tmp location
				rm -fr /tmp/$U
			done
			
			#Set Permissions on the home folders
			for P in `ls /Users/ | grep -v Shared | grep -v localadmin` ; do
				#sets owner and group to user and staff
				chown -R $P:staff /Users/$P
				#sets the folder to let the staff users in but no access
				chmod 740 /Users/$P
				#sets the user to have full access to the home dir and no one else.
				chmod -R 700 /Users/$P/*
				#Access to the public folder
				chmod 777 /Users/$P/Public
			done 
 		fi		
		
	done	
	
fi

exit 0