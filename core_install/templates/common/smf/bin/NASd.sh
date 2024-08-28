#!/bin/bash
# ********************************************************************
# Ericsson Radio Systems AB                                     SCRIPT
# ********************************************************************
#
#
# (c) Ericsson Radio Systems AB 2018 - All rights reserved.
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
# Name    : NASd.sh
# Date    : 24/07/2023
# Revision: main\5
# Purpose : SYSTEMD Methods script to start and stop the NAS Monitor demon
#			This script is called by the relevant SYSTEMD service
#			files during start/stop phase.
#
# ********************************************************************
#
# 		Command Section
#
# ********************************************************************
AWK=/usr/bin/awk
BASENAME=/usr/bin/basename
CAT=/usr/bin/cat
CP=/usr/bin/cp
CUT=/usr/bin/cut
DATE=/usr/bin/date
DIRNAME=/usr/bin/dirname
ECHO=/usr/bin/echo
EGREP=/usr/bin/egrep
FIND=/usr/bin/find
GETENT=/usr/bin/getent
GREP=/usr/bin/grep
HEAD=/usr/bin/head
ID=/usr/bin/id
KILL=/usr/bin/kill
MKDIR=/usr/bin/mkdir
MV=/usr/bin/mv
PS=/usr/bin/ps
RM=/usr/bin/rm
SED=/usr/bin/sed
SYSTEMCTL=/usr/bin/systemctl
TOUCH=/usr/bin/touch
UNAME=/usr/bin/uname

# ********************************************************************
#
#       Configuration Section
#
# ********************************************************************
#

# The NAS milestone.
NAS_online_FMRI="NAS-online.service"

#The NASd Storage.
NASD="NASd.service"

# The NASd Monitor script
NAS_Monitor="/eniq/smf/nasd/NAS_Monitor.bsh"

# ********************************************************************
#
# 		Functions
#
# ********************************************************************
#
### Function: disable_NAS_milestone ###
#
# Stops the NAS milestone so that all services with a dependency on having
# the NAS filesystems available are stopped.
#
disable_NAS_milestone()
{
# The first thing this must always do is to stop NAS-online.service.
# If this is startup then NAS-online must be stopped.
# The NASd Monitor script will start it when its ready.
# If someone manually enabled NAS-online then we must disable it,
# it has a dependency on this NASd and NASd will start it when its ready.

${SYSTEMCTL} stop ${NAS_online_FMRI}

_service_state=`$SYSTEMCTL show ${NAS_online_FMRI} -p ActiveState | $AWK -F= '{print $2}'`
	if [ "${_service_state}" == "inactive" ] ; then
		$ECHO " $_service_state state set correctly for ${NAS_online_FMRI}"
	else
		$ECHO " Failed to set inactive state for ${NAS_online_FMRI}"
    fi

${SYSTEMCTL} disable ${NAS_online_FMRI}

	if [ $? -eq 0 ]; then
		$ECHO "INFO:: successfully disabled ${NAS_online_FMRI} service"
	else
		$ECHO "ERROR:: Unable to disabled ${NAS_online_FMRI} service"
	fi
}

### Function: restart_NASd ###
#
# Sends a reset SIGNAL to the NASd service.
# The NAS_Monitor script traps the user signal USR1 as a reset.
#
restart_NASd()
{
NAS_Monitor_pid=""
# We shouldn't need to disable the NAS milestone for a reset of the NASd.
# The NASd can restart it if required.

NAS_Monitor_pid=`${PS} -eaf|$GREP -vw grep|$GREP -w ${NAS_Monitor}|$AWK '{print $2}'`
if [ -z ${NAS_Monitor_pid} ]; then
    # The NAS_Monitor script defined the user SIG "USR1" as a reset.
    # It will trap for this and call a reset function.
    $KILL -USR1 ${NAS_Monitor_pid}
fi
}

### Function: start_NASd ###
#
# Starts the NASd service that monitors and mounts the NAS filesystems
#
start_NASd()
{
disable_NAS_milestone

if [ -s ${NAS_Monitor} ]; then
    ${NAS_Monitor} &
fi
}

### Function: stop_NASd ###
#
# Stops the NASd service that monitors and mounts the NAS filesystems
#
stop_NASd()
{
disable_NAS_milestone
NAS_Monitor_pid=""

NAS_Monitor_pid=`${PS} -eaf|$GREP -vw grep|$GREP -w ${NAS_Monitor}|$AWK '{print $2}'`
if [ ! -z ${NAS_Monitor_pid} ]; then
	# The NAS_Monitor script defines the user SIG "USR2" as a TERMINATE
	# It will trap for this and call a terminate function.
	$KILL -USR2 ${NAS_Monitor_pid}
	
	${SYSTEMCTL} reset-failed ${NASD}
	
	${SYSTEMCTL} disable ${NASD}
	
	if [ $? -eq 0 ]; then
		$ECHO "INFO:: successfully disabled ${NASD} service"
	else
		$ECHO "ERROR:: Unable to disabled ${NASD} service"
	fi
	
else
	$ECHO "WARNING: Unable to get ProcessID for NASd"
fi
}

### Function: usage ###
#
# Displays the usage message.
#
usage()
{
$ECHO "
`$BASENAME $0` -a start|stop|restart
    NASd SYSTEMD method script handling the starting of the NASd services
    during Linux start/stop. This script is called by the relevant
    SYSTEMD service files during start/stop phases.
"
}

# ***********************************************************************
#
#                    Main body of program
#
# ***********************************************************************
#

while getopts ":a:" arg; do
    case $arg in
        a) 	NASd_ACTION="$OPTARG"
       	    ;;
        \?) usage
		    exit 1
       	    ;;
    esac
done
shift `expr $OPTIND - 1`

if [ ! "${NASd_ACTION}" ]; then
    usage
    exit 1
fi

case "${NASd_ACTION}" in
     start) start_NASd
    	    ;;

      stop) stop_NASd
    	    ;;

   restart) restart_NASd
    	    ;;

         *) # SHOULD NOT GET HERE
         	usage
         	exit 1
       	    ;;
esac

exit 0

