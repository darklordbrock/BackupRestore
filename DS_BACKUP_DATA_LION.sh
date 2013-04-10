#!/bin/bash

# OS X Lion Beta version. Needs testing. Please report bugs.
# rustymyers@gmail.com

# Script to backup home folders on volume before restoring disk image with DeployStudio
# Uses the directories in the /Users folder of the target machine to back up data, user account details, and password.
# Use accompanying ds_restore_data.sh to pur users and user folders back onto computer after re-imaging.

function help {
    cat<<EOF

    Usage: `basename $0` [ -e "guest admin shared" ] [ -v "/Volumes/Macintosh HD" ] [ -u /Users ] [ -d "/Volumes/External Drive/" ] [ -t tar ]
    Variables can be set in DeployStudio variables window when running script.
    BackupRestore Variables:
    -q Unique Identifier 
			Enter the MAC address of the backup you want to restore.
			For example, if you backup a computer and its MAC address
			was: 000000000001. You can then specify that MAC as the
			variable to restore to a different computer.
		 	Read Me has more information on its use.
	-c Remove User Cache
			Will delete the Users /Library/Cache
	 		folder before backing up the data.
    -e Users to Skip
            Must use quotes for multiple users
            Default is "guest" and "shared"
                You must specify "guest" and
                "shared" if your use the argument
    -v Target volume
            Specify full path to mount point of volume
            Default is the internal volume
            e.g. /Volumes/Macintosh HD
    -u User path on target
            Set to path of users on volume
            Default is /Users
    -d Backup destination
            Specify full path to the backup volume
            Default is /tmp/DSNetworkRepository
    -t Backup tool (tar) - Still working on this one!
            Select backup software, Default tar
            tar = Use tar with gzip to backup.
            ditto = Use ditto with gzip to backup
            rsync NOT WORKING, yet!
            -removed- rsync = Use rsync to backup
EOF

}

#Variables:
# Ignore these accounts or folders in /Users (use lowercase):
# Shared folder is excluded using "shared"
export EXCLUDE=( "shared" "guest" "deleted users" "ladmin" )
# Unique ID for plist and common variable for scripts
export UNIQUE_ID=`echo "$DS_PRIMARY_MAC_ADDRESS"|tr -d ':'` 
# Add Times? UNIQUE_ID=`date "+%Y%m%d%S"`
# Should we remove users cache folder? 1 = yes, 0 = no. Set to 0 by default.
export RMCache="1"
# DS Script to backup user data with tar to Backups folder on repository.
export DS_REPOSITORY_BACKUPS="$DS_REPOSITORY_PATH/Backups/$UNIQUE_ID"
# Set Path to internal drive
export DS_INTERNAL_DRIVE=`system_profiler SPSerialATADataType|awk -F': ' '/Mount Point/ { print $2}'|head -n1`
# Set Path to the folder with home folders
export DS_USER_PATH="/Users"
# Default backup tool
export BACKUP_TOOL="tar"

# Parse command line arguments
while getopts :e:q:cv:u:d:t:h opt; do
	case "$opt" in
		e) EXCLUDE="$OPTARG";;
		q) UNIQUE_ID="$OPTARG";;
		c) RMCache="1";;
		v) DS_INTERNAL_DRIVE="$OPTARG";;
		u) DS_USER_PATH="$OPTARG";;
		d) DS_REPOSITORY_BACKUPS="$OPTARG/Backups/$UNIQUE_ID";;
		t) BACKUP_TOOL="$OPTARG";;
		h) 
			help
			exit 0;;
		\?)
			echo "Usage: `basename $0` [-e Excluded Users] [-v Target Volume] [-u User Path] [-d Destination Volume] [ -t Backup Tool ]"
			echo "For more help, run: `basename $0` -h"
			exit 0;;
	esac
done
shift `expr $OPTIND - 1`

# Set variables that are dependent on getopts
# Set path to dscl
export dscl="$DS_INTERNAL_DRIVE/usr/bin/dscl"
# Internal drive's directory node
export INTERNAL_DN="$DS_INTERNAL_DRIVE/var/db/dslocal/nodes/Default"

# Prints variables in the log. Great for troubleshooting. 		
echo -e "## Backup Arguments"
echo -e "# Unique ID:					$UNIQUE_ID"
echo -e "# Remove User Cache:			$RMCache"
echo -e "# Excluded users:				${EXCLUDE[@]}"
echo -e "# Target Volume:				$DS_INTERNAL_DRIVE"
echo -e "# User Path on target:			$DS_USER_PATH"
echo -e "# DS Repo: 					$DS_REPOSITORY_PATH"
echo -e "# Backup Path:					$DS_REPOSITORY_BACKUPS"
echo -e "# Backup tool:				$BACKUP_TOOL"
echo -e "# dscl path:					$dscl"
echo -e "# Internal Directory:			$INTERNAL_DN"

function RUNTIME_ABORT {
# Usage:
# argument 1 is error message
# argument 2 is success message
if [ "${?}" -ne 0 ]; then
	echo "RuntimeAbortWorkflow: $1...exiting."
	exit 1
else
	echo -e "\t$2"
fi
}

echo "educ_backup_data.sh - v0.7.2 (Lion) beta ("`date`")"

# Check to see if the drive is encrypted. If it is stop the backup script. Script taken from rtrouton.
CORESTORAGESTATUS="/private/tmp/corestorage.txt"
ENCRYPTSTATUS="/private/tmp/encrypt_status.txt"
ENCRYPTDIRECTION="/private/tmp/encrypt_direction.txt"
DEVICE_COUNT=`diskutil cs list | grep -E "^CoreStorage logical volume groups" | awk '{print $5}' | sed -e's/(//'`
EGREP_STRING=""
if [ "$DEVICE_COUNT" != "1" ]; then
  EGREP_STRING="^\| *"
fi
osversionlong=`sw_vers -productVersion`
osvers=${osversionlong:3:1}
CONTEXT=`diskutil cs list | grep -E "$EGREP_STRING\Encryption Context" | sed -e's/\|//' | awk '{print $3}'`
ENCRYPTIONEXTENTS=`diskutil cs list | grep -E "$EGREP_STRING\Has Encrypted Extents" | sed -e's/\|//' | awk '{print $4}'`
ENCRYPTION=`diskutil cs list | grep -E "$EGREP_STRING\Encryption Type" | sed -e's/\|//' | awk '{print $3}'`
CONVERTED=`diskutil cs list | grep -E "$EGREP_STRING\Size \(Converted\)" | sed -e's/\|//' | awk '{print $5, $6}'`
SIZE=`diskutil cs list | grep -E "$EGREP_STRING\Size \(Total\)" | sed -e's/\|//' | awk '{print $5, $6}'`

if [[ ${osvers} -ge 7 ]]; then
  diskutil cs list >> $CORESTORAGESTATUS
#10.7 checking of FileVault 2.
if grep -iE 'Logical Volume Family' $CORESTORAGESTATUS 1>/dev/null; then
      if [ "$CONTEXT" = "Present" ]; then
        if [ "$ENCRYPTION" = "AES-XTS" ]; then
	      diskutil cs list | grep -E "$EGREP_STRING\Conversion Status" | sed -e's/\|//' | awk '{print $3}' >> $ENCRYPTSTATUS
		    if grep -iE 'Complete' $ENCRYPTSTATUS 1>/dev/null; then 
		      echo "Drive is Encrypted"
			exit 1
            fi 
        fi
      fi  
fi
fi

# Check that the backups folder is there. 
# If its missing, make it.
if [[ ! -d "$DS_REPOSITORY_PATH/Backups" ]]; then
	mkdir -p "$DS_REPOSITORY_PATH/Backups"
fi
# Check that the computer has a backup folder.
# If its missing, make it.
if [[ ! -d "$DS_REPOSITORY_PATH/Backups/$UNIQUE_ID" ]]; then
	mkdir -p "$DS_REPOSITORY_PATH/Backups/$UNIQUE_ID"
fi

# Start script...
echo "Scanning Users folder..."

# List users on the computer
for i in "$DS_INTERNAL_DRIVE""$DS_USER_PATH"/*/;
do
	echo -e ""
	# Change the account name to lowercase
    USERZ=$(basename "$i"| tr '[:upper:]' '[:lower:]');
    # Set keep variable
	keep=1;
    for x in "${EXCLUDE[@]}";
    do
        [[ $x = $USERZ ]] && keep=0;

    done;
    if (( $keep )); then
		echo "<>Backing up $USERZ to $DS_REPOSITORY_BACKUPS"
		# Backup user account to computer's folder
		DS_BACKUP="$DS_INTERNAL_DRIVE$DS_USER_PATH/$USERZ"
		DS_ARCHIVE="$DS_REPOSITORY_BACKUPS/$USERZ-HOME"
		
		# Remove users cache? If set to 1, then yes.
		if [[ $RMCache = 1 ]]; then
			# Remove users home folder cache
			echo -e "\t-Removing user cache..."
			rm -rfd "$DS_BACKUP/Library/Cache/"
			# Empty the trash as well
			echo -e "\t-Emptying user Trash..."
			rm -rfd "$DS_BACKUP/.Trash/*"
		fi

		case $BACKUP_TOOL in
			tar )
			# Backup users with tar
			/usr/bin/tar -czpf "$DS_ARCHIVE.tar" "$DS_BACKUP" &> /dev/null
			RUNTIME_ABORT "RuntimeAbortWorkflow: Error: could not back up home" "\t+Sucess: Home successfully backed up using tar"
				;;
			ditto ) ## Contributed by Miles Muri, Merci!
			echo -e "Backing up user home directory to $DS_ARCHIVE.zip"
			ditto -c -k --sequesterRsrc --keepParent "$DS_BACKUP" "$DS_ARCHIVE.zip" 
			RUNTIME_ABORT "RuntimeAbortWorkflow: Error: Could not back up home" "\t+Sucess: Home successfully backed up using ditto"
			 	;;
			* )
			echo "RuntimeAbortWorkflow: Backup Choice: $BACKUP_TOOL. Invalid flag, no such tool...exiting." 
			help
			exit 1
				;;
		esac
		# Log which tool was used to backup user
		/usr/libexec/PlistBuddy -c "add :backuptool string $BACKUP_TOOL" "$DS_REPOSITORY_BACKUPS/$USERZ.BACKUP.plist" &>/dev/null
		
		# Backup User Account
		if [[ ! `"$dscl" -f "$INTERNAL_DN" localonly -read "/Local/Target/Users/$USERZ" |grep -E "OriginalAuthenticationAuthority"` ]]; then #this is a local account
			echo -e "\t+Sucess: $USERZ is a Local account"
			# Perhaps All I need to do is backup the dslocal users plist?
			if [[ -e "${DS_INTERNAL_DRIVE}/var/db/dslocal/nodes/Default/users/$USERZ.plist" ]]; then
				cp -p "${DS_INTERNAL_DRIVE}/var/db/dslocal/nodes/Default/users/$USERZ.plist" "${DS_REPOSITORY_BACKUPS}/$USERZ.plist"
				RUNTIME_ABORT "RuntimeAbortWorkflow: Error: Could not back up user account" "\t+Sucess: User account successfully backed up"
			fi
		else
			echo -e "\t+Sucess: $USERZ is a Mobile account"
			echo -e "\t+Sucess: account excluded for mobile account"
			# User data backup plist
			DS_USER_BACKUP_PLIST="$DS_REPOSITORY_BACKUPS/$USERZ-NETUSER.plist"
		fi
	else 
		echo -e "<>Excluding $USERZ" 
		echo -e ""
	fi 
done

echo "educ_backup_data.sh - end"
exit 0