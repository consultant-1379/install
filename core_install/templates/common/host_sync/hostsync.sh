#!/bin/bash
# ********************************************************************
# Ericsson Radio Systems AB                                     SCRIPT
# ********************************************************************
#
#
# (c) Ericsson Radio Systems AB 2010 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Radio Systems AB, Sweden. The programs may be used
# and/or copied only with the written permission from Ericsson Radio
# Systems AB or in accordance with the terms and conditions stipulated
# in the agreement/contract under which the program(s) have been
# supplied.
#
#
# ********************************************************************
# Name    : hostsync.sh
# Date    : 24/07/2023
# Revision: main/5
# Purpose : Service Methods script to start and stop the service.
#			This script is called by the relevant Service Unit
#			files during start/stop phase.
#
# ********************************************************************
#
# 		Command Section
#
# ********************************************************************
AWK=/usr/bin/awk
BASENAME=/usr/bin/basename
ECHO=/usr/bin/echo
GREP=/usr/bin/grep
KILL=/usr/bin/kill
PS=/usr/bin/ps
# ********************************************************************
#
#       Configuration Section
#
# ********************************************************************
#
#The HostSync Service.
HOSTSYNC="hostsync.service"

# Script to monitor and update the local hosts file.
HOSTSYNC_MONITOR="/eniq/smf/bin/hostsync_monitor.bsh"

# ********************************************************************
#
# 		Functions
#
# ********************************************************************
#
### Function: restart_service ###
#
# Restarts the Service 
#
restart_service()
{
	_pid_=`${PS} -eaf|$GREP -vw grep|$GREP -w ${HOSTSYNC_MONITOR}|$AWK '{print $2}'`
	if [ "${_pid_}" ]; then
		$KILL -USR2 ${_pid_}
	fi

	if [ -s ${HOSTSYNC_MONITOR}  ]; then
		${HOSTSYNC_MONITOR} &
	else
		$ECHO "ERROR: Unable to locate start script for service ${HOSTSYNC_MONITOR}. "
		exit 1
	fi
}

### Function: start_service ###
#
# Starts the Service 
#
start_service()
{
if [ -s ${HOSTSYNC_MONITOR}  ]; then
	${HOSTSYNC_MONITOR} &
else
	$ECHO "ERROR: Unable to locate start script for service ${HOSTSYNC_MONITOR}. "
	exit 1
fi
}

### Function: stop_service ###
#
# Stops the Service 
#
stop_service()
{
_pid_=`$PS -eaf|$GREP -vw grep|$GREP -w ${HOSTSYNC_MONITOR}|$AWK '{print $2}'`
if [ "${_pid_}" ]; then
	# The Hostsync_Monitor script defines the user SIG "USR2" as a TERMINATE
	# It will trap for this and call a terminate function.
	$KILL -USR2 ${_pid_}
else
	$ECHO "WARNING: Unable to find PID for ${HOSTSYNC_MONITOR} service."
fi
}

usage()
{
	$ECHO "`$BASENAME $0` -a start|stop|restart "
}

# ***********************************************************************
#
#                    Main body of program
#
# ***********************************************************************
#

while getopts ":a:" arg; do
    case $arg in
        a) 	_ACTION="$OPTARG"
       	    ;;
        \?) usage
		    exit 1
       	    ;;
    esac
done
shift `expr $OPTIND - 1`

if [ ! "${_ACTION}" ]; then
    usage
    exit 1
fi


case "${_ACTION}" in
    start) start_service
    	    ;;

    restart) restart_service
    	    ;;

    stop) stop_service
    	    ;;

         *) # SHOULD NOT GET HERE
         	usage
         	exit 1
       	    ;;
esac
exit 0