#!/bin/bash

# Set Path to internal drive
export DS_INTERNAL_DRIVE=`system_profiler SPSerialATADataType | awk -F': ' '/Mount Point/ { print $2}'|head -n1`

# Unique ID for plist and common variable for scripts
export UNIQUE_ID=`echo "$DS_PRIMARY_MAC_ADDRESS"|tr -d ':'`


# DS Script to backup user data with tar to Backups folder on repository.
#export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$input_variable"

#Set Path to the shared folder
export DS_SHARED_PATH="/Users/Shared"

#This should copy the backups to the local drive's shared folder. 
#cp -R $DS_REPOSITORY_BACKUPS "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"

#sets path to CocoaDialog
CD="$HOME/Applications/CocoaDialog.app/Contents/MacOS/CocoaDialog"

### Example 1
rv=`$CD ok-msgbox --text "Please input the Unique ID for the Restore" \
--informative-text "(Yes, the message was to inform you about itself)" \
--no-newline --float`

if [ "$rv" = "$UNIQUE_ID" ]; then
	export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$rv"
	cp -R $DS_REPOSITORY_BACKUPS "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"
else
	echo "The is no match"
	exit 1
fi


exit 0