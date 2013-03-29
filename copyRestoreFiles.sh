#!/bin/bash

######
#
# This script runs in DeployStudio. It is based off the Restore Scripts by Rusty Myers
# The backup tar files are copied from the server to the shared folder on the system being imaged. 
# In one of the first boot scripts the files will be used to fill a person's homedir. 
# The idea for this would be switch from local accounts to AD accounts, or the other way around 
#
# Writen By
# Kyle Brockman and Ashley Knowlesa
# While working for the Univerity of Wisconsin Milwaukee
######

# Set Path to internal drive
export DS_INTERNAL_DRIVE=`system_profiler SPSerialATADataType | awk -F': ' '/Mount Point/ { print $2}'|head -n1`

# Unique ID for plist and common variable for scripts
export UNIQUE_ID=`echo "$DS_PRIMARY_MAC_ADDRESS"|tr -d ':'` # Add Times? UNIQUE_ID=`date "+%Y%m%d%S"`

# DS Script to backup user data with tar to Backups folder on repository.
export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$UNIQUE_ID"

# Set Path to the folder with home folders
#export DS_USER_PATH="/Users"

#Set Path to the shared folder
export DS_SHARED_PATH="/Users/Shared"

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