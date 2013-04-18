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

#dropdown that lists all folders in the backup folder.
dropdown=`$CD standard-dropdown --title "Choose a Backup" --string-output --no-newline --text "Please choose a baskup to restore" --items $u `

#get the backup variable that is chosen.
backup=`echo $dropdown | awk '{ print $2 }'`

#This should set what the backup folder is so it can be copied.
export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$backup"
#This should copy the backups to the local drive's shared folder. 
cp -R $DS_REPOSITORY_BACKUPS "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"

exit 0