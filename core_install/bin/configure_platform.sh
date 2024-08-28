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
# Name    : configure_platform.sh
# Date    : 19/02/2015
# Revision: A.1
# Purpose : Script to set certain parameters when installing in a VM
#
# Usage   : See Usage() function

# ********************************************************************
#
#   Command Section
#
# ********************************************************************
AWK=/usr/bin/awk
BASENAME=/usr/bin/basename
CAT=/usr/bin/cat
CLEAR=/usr/bin/clear
CP=/usr/bin/cp
ECHO=/usr/bin/echo
EGREP=/usr/bin/egrep
GEGREP=/usr/sfw/bin/gegrep
HEAP=/usr/bin/head
MV=/usr/bin/mv
MYHOSTNAME=/usr/bin/hostname
NAWK=/usr/bin/nawk
PRINTF=/usr/bin/printf
PRTCONF=/usr/sbin/prtconf
RM=/usr/bin/rm
SED=/usr/bin/sed
TEE=/usr/bin/tee
TR=/usr/bin/tr

# ********************************************************************
#
#   Default Settings Values
#
# ********************************************************************

GLASSFISH_DEFAULT_MAX_HEAP="8192m"
GLASSFISH_DEFAULT_MIN_HEAP="8192m"
GLASSFISH_DEFAULT_PERM_SIZE="2048m"
GLASSFISH_DEFAULT_LPAGE="256m"
GLASSFISH_DEFAULT_SRATIO="4"
GLASSFISH_DEFAULT_NRATIO="4"

ENGINE_HEAP_FACTOR_STATS=18
ENGINE_HEAP_FACTOR_EVENTS=24

SCHEDULER_DEFAULT_MAX_HEAP="64M"

EVENTS_IQ_MIN_CACHE_SIZE_DEFAULT="2000M"
EVENTS_IQ_MAX_CACHE_SIZE_DEFAULT="2000M"
STATS_IQ_INITIAL_CACHE_SIZE_DEFAULT="5000M"

###set_core_memcache
OS_MIN_VALUE_DEFAULT=12288
MIN_OS_MEM_DEFAULT=20480
FT_CO_APP_BUFF_DEFAULT=2048
MAIN_CACHE_DEFAULT=5349
TEMP_CACHE_DEFAULT=8024
LARGE_CACHE_DEFAULT=2048
CATALOG_CACHE_DEFAULT=2048


# ********************************************************************
#
#   Global Constants
#
# ********************************************************************

EXIT_OK=0
EXIT_ERROR=1
EXIT_USAGE_ERROR=2
EXIT_INVALID_VALUE=3
EXIT_INVALID_SETTING=4

RETURN_OK=0
RETURN_ERROR=1

declare -a SIZE_ORDER=(k m g t)
MEM_FORMAT="(^[0-9]+)([k|m|g|t])"

ENIQ_INST=/eniq/installation
ENIQ_CORE_INSTALL=${ENIQ_INST}/core_install/
ENIQ_CONF_DIR=${ENIQ_INST}/config
INST_TYPE_FILE=${ENIQ_CONF_DIR}/ericsson_use_config
INERATOR_ANSWER_FILE=${PWD}/inerator.properties
INSTALL_TYPE=`$CAT ${INST_TYPE_FILE} | $NAWK -F\= '{print $2}'`
ENIQ_INI=niq.ini
validate_input=0


# ********************************************************************
#
#       Configuration Section
#
# ********************************************************************

ASK_FOR_VALUES="n"
if [ -s ${ENIQ_CORE_INSTALL}/lib/common_functions.lib ]; then
    . ${ENIQ_CORE_INSTALL}/lib/common_functions.lib
else
    $ECHO "File ${ENIQ_CORE_INSTALL}/lib/common_functions.lib not found"
    exit ${EXIT_ERROR}
fi

if [ ! -s ${ENIQ_CORE_INSTALL}/lib/iniadd.pl ]; then
    $ECHO "Cannot locate ${ENIQ_CORE_INSTALL}/lib/iniadd"
    exit ${EXIT_ERROR}
else
	INIADD=${ENIQ_CORE_INSTALL}/lib/iniadd.pl
fi
# ********************************************************************
#
#   Functions
#
# ********************************************************************
### Function: to_bytes ###
#
# Converts a JVM memory value to bytes and echoes the result to STDOUT
#
# Arguments:
#       $1 : The memory value e.g. 125m or 1024k
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
to_bytes()
{
	_setting_=`$ECHO "$1" | $TR '[A-Z]' '[a-z]'`
	_num_=`$ECHO $_setting_ | $AWK '{print substr($1, 0, length($1)-1)}'`
	_factor_=`$ECHO $_setting_ | $AWK '{print substr($1, length($1), length($1))}'`

	_kilo_=1024
	_mega_=$((${_kilo_} * ${_kilo_}))
	_giga_=$((${_mega_} * ${_kilo_}))
	_tera_=$((${_giga_} * ${_kilo_}))

	_mul_=1
	
	if [ "$_factor_" == "k" ] ; then
		_mul_=${_kilo_}
	elif [ "$_factor_" == "m" ] ; then
		_mul_=${_mega_}
	elif  [ "$_factor_" == "g" ] ; then
		_mul_=${_giga_}
	elif  [ "$_factor_" == "t" ] ; then
		_mul_=${_tera_}
	else
		$ECHO "Unknown size factor '$_factor_' in $_setting_" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	$ECHO $(($_num_ * $_mul_))
	return ${RETURN_OK}
}

### Function: get_value ###
#
# Get user response to a question or default value if no answer specified
#
# Arguments:
#       $1 : The question
#		$2 : The variable the answer will be stored in
#		$3 : Default answer to the question
# Return Values
#		0 if successful
#		1 if errors
get_value()
{
        local _message_=$1
        local _return_var_=$2
        local _default_=$3
        local _is_int_=$4
        local _value_
	
        while :; do
                $PRINTF "$_message_ "
                if [ "${_default_}" ]; then
                          $PRINTF "(defaults to ${_default_}) "
                fi
                $PRINTF ": "
                read _value_
                #transform everything to lower case, makes it easier to verify stuff later on
                _value_=`$ECHO "$_value_" | $TR '[A-Z]' '[a-z]'`
                    if [[ "${_value_}" ]] ; then
                        if [[ "${_is_int_}" ]] ;then 
                            if [ ${_is_int_} -eq 0 ]; then
                                if  [[ "$_value_" =~ ^[0-9]+$ ]] ; then 
                                    first_digit=`$ECHO ${_value_} | cut -c 1`
                                    if [ ${first_digit} -eq 0 ]; then
                                        log_msg -s "Please enter memory values in numeric only" -l ${LOGFILE}
                                        continue;
                                    fi
                                else
                                    log_msg -s "Please enter memory values in numeric only" -l ${LOGFILE}
                                    continue;
                                fi
                            fi
                        fi 
                            eval $_return_var_="'${_value_}'"
                            break;
                       elif [[ "${_default_}" ]] ; then
                       eval $_return_var_="'${_default_}'"
                       break;
                       else
                       continue
                   fi
        done
        return ${RETURN_OK}
}


verify_calculated_cache()
{
#
# Percentage extra of total memory
# to hold in reserve
        OS_MIN_VALUE=$1 
        TOTAL_MEM_RES_PERCENTAGE=6
        NEW_OS_MIN_VALUE=""
        # Min value for OS - 12GB
        # Overwrite with new Values if they exist
        if [ -f ${ENIQ_CONF_DIR}/${ENIQ_INI} ]; then
        NEW_OS_MIN_VALUE=`iniget SYSTEM_INFO -f ${ENIQ_CONF_DIR}/${ENIQ_INI} -v OS_MIN_VALUE`
        fi
        if [ "${NEW_OS_MIN_VALUE}" ]; then
                OS_MIN_VALUE=${NEW_OS_MIN_VALUE}
        fi
        # Get the total memory of server in MBytes
        _total_phys_mem_=`$PRTCONF | $EGREP '^Memory size'|$NAWK '{print $3}'`
        if [ ! "${_total_phys_mem_}" ]; then
                log_msg -s  "Could not read total memory value from $PRTCONF" -l ${LOGFILE}
                return ${RETURN_ERROR} 
        fi
        log_msg -s "\nTotal physical memory is ${_total_phys_mem_}Mb" -q -l ${LOGFILE}
        _phys_mem_res_=`$EXPR ${_total_phys_mem_} \* ${TOTAL_MEM_RES_PERCENTAGE} / 100`
        if [ ! "${_phys_mem_res_}" ]; then
                log_msg -s "Could not set a percentage reserve of memory" -q -l ${LOGFILE}
        return ${RETURN_ERROR} 
        fi
        log_msg -s "Total memory percentage reserved ${_phys_mem_res_}Mb" -q -l ${LOGFILE}
        _iq_avail_mem_=`$EXPR ${OS_MIN_VALUE} + ${_phys_mem_res_}`
        if [ ! "${_iq_avail_mem_}" ]; then
                 log_msg -s "Could not set value required for OS" -l ${LOGFILE}
        return ${RETURN_ERROR}
        fi
        if [ ${_iq_avail_mem_} -lt ${min_os_value} ]; then
               _sol_res_=${min_os_value}
        else
               _sol_res_=${_iq_avail_mem_}
        fi
        log_msg -s "Total memory being hidden from IQ is ${_sol_res_}Mb" -q -l ${LOGFILE}
        _total_mem_=`$EXPR ${_total_phys_mem_} - ${_sol_res_} - ${ft_app_buff} - 5120`
        if [ ! "${_total_mem_}" ]; then
                 log_msg -s "Could not get a memory value for IQ" -l ${LOGFILE}
                 return ${RETURN_ERROR}
        fi     
        if [ ${_total_mem_} -le 0 ]; then
               log_msg -s "Memory required for IQ cannot be a negative value (${_total_mem_})" -l ${LOGFILE}
               return ${RETURN_ERROR}
        fi
        log_msg -s "Total memory available for IQ is ${_total_mem_}Mb" -q -l ${LOGFILE}
        # Check that the total cache is not greater than total memory
        # or the Max shared Memory Segment
        _tot_cach_mem_=`$EXPR ${main_cache_mem} + ${temp_cache_mem} + ${large_cache_mem} + ${catalog_cache_mem}`
        # Here I check if the calculated cache requirements a re greater than
        # the total memory or the shared memory size. 
        if [ ${_tot_cach_mem_} -gt ${_total_mem_} ]; then
               log_msg -s "Cache memory entered is greater or equal to total available memory (${_total_mem_}MB).Please re-enter." -l ${LOGFILE} 
               return ${RETURN_ERROR}  
        fi
        return ${RETURN_OK}
}
### Function: verify_memory_format ###
#
# Verify the memory format string is ok
# format is {num}k|m|g|t e.g. 125m or 1024k
#
# Arguments:
#       $1 : The memory value
# Return Values:
#		0 if format is ok
#		1 if format is not correct
verify_memory_format()
{
	local _setting_=$1
	$ECHO "$_setting_" | $TR '[A-Z]' '[a-z]' | $GEGREP "${MEM_FORMAT}" > /dev/null
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	return ${RETURN_OK}
}

### Function: _ini_add ###
#
# Add a new name=value entry to an ini file
#
# Arguments:
#       $1 : The ini file to update
#		$2 : The block name
#		$3 : The parameter name
#		$4 : The parameter value
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
_ini_add()
{
	local _ini_file_=$1
	if [ ! -s ${_ini_file_} ]; then
		$ECHO "${_ini_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	local _block_=$2
	local _name_=$3
	local _value_=$4
	local _output_file_=`$BASENAME $_ini_file_`.$$
	
	$RM -rf $_output_file_
	
	$AWK '{
		print $0
		if($1 == block)
		{
			print(param)
		}
	}' block="[$_block_]" param="$_name_=$_value_" $_ini_file_ > $_output_file_
	
	if [ $? -ne 0 ]; then
		$ECHO "Error(1) adding ${_block_}:${_name_}=${_value_} to ${_ini_file_}" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	
	$MV $_output_file_ $_ini_file_
	if [ $? -ne 0 ]; then
		$ECHO "Error(2) adding ${_block_}:${_name_}=${_value_} to ${_ini_file_}" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
    fi
	return ${RETURN_OK}
}

### Function: _ini_update ###
#
# Update and existing name=value entry in an ini file
#
# Arguments:
#       $1 : The ini file to update
#		$2 : The block name
#		$3 : The parameter name
#		$4 : The parameter value
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
_ini_update()
{
	local _ini_file_=$1
	if [ ! -s ${_ini_file_} ]; then
		$ECHO "${_ini_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	local _block_=$2
	local _name_=$3
	local _value_=$4
	iniset ${_block_} -f ${_ini_file_} ${_name_}=${_value_}
	if [ $? -ne 0 ]; then
		$ECHO "Could not update ${_ini_file_} with ${_block_}:${_name_}=${_value_}" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	return ${RETURN_OK}
}

### Function: update_ini ###
#
# This function will update an ini file with the values specified.
# If the entry already exists it will get updated
# If the entry in new it will get added
#
# Arguments:
#	$1 : INI file to be updated
#	$2 : Ini block
#	$3 : param name
#	$4 : param value
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
update_ini()
{
	local _ini_file_=$1
	if [ ! -s ${_ini_file_} ]; then
		$ECHO "${_ini_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	
	local _block_=$2
	local _name_=$3
	local _value_=$4
	_current_=`iniget ${_block_} -f ${_ini_file_} -p ${_name_}`
	if [ -z $_current_ ] ; then
		_tmp_file_=/var/tmp/`$BASENAME $_ini_file_`
		_ini_add ${_ini_file_} ${_block_} ${_name_} ${_value_} ${_tmp_file_}
		if [ $? -ne 0 ] ; then
			return ${RETURN_ERROR}
		fi
	else
		_ini_update ${_ini_file_} ${_block_} ${_name_} ${_value_}
		if [ $? -ne 0 ] ; then
			return ${RETURN_ERROR}
		fi
	fi
	return ${RETURN_OK}
}

### Function: update_set_core_memcache_settings ###
#
# This function sets core memcache settings parameters in the ini file.
#
# Arguments:
#	$1 : INI file to be updated
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
update_set_core_memcache_settings()
{

local _ini_file_=$1
	if [ ! -s ${_ini_file_} ]; then
		$ECHO "${_ini_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
        local os_min_value=$OS_MIN_VALUE_DEFAULT
        local min_os_value=$MIN_OS_MEM_DEFAULT
        local ft_app_buff=$FT_CO_APP_BUFF_DEFAULT
        local main_cache_mem=$MAIN_CACHE_DEFAULT
        local temp_cache_mem=$TEMP_CACHE_DEFAULT
        local large_cache_mem=$LARGE_CACHE_DEFAULT
        local catalog_cache_mem=$CATALOG_CACHE_DEFAULT 
	if [ "$ASK_FOR_VALUES" == "y" ] ; then
		get_value "Enter OS Min Disk Value" os_min_value $os_min_value $validate_input
		get_value "Enter OS MIN Memory Value" min_os_value $min_os_value $validate_input
		get_value "Enter FT APP Buffer" ft_app_buff $ft_app_buff $validate_input
                while :; do
                         while :; do   
                                get_value "Enter MAIN Cache memory value" main_cache_mem $main_cache_mem $validate_input
                         break
                         done
                         while :; do
                                get_value "Enter Temp Cache memory value" temp_cache_mem $temp_cache_mem $validate_input
                         break
                         done
                         while :; do
                                get_value "Enter Large Cache memory value" large_cache_mem $large_cache_mem $validate_input
                         break
                         done
                         while :; do
                            get_value "Enter Catalog Cache memory value" catalog_cache_mem $catalog_cache_mem $validate_input
                         break
                         done
                         verify_calculated_cache $os_min_value
                         if [ $? -ne 0 ]; then
                               continue;
                         fi
                         break
                done
	fi
	update_ini ${_ini_file_} SYSTEM_INFO OS_MIN_VALUE ${os_min_value}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export OS_MIN_VALUE=${os_min_value}
	
	update_ini ${_ini_file_} SYSTEM_INFO MIN_OS_MEM ${min_os_value}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export MIN_OS_MEM=${min_os_value}
	
	update_ini ${_ini_file_} SYSTEM_INFO FT_CO_APP_BUFF ${ft_app_buff}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export FT_CO_APP_BUFF=${ft_app_buff}

        update_ini ${_ini_file_} DWH MainCache ${main_cache_mem}
        if [ $? -ne 0 ] ; then
                return ${RETURN_ERROR}
        fi
        export MainCache=${main_cache_mem} 

        update_ini ${_ini_file_} DWH TempCache ${temp_cache_mem}
        if [ $? -ne 0 ] ; then
                return ${RETURN_ERROR}
        fi
        export TempCache=${temp_cache_mem}

        update_ini ${_ini_file_} DWH LargeMemory ${large_cache_mem}
        if [ $? -ne 0 ] ; then
                return ${RETURN_ERROR}
        fi
        export LargeMemory=${large_cache_mem}

        update_ini ${_ini_file_} DWH CatalogCache ${catalog_cache_mem}
        if [ $? -ne 0 ] ; then
                return ${RETURN_ERROR}
        fi
        export CatalogCache=${catalog_cache_mem}

	return ${RETURN_OK}

}

### Function: update_glassfish_settings ###
#
# Update the Glassfish JVM settings in the main ini file
#
# Arguments:
#       $1 : Ini file to update
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
update_glassfish_settings()
{
	local _ini_file_=$1
	if [ ! -s ${_ini_file_} ]; then
		$ECHO "${_ini_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	local max_heap=$GLASSFISH_DEFAULT_MAX_HEAP
	local min_heap=$GLASSFISH_DEFAULT_MIN_HEAP
	local perm_size=$GLASSFISH_DEFAULT_PERM_SIZE
	local lpage=$GLASSFISH_DEFAULT_LPAGE
	local sratio=$GLASSFISH_DEFAULT_SRATIO
	local nratio=$GLASSFISH_DEFAULT_NRATIO
	
	if [ "$ASK_FOR_VALUES" == "y" ] ; then
		while :; do	
			get_value "Enter Glassfish Max Heap" max_heap $max_heap
			if [ "quit" == "$max_heap" ] ; then
				return ${RETURN_ERROR}
			fi
			verify_memory_format $max_heap
			if [ $? -ne 0 ] ; then
				$ECHO "Max memory setting is not in the correct format: $max_heap" | $TEE -a ${LOGFILE}
				max_heap=$GLASSFISH_DEFAULT_MAX_HEAP
				continue
			fi
			
			get_value "Enter Glassfish Min Heap" min_heap $min_heap
			if [ "quit" == "$min_heap" ] ; then
				return ${RETURN_ERROR}
			fi
			verify_memory_format $min_heap
			if [ $? -ne 0 ] ; then
				$ECHO "Min memory setting is not in the correct format: $min_heap" | $TEE -a ${LOGFILE}
				min_heap=$GLASSFISH_DEFAULT_MIN_HEAP
				continue
			fi

			get_value "Enter Glassfish MaxPermSize" perm_size $perm_size
			if [ "quit" == "$perm_size" ] ; then
				return ${RETURN_ERROR}
			fi
			verify_memory_format $perm_size
			if [ $? -ne 0 ] ; then
				$ECHO "MaxPermSize is not in the correct format: $perm_size" | $TEE -a ${LOGFILE}
				min_heap=$GLASSFISH_DEFAULT_PERM_SIZE
				continue
			fi
			
			get_value "Enter Glassfish LargePageSizeInBytes" lpage $lpage
			if [ "quit" == "$lpage" ] ; then
				return ${RETURN_ERROR}
			fi
			verify_memory_format $lpage
			if [ $? -ne 0 ] ; then
				$ECHO "LargePageSizeInBytes is not in the correct format: $lpage" | $TEE -a ${LOGFILE}
				lpage=$GLASSFISH_DEFAULT_LPAGE
				continue
			fi

			get_value "Enter Glassfish SurvivorRatio" sratio $sratio $validate_input
			if [ "quit" == "$sratio" ] ; then
				return ${RETURN_ERROR}
			fi
			if ! [[ "$sratio" =~ ^[0-9]+$ ]] ; then
				$ECHO "SurvivorRatio must be a number: $sratio" | $TEE -a ${LOGFILE}
				sratio=$GLASSFISH_DEFAULT_SRATIO
				continue
			fi
			
			get_value "Enter Glassfish NewRatio" nratio $nratio
			if [ "quit" == "$nratio" ] ; then
				return ${RETURN_ERROR}
			fi
			if ! [[ "$nratio" =~ ^[0-9]+$ ]] ; then
				$ECHO "NewRatio must be a number: $nratio" | $TEE -a ${LOGFILE}
				nratio=$GLASSFISH_DEFAULT_NRATIO
				continue
			fi
			
			local _max_bytes_=`to_bytes $max_heap`
			if [ $? -ne 0 ] ; then
				$ECHO "Failed to convert max heap: $_max_bytes_" | $TEE -a ${LOGFILE}
				continue
			fi
			local _min_bytes_=`to_bytes $min_heap`
			if [ $? -ne 0 ] ; then
				$ECHO "Failed to convert min heap: $_min_bytes_" | $TEE -a ${LOGFILE}
				continue
			fi
			
			if [ $_min_bytes_ -gt $_max_bytes_ ] ; then
				$ECHO "Max heap size cant be less than the min heap size: $max_heap < $min_heap" | $TEE -a ${LOGFILE}
				continue
			fi
			
			local _perm_bytes_=`to_bytes $perm_size`
			if [ $? -ne 0 ] ; then
				$ECHO "Failed to convert perm size: $_perm_bytes_" | $TEE -a ${LOGFILE}
				continue
			fi
			if [ $_perm_bytes_ -gt $_max_bytes_ ] ; then
				$ECHO "MaxPermSize cant be greater than the max heap size: $perm_size > $max_heap" | $TEE -a ${LOGFILE}
				continue
			fi
			break;
		done
	fi
	
	update_ini ${_ini_file_} GLASSFISH MinHeap ${min_heap}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export GLASSFISH_MIN_HEAP=${min_heap}
	
	update_ini ${_ini_file_} GLASSFISH MaxHeap ${max_heap}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export GLASSFISH_MAX_HEAP=${max_heap}
	
	update_ini ${_ini_file_} GLASSFISH MaxPermSize ${perm_size}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export GLASSFISH_PERM=${perm_size}
	
	update_ini ${_ini_file_} GLASSFISH LargePageSizeInBytes ${lpage}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export GLASSFISH_LPAGE=${lpage}
	
	update_ini ${_ini_file_} GLASSFISH SurvivorRatio ${sratio}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export GLASSFISH_SRATIO=${sratio}
	
	update_ini ${_ini_file_} GLASSFISH NewRatio ${nratio}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export GLASSFISH_NRATIO=${nratio}
	
	return ${RETURN_OK}
}

### Function: update_engine_settings ###
#
# This function will set the Heap Memory size 
# of the ENIQ engine.
#
# Arguments:
#	$1 : INI file to be updated
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
update_engine_settings()
{
	local _ini_file_=$1
	if [ ! -s ${_ini_file_} ]; then
		$ECHO "${_ini_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	# Call the one in common_functions.lib
	update_engine_java_heap_size $_ini_file_ | $TEE -a ${LOGFILE}
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	return ${RETURN_OK}
}

### Function: update_scheduler_settings ###
#
# This function will set the Heap Memory size 
# of the ENIQ scheduler.
#
# Arguments:
#	$1 : INI file to be updated
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
update_scheduler_settings()
{
	local _ini_file_=$1
	local _heap_size_=$SCHEDULER_DEFAULT_MAX_HEAP
	if [ "$ASK_FOR_VALUES" == "y" ] ; then
		while :; do
			get_value "Enter Scheduler Max Heap" _heap_size_ ${_heap_size_}
			if [ "quit" == "$_heap_size_" ] ; then
				return ${RETURN_ERROR}
			fi
			verify_memory_format $_heap_size_
			if [ $? -ne 0 ] ; then
				$ECHO "Memory setting is not in the correct format: $_heap_size_" | $TEE -a ${LOGFILE}
				_heap_size_=$SCHEDULER_DEFAULT_MAX_HEAP
				continue
			fi
			break
		done
	fi
	update_ini ${_ini_file_} ETLC SchedulerHeap $_heap_size_
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export SCHEDULER_MAX_HEAP=$_heap_size_
	return ${RETURN_OK}
}

### Function: _config_iq_events ###
#
# This function set Events specific IQ database parameters.
#
# Arguments:
#	$1 : INI file to be updated
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
_config_iq_events()
{
	local _iqcfg_file_=$1
	if [ ! -s ${_iqcfg_file_} ]; then
		$ECHO "${_iqcfg_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	
	while :; do
		local _min_cache_size_=$EVENTS_IQ_MIN_CACHE_SIZE_DEFAULT
		local _max_cache_size_=$EVENTS_IQ_MAX_CACHE_SIZE_DEFAULT
		
		get_value "Enter IQ Cache minimum size in bytes" _min_cache_size_ ${_min_cache_size_}
		if [ "quit" == "$_min_cache_size_" ] ; then
			return ${RETURN_ERROR}
		fi
		verify_memory_format $_min_cache_size_
		if [ $? -ne 0 ] ; then
			$ECHO "Memory setting is not in the correct format: $_min_cache_size_" | $TEE -a ${LOGFILE}
			continue
		fi
	
		get_value "Enter IQ Cache maximum size in bytes" _max_cache_size_ ${_max_cache_size_}
		if [ "quit" == "$_max_cache_size_" ] ; then
			return ${RETURN_ERROR}
		fi
		verify_memory_format $_max_cache_size_
		if [ $? -ne 0 ] ; then
			$ECHO "Memory setting is not in the correct format: $_max_cache_size_" | $TEE -a ${LOGFILE}
			continue
		fi
	
		local _min_bytes_=`to_bytes $_min_cache_size_`
		if [ $? -ne 0 ] ; then
			$ECHO "Failed to convert min cache size: $_min_cache_size_" | $TEE -a ${LOGFILE}
			continue
		fi
		
		local _max_bytes_=`to_bytes $_max_cache_size_`
		if [ $? -ne 0 ] ; then
			$ECHO "Failed to convert max cache size: $_max_cache_size_" | $TEE -a ${LOGFILE}
			continue
		fi
		
		if [ $_min_bytes_ -gt $_max_bytes_ ] ; then
			$ECHO "Max cache size cant be less than the min cache size: $_max_cache_size_ < $_min_cache_size_" | $TEE -a ${LOGFILE}
			continue
		fi
		break
	done
	
	update_ini ${_ini_file_} DWH MaxCache $_max_cache_size_
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export EVENTS_IQ_MAX_CACHE_SIZE=$_max_cache_size_
	
	update_ini ${_ini_file_} DWH MinCache $_min_cache_size_
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export EVENTS_IQ_MIN_CACHE_SIZE=$_min_cache_size_
	
	return ${RETURN_OK}
}

### Function: _config_iq_stats ###
#
# This function set Stats specific IQ database parameters.
#
# Arguments:
#	$1 : INI file to be updated
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
_config_iq_stats()
{
	local _iqcfg_file_=$1
	if [ ! -s ${_iqcfg_file_} ]; then
		$ECHO "${_iqcfg_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	
	while :; do
		local _initial_cache_max_=$STATS_IQ_INITIAL_CACHE_SIZE_DEFAULT
		get_value "Enter IQ Cache initial size in bytes" _initial_cache_max_ ${_initial_cache_max_}
		if [ "quit" == "$_initial_cache_max_" ] ; then
			return ${RETURN_ERROR}
		fi
		verify_memory_format $_initial_cache_max_
		if [ $? -ne 0 ] ; then
			$ECHO "Memory setting is not in the correct format: $_initial_cache_max_" | $TEE -a ${LOGFILE}
			continue
		fi
		break
	done
	
	update_ini ${_ini_file_} DWH InitialMaxCache $_initial_cache_max_
	if [ $? -ne 0 ] ; then
		return ${RETURN_ERROR}
	fi
	export STATS_IQ_INITIAL_CACHE_SIZE=$_initial_cache_max_
	return ${RETURN_OK}
}

### Function: update_iq_settings ###
#
# This function set IQ database parameters.
#
# Arguments:
#	$1 : INI file to be updated
#	$2 : Database .cfg file to be updated
# Return Values:
#		0 if successful
#		1 if errors (error message sent to stdout)
update_iq_settings()
{
	local _ini_file_=$1
	if [ ! -s ${_ini_file_} ]; then
		$ECHO "${_ini_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
		return ${RETURN_ERROR}
	fi
	
	if [ "$ASK_FOR_VALUES" == "y" ] ; then
		_block_="DWH"
		_param_name_="IQPageSize"
		while :; do
			_iq_page_size_=`iniget ${_block_} -f ${_ini_file_} -v ${_param_name_}`
			get_value "Enter IQ Page Size" _iq_page_size_ ${_iq_page_size_} $validate_input
			if [ "quit" == "$_iq_page_size_" ] ; then
				return ${RETURN_ERROR}
			fi
			if ! [[ "$_iq_page_size_" =~ ^[0-9]+$ ]] ; then
				$ECHO "$_param_name_ must be a number: $_iq_page_size_" | $TEE -a ${LOGFILE}
				continue
			fi
			break
		done
		
		update_ini ${_ini_file_} ${_block_} ${_param_name_} $_iq_page_size_
		if [ $? -ne 0 ] ; then
			return ${RETURN_ERROR}
		fi
		export IQ_PAGE_SIZE=$_iq_page_size_

		if [ "${INSTALL_TYPE}" == "events" ]; then
			_config_iq_events $_iq_file_
		else
			_config_iq_stats $_iq_file_
		fi
		if [ $? -ne 0 ] ; then
			return ${RETURN_ERROR}
		fi
	fi
	return ${RETURN_OK}
}

### Function: usage ###
#
# Print usage
#
# Arguments:
#       none
# Return Values:
#       none
usage()
{
$CAT << EOF
usage: $0 -i file [-e|-g|-s|-q]

Updates the JVM settings for Platform components
Sets values based on defaults & calculated
Used the -a flag will prompt for a value (also providing a default)

OPTIONS:
	-a		Ask for values
	-i ini	Ini file to store the setting in.
	-e      Update the JVM settings for Engine.
	-g      Update the JVM settings for Glassfish.
	-s      Update the JVM settings for Scheduler.
	-q 		Update the IQ config settings.
	-c 		Update the set core mem cache settings.
	-l logfile	Logfile to output messages/errors.
EOF
}

# ********************************************************************
#
#   Main body of program
#
# ********************************************************************

if [ $# -eq 0 ] ; then
	usage
	exit ${EXIT_USAGE_ERROR}
fi

ASK_FOR_VALUES="n"
LOGFILE=

while getopts "l:aesgqci:" OPTION ; do
	case $OPTION in
		a)	ASK_FOR_VALUES="y"
			;;
		e)	update_engine=1
			;;
		s)	update_scheduler=1
			;;
		g)	update_glassfish=1
			;;
		q)	update_iq=1
			;;		
		c) 	update_core_memcache=1
			;;
		i)	_ini_file_=$OPTARG
			;;
		l)	LOGFILE=$OPTARG
			;;
		?)	usage
			exit ${EXIT_USAGE_ERROR}
			;;
	esac
done


if [ ! "${LOGFILE}" ]; then
	if [ ! "${ENIQ_BASE_DIR}" ]; then
		ENIQ_BASE_DIR=/eniq
	fi
	LOGFILE="${ENIQ_BASE_DIR}/local_logs/installation/`${MYHOSTNAME}`_install_config.log"
	$ECHO "No logfile specified, using ${LOGFILE}"
fi

if [ -z $_ini_file_ ] ; then
	$ECHO "No ini file specified?" | $TEE -a ${LOGFILE}
	exit ${EXIT_USAGE_ERROR}
fi

if [ ! -s ${_ini_file_} ]; then
	$ECHO "${_ini_file_} does not exist, or is empty" | $TEE -a ${LOGFILE}
	exit ${EXIT_ERROR}
fi

if [ $update_engine ] ; then
	update_engine_settings $_ini_file_
	if [ $? -ne 0 ] ; then
		exit ${EXIT_ERROR}
	fi
fi

if [ $update_glassfish ] ; then
	update_glassfish_settings $_ini_file_
	if [ $? -ne 0 ] ; then
		exit ${EXIT_ERROR}
	fi
fi

if [ $update_scheduler ] ; then
	update_scheduler_settings $_ini_file_
	if [ $? -ne 0 ] ; then
		exit ${EXIT_ERROR}
	fi
fi

if [ $update_iq ] ; then
	update_iq_settings $_ini_file_
	if [ $? -ne 0 ] ; then
		exit ${EXIT_ERROR}
	fi
fi

if [ $update_core_memcache ] ; then
	update_set_core_memcache_settings $_ini_file_
	if [ $? -ne 0 ] ; then
		exit ${EXIT_ERROR}
	fi
fi

exit ${EXIT_OK}

