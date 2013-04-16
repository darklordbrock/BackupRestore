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

# Enter unique_id that is in DeployStudio.
echo "Please enter some input: "
read input_variable
echo "You entered: $input_variable"

if [ "$input_variable" = "$UNIQUE_ID" ]; then
	export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$input_variable"
	cp -R $DS_REPOSITORY_BACKUPS "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"
else
	echo "The is no match"
	exit 1
fi


exit 0