#!/bin/bash
# Some of this script was taken from Rusty Meyers.

# Set Path to internal drive
export DS_INTERNAL_DRIVE=`system_profiler SPSerialATADataType | awk -F': ' '/Mount Point/ { print $2}'|head -n1`

# Unique ID for plist and common variable for scripts
export UNIQUE_ID=`echo "$DS_PRIMARY_MAC_ADDRESS"|tr -d ':'` # Add Times? UNIQUE_ID=`date "+%Y%m%d%S"`

# DS Script to backup user data with tar to Backups folder on repository.
export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$UNIQUE_ID"

# Set backup count to number of tar files in backup repository - Contributed by Rhon Fitzwater
# Updated grep contributed by Alan McSeveney <alan@themill.com>
# export DS_BACKUP_COUNT=`/bin/ls -l "$DS_REPOSITORY_BACKUPS" | grep -E '\.(tar|zip)$' | wc -l`
export DS_BACKUP_COUNT=`/bin/ls -l "$DS_REPOSITORY_BACKUPS" | grep -E '.*\.tar|.*\.zip' | wc -l`

# Set Path to the folder with home folders
export DS_USER_PATH="/Users"

while getopts :v:q:r:u:h opt; do
	case "$opt" in
		# e) EXCLUDE="$OPTARG";;
		v) DS_LAST_RESTORED_VOLUME="$OPTARG";;
		q) UNIQUE_ID="$OPTARG";;
		r) DS_REPOSITORY_PATH="$OPTARG/Backups/$UNIQUE_ID";;
		u) DS_USER_PATH="$OPTARG";;
		h) 
			help
			exit 0;;
		\?)
			echo "Usage: `basename $0` [-v Target Volume ] [-q MAC Address of target machine] [-r Backup Repository ]"
			echo "For more help, run: `basename $0` -h"
			exit 0;;
	esac
done
shift `expr $OPTIND - 1`

# Set path to dscl
#export dscl="$DS_LAST_RESTORED_VOLUME/usr/bin/dscl"
# Internal Drive directory node
#export INTERNAL_DN="$DS_LAST_RESTORED_VOLUME/var/db/dslocal/nodes/Default"

# Uncomment this section when you want to see the variables in the log. Great for troubleshooting. 
echo -e "# Restore Arguments"
echo -e "# Last Restored Volume:		$DS_LAST_RESTORED_VOLUME"
echo -e "# Unique ID:					$UNIQUE_ID"
echo -e "# User Path on target:			$DS_USER_PATH"
echo -e "# Restore Repository: 			$DS_REPOSITORY_PATH"
echo -e "# Internal Drive:				$DS_INTERNAL_DRIVE"
echo -e "# Backup Count:				$DS_BACKUP_COUNT"
echo -e "# dscl path:					$dscl"
echo -e "# Internal Directory:			$INTERNAL_DN"

# Check if any backups exist for this computer.  If not, exit cleanly. - Contributed by Rhon Fitzwater
if [ $DS_BACKUP_COUNT -lt 1 ] 
then
	echo -e "RuntimeAbortWorkflow: No backups for this computer exist";
	echo "restore.sh - end";
	exit 0;
fi

USERZ=`echo $(basename $i)|awk -F'-' '{print $1}'`

#Having problems with this line below... It cannot find the $USERZ.BACKUP.plist but I've verified that it is there.
RESTORE_TOOL=`"$DS_INTERNAL_DRIVE/usr/libexec/PlistBuddy" -c "print :backuptool" "$DS_REPOSITORY_BACKUPS/$USERZ.BACKUP.plist"`
echo " >Restoring $USERZ user directory with $RESTORE_TOOL"
case $RESTORE_TOOL in
	tar )
		for i in "$DS_REPOSITORY_BACKUPS"/*HOME.tar; do
			USERZ=`echo $(basename $i)|awk -F'_' '{print $1}'`
			echo " >>Restore From: $i Restore To: ~/Users/Shared"
			/usr/bin/tar -xf "$i" -C "~/Users/Shared" --strip-components=3 --keep-newer-files
			RUNTIME_ABORT "RuntimeAbortWorkflow: Could not restore home folder for $USERZ using tar...exiting." "\t +home restored successfully"
		done
esac


exit 0