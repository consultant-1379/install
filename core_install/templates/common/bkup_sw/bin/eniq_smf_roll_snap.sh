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
# ********************************************************************
# Name    : eniq_smf_roll_snap.bsh
# Date    : 06/12/2018
# Revision: C
# Purpose : Main wrapper script handling the starting of an ENIQ daemon
#           during Linux start/stop. This script is called by the relevant
#           Service unit files during start/stop phases
#
# Usage   : eniq_smf_roll_snap.bsh
#
# ********************************************************************
#
#       Command Section
#
# ********************************************************************
AWK=/usr/bin/awk
BASENAME=/usr/bin/basename
CAT=/usr/bin/cat
DIRNAME=/usr/bin/dirname
ECHO=/usr/bin/echo
EGREP=/usr/bin/egrep
GREP=/usr/bin/grep
ID=/usr/bin/id
KILL=/usr/bin/kill
LS=/usr/bin/ls
PS=/usr/bin/ps
RM=/usr/bin/rm
SLEEP=/usr/bin/sleep
SYSTEMCTL=/usr/bin/systemctl

# ********************************************************************
#
#       Configuration Section
#
# ********************************************************************

# This is the name of the ENIQ System User
DEFAULT_USER=root

ENIQ_ROLLSNAPD="/eniq/bkup_sw/bin/eniq_rollsnapd.bsh"
SVC="eniq-roll-snap.service"


# Shell scripts used to define Service Methods should include /lib/svc/share/smf_include.sh
# to gain access to convenience functions and return value definitions.
if [ -s /lib/svc/share/smf_include.sh ]; then
    . /lib/svc/share/smf_include.sh
fi

ENIQ_CONF_DIR=/eniq/installation/config
SMF_CONTRACT_INFO=/eniq/admin/etc/smf_contract_config

# ********************************************************************
#
#       functions
#
# ********************************************************************
### Function: abort_script ###
#
#   This will is called if the script is aborted thru an error
#   error signal sent by the kernel such as CTRL-C or if a serious
#   error is encountered during runtime
#
# Arguments:
#       $1 - Error message from part of program (Not always used)
# Return Values:
#       none
abort_script()
{
if [ "$1" ]; then
    _err_msg_=$1
else
    _err_msg_="Script aborted.......\n"
fi

$ECHO "\nERROR : $_err_msg_\n"

cd $SCRIPTHOME

if [ "$2" ]; then
    ${2}
else
   exit 1
fi
}

### Function: allowed_to_start ###
#
# Checks if this server is allowed to start this SMF Service.
# Checks the
# Checks this servers IP to see if it is allowed to start service.
#
allowed_to_start()
{
CURR_SERVER_TYPE=`$CAT $ENIQ_CONF_DIR/installed_server_type`

_enable_service_=`$CAT ${SMF_CONTRACT_INFO} | $EGREP ${CURR_SERVER_TYPE} | $EGREP "roll-snap" | $AWK -F"::" '{print $4}'`
if [ "${_enable_service_}" = "Y" ]; then
    return 0
else
    return 1
fi
}

### Function: check_id ###
#
#   Check that the effective id of the user is correct
#   If not print error msg and exit.
#
# Arguments:
#       $1 : User ID name
# Return Values:
#       none
check_id()
{
_check_id_=`$ID  | $AWK -F\( '{print $2}' | $AWK -F\) '{print $1}'`
if [ "$_check_id_" != "$1" ]; then
    _err_msg_="You must be $1 to execute this script."
    abort_script "$_err_msg_"
fi
}

### Function: get_absolute_path ###
#
# Determine absolute path to software
#
# Arguments:
#       none
# Return Values:
#       none
get_absolute_path()
{
_dir_=`$DIRNAME $0`
SCRIPTHOME=`cd $_dir_ 2>/dev/null && pwd || $ECHO $_dir_`
}

### Function: start_eniq_roll_snap ###
#
# Start the ENIQ roll_snap daemon
#
# Arguments:
#       none
# Return Values:
#       none
start_eniq_roll_snap()
{
if  allowed_to_start ; then
    ${ENIQ_ROLLSNAPD} &
else
        # The service should not start on this server. Disable smf sercive.
        $ECHO "INFO: Service should not be started on this server"
        $SYSTEMCTL disable ${SVC}
		$SYSTEMCTL stop ${SVC}
        $SLEEP 1
        exit 1
fi
}

### Function: stop_eniq_roll_snap ###
#
# Stop the ENIQ roll_snap daemon
#
# Arguments:
#       none
# Return Values:
#       none
stop_eniq_roll_snap()
{

_pid_=`${PS} -eaf | $GREP -vw grep | $GREP ${ENIQ_ROLLSNAPD} | $AWK '{print $2}'`
if [ "${_pid_}" ]; then
    $KILL ${_pid_}
    $SLEEP 3
    _pid_=`${PS} -eaf | $GREP -vw grep | $GREP ${ENIQ_ROLLSNAPD} | $AWK '{print $2}'`
    if [ "${_pid_}" ]; then
                $KILL -9 ${_pid_}
    fi
fi
}

# ********************************************************************
#
#       Main body of program
#
# ********************************************************************
#
# Determine absolute path to software
get_absolute_path

# Check that the effective id of the user is root
check_id ${DEFAULT_USER}

while getopts ":a:" arg; do
  case $arg in
    a) ENIQ_ACTION="$OPTARG"
       ;;
   \?) _err_msg_="`$BASENAME $0` -a [start|stop]"
       abort_script "$_err_msg_"
       ;;
  esac
done
shift `expr $OPTIND - 1`

if [ ! "${ENIQ_ACTION}" ]; then
    _err_msg_="`$BASENAME $0` -a [start|stop]"
    abort_script "$_err_msg_"
fi

if [ ! -s ${ENIQ_ROLLSNAPD} ]; then
    _err_msg_="${ENIQ_ROLLSNAPD} not found or empty"
    abort_script "$_err_msg_"
fi

if [ ! -x ${ENIQ_ROLLSNAPD} ]; then
    _err_msg_="${ENIQ_ROLLSNAPD} not executable"
    abort_script "$_err_msg_"
fi

case "${ENIQ_ACTION}" in
        start)  start_eniq_roll_snap
             ;;
        stop)  stop_eniq_roll_snap
             ;;
       *)  : # SHOULD NOT GET HERE
             ;;
esac

exit 0