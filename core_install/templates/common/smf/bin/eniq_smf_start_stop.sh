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
# ********************************************************************
# Name    : eniq_smf_start_stop
# Date    : 11/09/2018
# Revision: B
# Purpose : Main service wrapper script handling the starting/stopping
#           of ENIQ  services. This script is called by the relevant
#	    .service files during start/stop phases.
#
# Usage   : eniq_smf_start_stop.sh
#

# ********************************************************************
#
# 		Command Section
#
# ********************************************************************
AWK=/usr/bin/awk
BASENAME=/usr/bin/basename
CAT=/usr/bin/cat
CHOWN=/usr/bin/chown
CP=/usr/bin/cp
CUT=/usr/bin/cut
DATE=/usr/bin/date
DIRNAME=/usr/bin/dirname
ECHO="/usr/bin/echo -e"
EGREP=/usr/bin/egrep
FIND=/usr/bin/find
GAWK=/usr/bin/gawk
GETENT=/usr/bin/getent
GREP=/usr/bin/grep
ID=/usr/bin/id
MKDIR=/usr/bin/mkdir
MV=/usr/bin/mv
RM=/usr/bin/rm
SED=/usr/bin/sed
SU=/usr/bin/su
SUDO=/usr/bin/sudo
SYSTEMCTL=/usr/bin/systemctl
TOUCH=/usr/bin/touch
UNAME=/usr/bin/uname

# ********************************************************************
#
#       Configuration Section
#
# Used to setup the Environment for the services.
# ********************************************************************
#
# This is the name of the ENIQ System User
SYS_USER="dcuser"

# Determine absolute path to software
_dir_=`$DIRNAME $0`
SCRIPTHOME=`cd $_dir_ 2>/dev/null && pwd || $ECHO $_dir_`

# Main ENIQ Dir
ENIQ_BASE_DIR=/eniq

# Environment directory for SYS_USER. Used by services startup scripts.
CONF_DIR=${ENIQ_BASE_DIR}/sw/conf
export CONF_DIR

# Main Directory for the Core Installation SW
ENIQ_INST_DIR=${ENIQ_BASE_DIR}/installation

ENIQ_CONF_DIR=${ENIQ_INST_DIR}/config

SVC_CONTRACT_INFO=${ENIQ_BASE_DIR}/admin/etc/smf_contract_config
ENIQ_ADMIN_BIN=${ENIQ_BASE_DIR}/admin/bin

# Core install directory that contains scripts
ENIQ_CORE_DIR=${ENIQ_INST_DIR}/core_install

ENIQ_DB_DIR=${ENIQ_BASE_DIR}/database

# ********************************************************************
#
# 		Functions
#
# ********************************************************************
#
### Function: allowed_to_start ###
#
# Checks if this server is allowed to start this Service.
# Checks this servers IP to see if it is allowed to start service.
#
allowed_to_start()
{
if [ -s $ENIQ_CONF_DIR/installed_server_type ]; then
     CURR_SERVER_TYPE=`$CAT $ENIQ_CONF_DIR/installed_server_type`
else
    echo "ERROR:: File '$ENIQ_CONF_DIR/installed_server_type' does not exist."
    # Unrecoverable configuration error. Service will not restart.
    exit 96
fi

if [ -z "${CURR_SERVER_TYPE}" ]; then
    echo "ERROR:: Unable to determine server type. '$ENIQ_CONF_DIR/installed_server_type' not valid."
    # Unrecoverable configuration error. Service will not restart.
    exit 96
fi

_enable_service_=`$CAT ${SVC_CONTRACT_INFO} | $EGREP ${CURR_SERVER_TYPE} | $GREP -w "${ENIQ_SERVICE}" | $GAWK -F"::" '{print $4}'`
if [ "${_enable_service_}" = "Y" ]; then
    return 0
else
    return 1
fi
}

### Function: start_service ###
#
# Starts the systemd Service 
#
start_service()
{
REPEATING_ERROR_COUNT=0

# If binaries are located on the NAS storage, this must be mounted before we continue.
# This check is to make sure the this is available before we try to start this service.
while [ ! -s ${ENIQ_ADMIN_BIN}/${ENIQ_SERVICE} -o ! -s ${SVC_CONTRACT_INFO} ]; do
    echo "WARNING: File ' ${ENIQ_ADMIN_BIN}/${ENIQ_SERVICE} ' or '${SVC_CONTRACT_INFO}' not found; waiting to try again."
    sleep 10
    REPEATING_ERROR_COUNT=`expr ${REPEATING_ERROR_COUNT} + 1`
    if [ "${REPEATING_ERROR_COUNT}" -lt "5" ]; then
        sleep 5
    fi
    if [ "${REPEATING_ERROR_COUNT}" -ge "6" ]; then
        exit 1
    fi
done

if  allowed_to_start ; then
    if [ -s ${ENIQ_ADMIN_BIN}/${ENIQ_SERVICE} -a -d ${CONF_DIR} ]; then
        if [ "${ENIQ_SERVICE}" = "dwhdb" -o "${ENIQ_SERVICE}" = "dwh_reader" ];then
           # Build a list of IQ devices
           $FIND ${ENIQ_DB_DIR} | $EGREP "\.iq" > /tmp/db_list
           if [ -s /tmp/db_list ]; then
               while read _line_; do
                   $CHOWN dcuser:dc5000 ${_line_}
                   if [ $? -ne 0 ]; then
                       $ECHO "ERROR: Could not change ownership of ${_line_} to dcuser:dc5000"
                       exit 1
                   fi
               done < /tmp/db_list
      	       $RM -f /tmp/db_list >> /dev/null 2>&1
           else
               $ECHO "ERROR: Could not get a list of IQ devices under ${ENIQ_DB_DIR}"
               exit 1
           fi
        fi

        # Note: Individual ENIQ_SERVICE script needs to
        # source .profile of dcuser inside the script Main()
        ${ENIQ_ADMIN_BIN}/${ENIQ_SERVICE} start
        if [ $? -ne 0 ]; then
            $ECHO "ERROR: Could not start ${ENIQ_ADMIN_BIN}/${ENIQ_SERVICE} "
            exit 1
        fi
    else
        $ECHO "ERROR: Unable to locate start script for service ' ${ENIQ_SERVICE} '. "
        $SYSTEMCTL stop ${SVC_NAME}
        _service_state=`$SYSTEMCTL show ${SVC_NAME} -p ActiveState | $AWK -F= '{print $2}'`
        if [ "${_service_state}" == "inactive" ] ; then
            $ECHO " $_service_state state set correctly for ${ENIQ_SERVICE}"
        else
            $ECHO " Failed to set inactive state for ${ENIQ_SERVICE}"
        fi

        $SYSTEMCTL disable ${SVC_NAME}
        if [ $? -eq 0 ]; then
            $ECHO "INFO:: Successfully disabled ${ENIQ_SERVICE} service"
        else
            $ECHO "ERROR:: Unable to disabled ${ENIQ_SERVICE} service"
        fi

        sleep 1
        exit 1
    fi
else
    # The service should not start on this server. Disable the service.
    $ECHO "ERROR: Service should not be started on this server."
    $SYSTEMCTL stop ${SVC_NAME}
    _service_state=`$SYSTEMCTL show ${SVC_NAME} -p ActiveState | $AWK -F= '{print $2}'`
    if [ "${_service_state}" == "inactive" ] ; then
        $ECHO " $_service_state state set correctly for ${ENIQ_SERVICE}"
    else
        $ECHO " Failed to set inactive state for ${ENIQ_SERVICE}"
    fi

    $SYSTEMCTL disable ${SVC_NAME}
    if [ $? -eq 0 ]; then
        $ECHO "INFO:: Successfully disabled ${ENIQ_SERVICE} service"
    else
        $ECHO "ERROR:: Unable to disabled ${ENIQ_SERVICE} service"
    fi

    sleep 1

    exit 100
fi
}

### Function: stop_service ###
#
# Stops the systemd Service 
#
stop_service()
{
if [ -s ${ENIQ_ADMIN_BIN}/${ENIQ_SERVICE} -a -d ${CONF_DIR} ]; then
    # Note: Individual ENIQ_SERVICE script needs to
    # source .profile of dcuser inside the script Main()
    ${ENIQ_ADMIN_BIN}/${ENIQ_SERVICE} stop
    if [ $? -ne 0 ]; then
        $ECHO "ERROR: Service shutdown script failed to complete successfully."
    fi
	sleep 10
	$SUDO $SYSTEMCTL reset-failed ${SVC_NAME}
	if [ $? -ne 0 ]; then
	     $ECHO "ERROR:: Unable to reset the ${ENIQ_SERVICE} service"
	fi
else
    $ECHO "WARNING: Unable to locate service shutdown script."
fi
}

### Function: usage ###
#
# Displays the usage message.
#
usage()
{
$ECHO "
Usage:
`$BASENAME $0` -a start|stop|restart  -s <service_name>
e.g. `$BASENAME $0` -a stop -s dwh_reader

\t Main wrapper script handling the starting of the ENIQ services
\tduring service start/stop. This script is called by the relevant
\t.service file during start/stop phases.
"
}

# ***********************************************************************
#
#                    Main body of program
#
# ***********************************************************************
#
while getopts ":a:s:" arg; do
    case $arg in
        a)  ENIQ_ACTION="$OPTARG"
            ;;
        s)  ENIQ_SERVICE="$OPTARG"
            SVC_NAME="eniq-${ENIQ_SERVICE}.service"
            ;;
        \?) usage
	        exit 1
            ;;
    esac
done
shift `expr $OPTIND - 1`

if [ ! "${ENIQ_ACTION}" -o ! "${ENIQ_SERVICE}" ]; then
    usage
    exit 1
fi

case "${ENIQ_ACTION}" in
     start) start_service
    	    ;;

      stop) stop_service
    	    ;;
   
   restart) stop_service
            start_service
    	    ;;

         *) # SHOULD NOT GET HERE
         	usage
         	exit 1
       	    ;;
esac

exit 0
