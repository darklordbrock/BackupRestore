#!/bin/bash

######
#
#
#
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
export DS_SHARED_PATH="/Shared"

#This should copy the backups to the local drive's shared folder. 
cp -R $DS_REPOSITORY_BACKUPS "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"

# Hashing the back up and what was copied to the machine.
#making a sha1 array for the backup files on the server
openssl sha1 $DS_REPOSITORY_BACKUPS/*
#making a sha1 array for the backup files on the Destination machine.
openssl sha1 "$DS_INTERNAL_DRIVE$DS_SHARED_PATH/"*

#Verify the sha1 array between the backup and Destination system, then deleting the backup on the server.

#In one of the frist boot scripts the files will be used to fill a person's homedir. 

exit 0