#!/bin/bash

######
# First boot script for JSS Production 
# After JSS QuickAdd is run. 
# Built on 03.27.2013
# Updated on 2013.11.19
# 
# Kyle Brockman
# While working at UW-Milwaukee
######

#check for JAMF binary 
if [[  -f /usr/sbin/jamf ]]; then
	echo "jamf binary is installed"
else
	echo "jamf binary is not installed."
	exit 1	
fi

# Add the jssworker account to local UWM admin group
dscl . append /Groups/localuwmadmingroup GroupMembership "jss"

exit 0