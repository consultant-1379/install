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
# Name    : eniq_smf_connectd.sh
# Date    : 30/10/2018
# Revision: /main/6
# Purpose : SERVICE Methods script to start and stop the connectd Monitor daemon.
#           This script is called by the relevant Service Unit files during start/stop phase.
#
# ********************************************************************
#
#       Command Section
#
# ********************************************************************
AWK=/usr/bin/awk
BASENAME=/usr/bin/basename
CAT=/usr/bin/cat
ECHO='/usr/bin/echo -e'
EGREP=/usr/bin/egrep
EXPR=/usr/bin/expr
GREP=/usr/bin/grep
KILL=/usr/bin/kill
PS=/usr/bin/ps
SYSTEMCTL=/usr/bin/systemctl

# ********************************************************************
#
#       Configuration Section
#
# ********************************************************************
#
# Shell scripts used to define SERVICE Methods should include /lib/svc/share/smf_include.sh
# to gain access to convenience functions and return value definitions.
if [ -s /lib/svc/share/smf_include.sh ]; then
    . /lib/svc/share/smf_include.sh
fi

# The connectd Monitor script
CONNECTD_MONITOR="/eniq/connectd/bin/connectd.bsh"

# Needed for 'allowed to start' function
ENIQ_SERVICE="connectd"
SVC="eniq-connectd.service"

# ENIQ Base Directory
ENIQ_BASE_DIR=/eniq/

# ENIQ Admin Directory
ENIQ_ADMIN_DIR=${ENIQ_BASE_DIR}admin/

# Main Directory for the Core Installation SW
ENIQ_INST_DIR=${ENIQ_BASE_DIR}installation/

# ENIQ Config Directory
ENIQ_CONF_DIR=${ENIQ_INST_DIR}config/

# Main Directory for the Admin etc SW
ENIQ_ADMIN_ETC_DIR=${ENIQ_ADMIN_DIR}etc/

#SMF_contract_config file
SVC_CONTRACT_INFO=${ENIQ_ADMIN_ETC_DIR}smf_contract_config

# ********************************************************************
#
#       Functions
#
# ********************************************************************
#


### Function: allowed_to_start ###
#
# Checks if this server is allowed to start this SMF Service.
# Checks this servers IP to see if it is allowed to start service.
#
allowed_to_start()
{

    REPEATING_ERROR_COUNT=0
    # If binaries are located on the NFS storage, this must be mounted before we continue.
    # This check is to make sure the this is available before we try to start this service.
    while [ ! -s ${SVC_CONTRACT_INFO} ]; do
	if [ "${REPEATING_ERROR_COUNT}" -ge "10" ]; then
		echo "WARNING: File  '${SVC_CONTRACT_INFO}' not found; waiting to try again."
	fi
	sleep 10
	REPEATING_ERROR_COUNT=`${EXPR} ${REPEATING_ERROR_COUNT} + 1`
	if [ "${REPEATING_ERROR_COUNT}" -ge "15" ]; then
   		$ECHO "ERROR: File  '${SVC_CONTRACT_INFO}' not found. Exiting "
       		$SYSTEMCTL stop ${SVC}
	    	_service_state=`$SYSTEMCTL show ${SVC} -p ActiveState | $AWK -F= '{print $2}'`
	    	if [ "${_service_state}" == "inactive" ] ; then
			logit " ${_service_state} state set correctly for ${SVC}"
	    	else
			logit " Failed to set inactive state for ${SVC}"			
	    	fi
	    	$SYSTEMCTL disable ${SVC}
	    	if [ $? -eq 0 ]; then
			logit "INFO:: successfully disabled ${SVC} service"
	    	else
			logit "ERROR:: Unable to disabled ${SVC} service"
	    	fi 
            	sleep 1
            	exit 1
        fi
    done

    if [ -s $ENIQ_CONF_DIR/installed_server_type ]; then
         CURR_SERVER_TYPE=`$CAT $ENIQ_CONF_DIR/installed_server_type`
    else
        echo "ERROR:: File '$ENIQ_CONF_DIR/installed_server_type' does not exist."
        # SMF_EXIT_ERR_CONFIG=96
        # Unrecoverable configuration error. SMF will not restart.
        exit 96
    fi

    if [ -z "${CURR_SERVER_TYPE}" ]; then
        echo "ERROR:: Unable to determine server type. '$ENIQ_CONF_DIR/installed_server_type' not valid."
        # SMF_EXIT_ERR_CONFIG=96
        # Unrecoverable configuration error. SMF will not restart.
        exit 96
    fi

    _enable_service_=`$CAT ${SVC_CONTRACT_INFO} | $EGREP ${CURR_SERVER_TYPE} | $GREP -w "${ENIQ_SERVICE}" | $AWK -F"::" '{print $4}'`
    if [ "${_enable_service_}" = "Y" ]; then
        return 0
    else
        return 1
    fi
}



### Function: refresh_connectd ###
#
# Sends a reset SIGNAL to the ConnectD service.
# The ConnectD Monitor script traps the user signal USR1 as a reset.
#
refresh_connectd()
{
    CONNECTD_Monitor_pid=""
    CONNECTD_Monitor_pid=`${PS} -eaf | $GREP -vw grep | $GREP ${CONNECTD_MONITOR} | $AWK '{print $2}'`

    if [ ${CONNECTD_Monitor_pid} ]; then
        # The NAS_Monitor script defined the user SIG "USR1" as a reset.
        # It will trap for this and call a reset function.
        $KILL -USR1 ${CONNECTD_Monitor_pid}
    fi
}


### Function: start_connectd ###
#
# Starts the ConnectD service that monitors and mounts the OSS filesystems
#
start_connectd()
{

    if  allowed_to_start ; then
        if [ -s ${CONNECTD_MONITOR} ]; then
            ${CONNECTD_MONITOR} &
        else
            echo "ERROR:: '${CONNECTD_MONITOR}' not found; EXITING"
            exit 96
        fi
    else
        # The service should not start on this server. Disable smf sercive.
        $ECHO "ERROR: Service should not be started on this server."
        $SYSTEMCTL stop ${SVC}
        _service_state=`$SYSTEMCTL show ${SVC} -p ActiveState | $AWK -F= '{print $2}'`    
        if [ "${_service_state}" == "inactive" ] ; then
        	logit " ${_service_state} state set correctly for ${SVC}"
        else
             	logit " Failed to set inactive state for ${SVC}"
        fi
        $SYSTEMCTL disable ${SVC}
        if [ $? -eq 0 ]; then
             	logit "INFO:: successfully disabled ${SVC} service"
        else
             	logit "ERROR:: Unable to disabled ${SVC} service" 
        fi
        sleep 1
        # SMF_EXIT_ERR_PERM     100
        exit 1
    fi
}


### Function: stop_connectd ###
#
# Stops the ConnectD service that monitors and mounts the OSS filesystems
#
stop_connectd()
{

    CONNECTD_Monitor_pid=""
    CONNECTD_Monitor_pid=`${PS} -eaf | $GREP -vw grep | $GREP ${CONNECTD_MONITOR} | $AWK '{print $2}'`

    if [ ! -z "${CONNECTD_Monitor_pid}" ]; then
		for _con_pid_ in ${CONNECTD_Monitor_pid}; do
        # The OSS_Monitor script defines the user SIG "USR2" as a TERMINATE
        # It will trap for this and call a terminate function.
			$KILL -USR2 ${_con_pid_}
         if [ $? -ne 0 ]; then
            $ECHO "ERROR: Service shutdown script failed to complete successfully, Killing SMF contract."
         fi
		done # end of loop through pids
    else
        $ECHO "WARNING: Unable to get ProcessID for connectd, Killing SMF contract."
      
    fi
}


### Function: usage ###
#
# Displays the usage message.
#
usage()
{
    $ECHO "
    `$BASENAME $0` -a start|stop
        SVC method script handling the starting and stopping of the connection
        services which monitor the NFS Mounts between ENIQ and each OSS/SFS
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
        a)  ENIQ_ACTION="$OPTARG"
            ;;
        \?) usage
            exit 1
            ;;
    esac
done
shift `${EXPR} $OPTIND - 1`

if [ ! "${ENIQ_ACTION}" ]; then
    usage
    exit 1
fi


case "${ENIQ_ACTION}" in
     start) start_connectd
            ;;

      stop) stop_connectd
            ;;

   refresh) refresh_connectd
            ;;

         *) # SHOULD NOT GET HERE
            usage
            exit 1
            ;;
esac
exit 0
