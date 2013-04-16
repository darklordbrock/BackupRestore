#!/bin/bash

# Set Path to internal drive
export DS_INTERNAL_DRIVE=`system_profiler SPSerialATADataType | awk -F': ' '/Mount Point/ { print $2}'|head -n1`

# Unique ID for plist and common variable for scripts
#export UNIQUE_ID=`echo "$DS_PRIMARY_MAC_ADDRESS"|tr -d ':'`


# DS Script to backup user data with tar to Backups folder on repository.
#export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$input_variable"

#sets path to CocoaDialog
CD="$HOME/CocoaDialog.app/Contents/MacOS/CocoaDialog"

ui=`$CD standard-inputbox --title "Please Enter a Value" \
--informative-text "Please enter a Unique ID" \
--no-newline --float`

UNIQUE_ID=`echo $ui | awk '{ print $2 }'`

#Set Path to the shared folder
export DS_SHARED_PATH="/Users/Shared"

#This should copy the backups to the local drive's shared folder. 
#cp -R $DS_REPOSITORY_BACKUPS "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"

dropdown=`$CD standard-dropdown --title "Choose a Backup" --string-output --no-newline --text "Please choose a baskup to restore" --items "ls ~/Backup/" `

backup=`echo $dropdown | awk '{ print $2 }'`

if [ "$backup" = "$UNIQUE_ID" ]; then
	export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$rv"
	cp -R $DS_REPOSITORY_BACKUPS "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"
else
	echo "There is no match"
	exit 1
fi


exit 0