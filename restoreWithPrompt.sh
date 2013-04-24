#!/bin/bash

# Set Path to internal drive
export DS_INTERNAL_DRIVE=`system_profiler SPSerialATADataType | awk -F': ' '/Mount Point/ { print $2}'|head -n1`

UNIQUE_ID=`echo $ui | awk '{ print $2 }'`

#Set Path to the shared folder
export DS_SHARED_PATH="/Users/Shared"

#sets path to CocoaDialog
CD="/Applications/Utilities/CocoaDialog.app/Contents/MacOS/CocoaDialog"

#sets path to the backup folder in deploystudio.
u=`ls $DS_REPOSITORY_PATH/Backups/ | grep -v ".DS_Store"`

#if for Macintosh HD check

if [ "${DS_INTERNAL_DRIVE}" == "/Volumes/Macintosh HD" ]; then
	echo $UNIQUE_ID > "/Volumes/Macintosh HD/private/var/db/.uitsRestoreID"
else
	exit 1
fi

#dropdown that lists all folders in the backup folder.
dropdown=`$CD standard-dropdown --title "Choose a Backup" --string-output --no-newline --text "Please choose a baskup to restore" --items $u `

#get the backup variable that is chosen.
restore=`echo $dropdown | awk '{ print $2 }'`

#This should set what the backup folder is so it can be copied.
export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$restore"
#This should copy the backups to the local drive's shared folder. 
cp -R $DS_REPOSITORY_BACKUPS "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"

# Declaring hash arrays so that the commands will run.
# Hashing the back up and what was copied to the machine.
#making a sha1 array for the backup files on the server
declare -a backup=("`openssl sha1 $DS_REPOSITORY_BACKUPS/*.tar | awk {'print $2'}`")
#making a sha1 array for the backup files on the Destination machine. The Need for print 3 is the space in the hard drive name.
declare -a internal=("`openssl sha1 "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"$UNIQUE_ID/*.tar | awk {'print $3'}`")

#Verify the sha1 array between the backup and Destination system, then deleting the backup on the server.
if [ "${backup}" == "${internal}" ]; then
	echo "There is a match"
	rm -fr $DS_REPOSITORY_BACKUPS/
	else
	echo "The backup files do not match what is on the computer. They have not been deleted."
fi

exit 0