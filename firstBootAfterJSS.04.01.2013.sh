#!/bin/bash

######
# First boot script for JSS Production 
# After JSS QuickAdd is run. 
# Built on 03.27.2013
#
# Kyle Brockman
# While working at UW-Milwaukee
######

# Add the jssworker account to local UWM admin group
dscl . append /Groups/localuwmadmingroup GroupMembership "jss"

#check for JAMF binary 
if [[  -f /usr/sbin/jamf ]]; then
	echo "jamf binary is installed"
else
	echo "jamf binary is not installed."
	exit 1	
fi

#Set the department in JSS based on machine name
DEPT=`hostname | sed 's/-/ /g' | awk '{print $1}' | tr "a-z" "A-Z"`
echo "Setting Department to: " $DEPT
/usr/sbin/jamf recon -department $DEPT

#check for any jamf policies for the machine. 
echo "check for any jamf policies"
/usr/sbin/jamf policy
sleep 3

# Trigger manual Printer installs
/usr/sbin/jamf policy -trigger printdriverBrother
sleep 2
/usr/sbin/jamf policy -trigger printdriverCanon
sleep 2
/usr/sbin/jamf policy -trigger printdriverEpson
sleep 2
/usr/sbin/jamf policy -trigger printdriverFuji
sleep 2
/usr/sbin/jamf policy -trigger printdriverGestetner
sleep 2
/usr/sbin/jamf policy -trigger printdriverHP
sleep 2
/usr/sbin/jamf policy -trigger printdriverInfo
sleep 2
/usr/sbin/jamf policy -trigger printdriverInfoTec
sleep 2
/usr/sbin/jamf policy -trigger printdriverLanier
sleep 2
/usr/sbin/jamf policy -trigger printdriverLexmark
sleep 2
/usr/sbin/jamf policy -trigger printdriverNRG
sleep 2
/usr/sbin/jamf policy -trigger printdriverRicoh
sleep 2
/usr/sbin/jamf policy -trigger printdriverSamsung
sleep 2
/usr/sbin/jamf policy -trigger printdriverSavin
sleep 2
/usr/sbin/jamf policy -trigger printdriverXerox
sleep 2

# Restore user data from Shared dir if a backup is there

/usr/sbin/jamf policy -trigger homedirmigration

exit 0