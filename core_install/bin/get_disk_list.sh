#!/bin/bash
#*********************************************************************
# Ericsson Radio Systems AB                                     SCRIPT
#*********************************************************************
#
#
# (c) Ericsson Radio Systems AB 2019 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Radio Systems AB, Sweden. The programs may be used
# and/or copied only with the written permission from Ericsson Radio
# Systems AB or in accordance with the terms and conditions stipulated
# in the agreement/contract under which the program(s) have been
# supplied.
#
#*********************************************************************
# Name    : get_disk_list.sh
# Date    : 24/07/2023
# Revision: Z
#
# Purpose : List the disks detectable on a server.
#           Optionally list disk details and controller and
#           network interface information.
#
#
# Usage   : get_disk_list.sh [ -f [ -d <delim_string> ] ]                     
#                            [ -r ]
#                            [ -v ] [ OPTIONAL]
#                            [ -D ] [ OPTIONAL]
#
# Owner   : root:root 700
#
# Notes   :
#
# See function "usage_msg()" for description of the options.
#*********************************************************************

#*****************************
# Command variable assignments
#*****************************
AWK=/usr/bin/awk
BASENAME=/usr/bin/basename
CAT=/usr/bin/cat
DATE=/usr/bin/date
DF=/usr/bin/df
DIRNAME=/usr/bin/dirname
ECHO='/usr/bin/echo -e'
EGREP=/usr/bin/egrep
EXPR=/usr/bin/expr
FDISK=/usr/sbin/fdisk
GREP=/usr/bin/grep
HEAD=/usr/bin/head
ID=/usr/bin/id
LS=/usr/bin/ls
LSSCSI=/usr/bin/lsscsi
LSBLK=/usr/bin/lsblk
MKDIR=/usr/bin/mkdir
MULTIPATH=/usr/sbin/multipath
PARTED=/usr/sbin/parted
PRINTF=/usr/bin/printf
RM=/usr/bin/rm
SED=/usr/bin/sed
SORT=/usr/bin/sort
UCBECHO=/usr/bin/echo
VGDISPLAY=/usr/sbin/vgdisplay

#********************
# Temporary directory
#********************
TEM_DIR=/tmp/list_disks
$RM -rf ${TEM_DIR}
$MKDIR -p ${TEM_DIR}

#********************
# ENIQ directories 
#********************
# Directory on the root filesystem
ENIQ_BASE_DIR=/eniq
	
# Main Directory for the Core Installation SW
ENIQ_INST_DIR=${ENIQ_BASE_DIR}/installation

# ENIQ Config Directory
ENIQ_CONF_DIR=${ENIQ_INST_DIR}/config

# ENIQ Lib Directory
ENIQ_LIB_DIR=${ENIQ_INST_DIR}/core_install/lib

#Source common library functions
. ${ENIQ_LIB_DIR}/common_functions.lib

# Cmd to exec a shell and drop user to it in case of an error
EXEC_SHELL_CMD="exec /bin/bash -o emacs"

SUNOS_INI=SunOS.ini
#************************************
# Temporary file variable assignments
#************************************
_temp_=${TEM_DIR}/temp
_root_disks_=${TEM_DIR}/root_disks
_disks_details_=${TEM_DIR}/disks_details
_disk_hba_list_=${TEM_DIR}/disk_hba_list
_included_disks_=${TEM_DIR}/included_disks
_final_included_disks_=${TEM_DIR}/final_included_disks
_disk_information_=${TEM_DIR}/disk_information

#***************************
# Initialise temporary files
#***************************
>${_temp_}
>${_root_disks_}
>${_disks_details_}
>${_included_disks_}
>${_final_included_disks_}
>${_disk_information_}

### Function: abort_script ###
#
#   This is called if the script is aborted by an error
#   signal sent by the kernel such as CTRL-C or if a serious
#   error is encountered during runtime
#
# Arguments:
#       $1 - Error message from part of program (Not always used)
# Return Values:
#       none
abort_script()
{
_err_time_=`$DATE '+%Y-%b-%d_%H.%M.%S'`

if [ "$1" ]; then
    _err_msg_="${_err_time_} - $1"
else
    _err_msg_="${_err_time_} - ERROR : Script aborted.......\n"
fi

$ECHO "\nERROR : ${_err_msg_}\n"

cd $SCRIPTHOME
$RM -rf ${TEM_DIR}

if [ "$2" ]; then
   exit 1
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
######################################################
check_id()
{
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "FUNCTION: check_id"
  elif [ "${VERBOSE}" ]
  then
      $ECHO "Checking user id"
      if [ -x $UCBECHO ]
      then
          $UCBECHO -n "."
      fi
  fi
  #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  _check_id_=`$ID | $AWK -F \( '{print $2}' | $AWK -F \) '{print $1}'`
  if [ "$_check_id_" != "$1" ]
  then
      $ECHO "You must be $1 to execute this script."
      exit 1
  fi

  #>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "_check_id_ : ${_check_id_}"
      $ECHO "\n"
  elif [ "${VERBOSE}" ]
  then
      $ECHO "\n"
  fi
  #<<<<<<<<<<<<<<<<<<<<
}


### Function: display_disk_information ###
#
#   Display disk information
#
# Arguments:
#       none
# Return Values:
#       none
##########################################
display_disk_information()
{
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "\nFUNCTION: display_disk_information"
  fi
  #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  if [ "${DELIMITER}" ]
  then
      IFS=":"
      $CAT ${_disk_information_} |
      while read DISK HBA SIZE VENDOR PRODUCT
      do
        /usr/bin/echo -e ${DISK}${DELIMITER}${HBA}${DELIMITER}${SIZE}${DELIMITER}${VENDOR}${DELIMITER}${PRODUCT}
      done | $PG
      IFS=" "
  elif [ "${FMT_OUTPUT}" ]
  then
      #***************************************
      # Set up output format string for printf
      #***************************************

      $ECHO "\nAvailable disks"
      $PRINTF "Disk" "HBA" "Size" "Vendor" "Product"
      $PRINTF "----" "---" "----" "------" "-------"
      IFS=":"
      $CAT ${_disk_information_} |
      while read DISK HBA SIZE VENDOR PRODUCT
      do
        $PRINTF $DISK $HBA $SIZE $VENDOR $PRODUCT
      done | $PG
      IFS=" "
  else
      IFS=":"
      $CAT ${_disk_information_} |
      while read DISK HBA SIZE VENDOR PRODUCT
      do
        $ECHO $DISK
      done | $PG
      IFS=" "
  fi
}

### Function: get_absolute_path ###
#
# Determine absolute path to software
#
# Arguments:
#   none
# Return Values:
#   none
get_absolute_path()
{
_dir_=`$DIRNAME $0`
SCRIPTHOME=`cd $_dir_ 2>/dev/null && pwd || $ECHO $_dir_`
}


### Function: get_disks_details_list ###
#
#   Get list of all disks from FDISK
#
# Arguments:
#       none
# Return Values:
#       none
#######################################
get_disks_details_list()
{
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "FUNCTION: get_disks_details_list"
  elif [ "${VERBOSE}" ]
  then
      $ECHO "Getting disks Details"
  fi
  #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  
  if [ "${STORAGE_TYPE}" == "raw" ]; then
  
         if [ "${_san_device_}" == "local" ]; then
              	 # Getting the list of local disks
        	 $LSBLK --scsi | $GREP -w "sas" | $SORT -n -k2 | $AWK -F " " '{print $1}' > ${TEM_DIR}/local_disk_list
         	 if [ $? -ne 0 ]; then
                    # exit from script if return code non-zero
                      _err_msg_="Could not get the list of local disks"
                      abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                 fi
                 $CAT ${TEM_DIR}/local_disk_list >> ${TEM_DIR}/available_disk_list
          	 if [ $? -ne 0 ]; then
                   # exit from script if return code non-zero
                   _err_msg_="Could not copy local disks to ${TEM_DIR}/available_disk_list"
                   abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                 fi
         else     
            # Getting the list of storage disks
            $MULTIPATH -l | $GREP "mpath" | $AWK -F " " '{print $1}' > ${TEM_DIR}/san_disk_list
            if [ $? -ne 0 ]; then
               # exit from script if return code non-zero
                 _err_msg_="Couldn't get list of storage disks"
                abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
            fi
 
            $CP ${TEM_DIR}/san_disk_list ${TEM_DIR}/available_disk_list
            if [ $? -ne 0 ]; then
                # exit from script if return code non-zero
                _err_msg_="Could not copy ${TEM_DIR}/san_disk_list ${TEM_DIR}/available_disk_list"
                abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
            fi
         fi
  else
      # Getting the list of local disks
	  $LSBLK --scsi | $GREP -w "sas" | $SORT -n -k2 | $AWK -F " " '{print $1}' > ${TEM_DIR}/local_disk_list
	  if [ $? -ne 0 ]; then
             # exit from script if return code non-zero
             _err_msg_="Could not get the list of local disks"
             abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
	  fi
	  
	  $CP ${TEM_DIR}/local_disk_list ${TEM_DIR}/available_disk_list
	  if [ $? -ne 0 ]; then
             # exit from script if return code non-zero
             _err_msg_="Could not copy ${TEM_DIR}/local_disk_list ${TEM_DIR}/available_disk_list"
             abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
	  fi
  
  fi 

# Getting the lists of disks excluding root disks
 _CARD_=0
 _LAST_HBA_COUNT_=""
 while read line; do
    _DISK_=$line

    if [ "${FMT_OUTPUT}" ]
    then
        if `$EGREP -w "$_DISK_" ${_root_disks_} >/dev/null`
        then
            #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            if [ "${DEBUG}" ]
            then
                $ECHO "Excluding root disk $_DISK_"
            fi
            #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        else
            #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            if [ "${DEBUG}" ]
            then
                $ECHO "Including data disk $_DISK_"
            fi
            #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			
   	    # Setting HBA value for multipath disks
	    if [[ ${_DISK_} =~ mpath[a-z] ]]; then
		_HBA_=mpxio
	    else
            # Setting HBA value for local disks 
	        _HBA_COUNT_=`$LSBLK --scsi | $GREP -w "${_DISK_}" | $AWK -F " " '{print $2}' | $AWK -F ":" '{print $1}'`
	        if [ $? -ne 0 ]; then
                # exit from script if return code non-zero
                    _err_msg_="Could not get value of _HBA_COUNT_ for $_DISK_"
                    abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
		fi
	
		if [ "${_HBA_COUNT_}" != "${_LAST_HBA_COUNT_}" ]; then
                   _CARD_=`$EXPR ${_CARD_} + 1`
                   if [ $? -ne 0 ]; then
                   # exit from script if return code non-zero
                       _err_msg_="Could not get value of _HBA_COUNT_ for $_DISK_"
                       abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                   fi 
                 fi
		
		 _HBA_=hba${_CARD_}
		 
	     fi

	     $ECHO "${_DISK_} ${_HBA_}" >> ${_final_included_disks_}
			
	 fi
	 
	 _LAST_HBA_COUNT_=${_HBA_COUNT_}
 
    fi
done < ${TEM_DIR}/available_disk_list

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "\nFILE: _final_included_disks_"
      $CAT ${_final_included_disks_}
	  if [ $? -ne 0 ]; then
          _err_msg_="Could not display _final_included_disks_ file"
          abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
	  fi
      $ECHO "\n"
  elif [ "${VERBOSE}" ]
  then
      $ECHO "\n"
  fi
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

}

### Function: get_included_disks_sizes ###
#
#   Get sizes of disks
#
# Arguments:
#       none
# Return Values:
#       none
##########################################
get_included_disks_sizes()
{
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "FUNCTION: get_included_disks_sizes"
  elif [ "${VERBOSE}" ]
  then
      $ECHO "\nGetting disk sizes"
  fi
  #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  $SORT -n ${_final_included_disks_} > ${_disk_hba_list_}
  if [ $? -ne 0 ]; then
      _err_msg_="Could not create ${_disk_hba_list_} file"
      abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
  fi
  
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    if [ "${DEBUG}" ]
    then
	$ECHO "Getting disk details from PARTED"
    fi
   #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	
  while read line; do
      _DISK_=`$ECHO $line | $AWK -F " " '{print $1}'`
      if [ $? -ne 0 ]; then
          _err_msg_="Could not get the value of _DISK_"
          abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
      fi
		
      _HBA_=`$ECHO $line | $AWK -F " " '{print $2}'`
      if [ $? -ne 0 ]; then
           _err_msg_="Could not get the value of _HBA_"
           abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
      fi
	  
      if [ "${_san_device_}" == "local" ]; then
            $PARTED /dev/${_DISK_} -s print 2> /dev/null | $AWK '$1+0'| $GREP 1  >> /dev/null 2>&1
            if [ $? -eq 0 ]; then
                _dsk_size_bps_=`$PARTED /dev/${_DISK_} -s unit B print 2> /dev/null | $AWK '$1+0'| $AWK -F " " '{print $4}'| $SED 's/B$//g'` 2> /dev/null 
                if [ ! "${_dsk_size_bps_}" ]; then
                      _err_msg_="Could not get the value total Bytes for ${_DISK_}1"
                      abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                 fi
			
                 if [[ ${_dsk_size_bps_} -lt 1073741824 ]]; then
                      _dsk_size_=`$EXPR ${_dsk_size_bps_} / 1048576| $AWK -F\. '{print $1}'`
                      if [ ! "${_dsk_size_}" ]; then
                            _err_msg_="Could not get the size of ${_DISK_} in MBytes"
                            abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                      fi
				
                      _disk_unit_="MBytes"
                else
                      _dsk_size_=`$EXPR ${_dsk_size_bps_} / 1073741824| $AWK -F\. '{print $1}'`
                      if [ ! "${_dsk_size_}"  ]; then
                           _err_msg_="Could not get the size of ${_DISK_} in GBytes"
                           abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                      fi
				
                      _disk_unit_="GBytes"
                fi

                 _FSIZE_="${_dsk_size_} ${_disk_unit_}"
                 if [ ! "${_FSIZE_}" ]; then
                       _err_msg_="Could not get the value of _FSIZE_ for ${_DISK_}"
                       abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                 fi
            fi
	  
      else
            $PARTED /dev/mapper/${_DISK_} -s print 2> /dev/null | $AWK '$1+0'| $GREP 1  >> /dev/null 2>&1
            if [ $? -eq 0 ]; then
                 _dsk_size_bps_=`$PARTED /dev/mapper/${_DISK_} -s unit B print 2> /dev/null | $AWK '$1+0'| $AWK -F " " '{print $4}'| $HEAD -1| $SED 's/B$//g'` 2> /dev/null
                 if [ ! "${_dsk_size_bps_}" ]; then
                      _err_msg_="Could not get the value total Bytes for ${_DISK_}1"
                      abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                 fi

                if [[ ${_dsk_size_bps_} -lt 1073741824 ]]; then
                      _dsk_size_=`$EXPR ${_dsk_size_bps_} / 1048576| $AWK -F\. '{print $1}'`
                     if [ ! "${_dsk_size_}" ]; then
                            _err_msg_="Could not get the size of ${_DISK_} in MBytes"
                            abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                     fi
				
                     _disk_unit_="MBytes"

                else
                     _dsk_size_=`$EXPR ${_dsk_size_bps_} / 1073741824| $AWK -F\. '{print $1}'`
                     if [ ! "${_dsk_size_}" ]; then
                            _err_msg_="Could not get the size of ${_DISK_} in GBytes"
                            abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                     fi
				
                     _disk_unit_="GBytes"

                fi

                _FSIZE_="${_dsk_size_} ${_disk_unit_}"
                if [ ! "${_FSIZE_}" ]; then
                       _err_msg_="Could not get the value of _FSIZE_ for ${_DISK_}"
                       abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
                fi
            fi
      fi	

        if [ "${_HBA_}" == "mpxio" ]; then
	    _VENDOR_=`$MULTIPATH -l | $GREP -w ${_DISK_} | $AWK -F " " '{print $4}'`
	    if [ $? -ne 0 ]; then
		_err_msg_="Could not get the value VENDOR for ${_DISK_}"
		abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
	    fi
                
	    _PRODUCT_=`$MULTIPATH -l | $GREP -w ${_DISK_} | $AWK -F " " '{print $5 "-" $6}'| $SED 's/,//g'`
	    if [ $? -ne 0 ]; then
		_err_msg_="Could not get the value of PRODUCT for ${_DISK_}"
		abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
	    fi
			
        else
	    _VENDOR_=`$LSSCSI | $GREP -w ${_DISK_} | $AWK -F " " '{print $3}'`
	    if [ $? -ne 0 ]; then
		_err_msg_="Could not get the value of VENDOR for ${_DISK_}"
		abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
	    fi
			
	    _PRODUCT_=`$LSSCSI | $GREP -w ${_DISK_} | $AWK -F " " '{print $4,$5}'`
	    if [ $? -ne 0 ]; then
		_err_msg_="Could not get the value of PRODUCT for  ${_DISK_}"
		abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
	    fi
        fi

        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        if [ "${DEBUG}" ]
        then
            $ECHO $_DISK_":"$_HBA_":"$_FSIZE_":"$_VENDOR_":"$_PRODUCT_
        fi
        #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            $ECHO $_DISK_":"$_HBA_":"$_FSIZE_":"$_VENDOR_":"$_PRODUCT_ >> ${_disk_information_}
            if [ $? -ne 0 ]; then
                _err_msg_="Could not add disk detrails in ${_disk_information_} for ${_DISK_}"
                abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
            fi
  done < ${_disk_hba_list_}


  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "\n"
      $ECHO "FILE: _disk_information_" 
	  $CAT ${_disk_information_}
      $ECHO "\n"
  elif [ "${VERBOSE}" ]
  then
      $ECHO "\n"
  fi
  #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

}

### Function: get_root_devs ###
#
# Get the disk(s) associated with root (/)
#
# Arguments:
#       none
# Return Values:
#       none
##########################################
get_root_devs()
{
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "FUNCTION: get_root_devs"
  elif [ "${VERBOSE}" ]
  then
      $ECHO "Getting root filesystem disks"
      if [ -x $UCBECHO ]
      then
          $UCBECHO -n "."
      fi
  fi
  #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  #Getting the root partition filesystem name
  _root_fs_=`$DF -hk / | $GREP "root" | $AWK -F " " '{print $1}'`
  if [ $? -ne 0 ]; then
      _err_msg_="Could not get the value of _root_fs_"
      abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
  fi
		
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "${_root_fs_} is a LVM filesystem"
  fi
  #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  # Getting root partition's Volume Group name
  _root_vg_=`$ECHO ${_root_fs_} | $AWK -F "/" '{print $4}' |  $AWK -F "-" '{print $1}'`
  if [ $? -ne 0 ]; then
      _err_msg_="Could not get the value of _root_vg_"
      abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
  fi
		
  #>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "Volume Group for root partition is ${_root_vg_}"
  fi
  #<<<<<<<<<<<<<<<<<<<<<<<<<

  #Getting list of root disks including mirrored disk
  $LSBLK | $GREP -vw "fd0" |$GREP -B 4 -w ${_root_vg_} | $GREP -w "disk" | $AWK '{print $1}' | $SED ':a;N;$!ba;s/\n/|/g' > ${_root_disks_}
  if [ $? -ne 0 ]; then
      _err_msg_="Could not get the value of _root_disks_"
      abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
  fi 

  if [ ! -s "${_root_disks_}" ]
  then
      $ECHO "Could not determine root disk details"
      exit 1
  fi

  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if [ "${DEBUG}" ]
  then
      $ECHO "FILE: _root_disks_"
      $CAT ${_root_disks_}
	  if [ $? -ne 0 ]; then
          _err_msg_="Could not display _root_disks_ file"
          abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
	  fi
      $ECHO "\n"
  elif [ "${VERBOSE}" ]
  then
      $ECHO "\n"
  fi
  #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

}


## Function: read_storage_type ###
#
# Arguments:
#   none
# Return Values:
#   set varibale STORAGE_TYPE
read_storage_type()
{
# Read the storage type
if [ -s ${ENIQ_CONF_DIR}/SunOS.ini ]; then
    STORAGE_TYPE=`iniget STOR_TYPE -f ${ENIQ_CONF_DIR}/SunOS.ini -v STORAGE_TYPE`
else
    if [ -s /eniq/installation/config/san_details ]; then
        STORAGE_TYPE=`$CAT ${ENIQ_CONF_DIR}/san_details | $GREP "^STORAGE_TYPE=" | $AWK -F\= '{print $2}'`
    fi
fi

if [ ! "${STORAGE_TYPE}" ]; then
    _err_msg_="Could not read STORAGE_TYPE param "
    abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
fi

# Read the SAN device type
if [ "${STORAGE_TYPE}" = "raw" ]; then
    if [ -s ${ENIQ_CONF_DIR}/${SUNOS_INI} ]; then
        _san_device_=`iniget SAN_DEV -f ${ENIQ_CONF_DIR}/${SUNOS_INI} -v SAN_DEVICE`
    else
        if [ -s ${ENIQ_CONF_DIR}/san_details ]; then
            _san_device_=`$CAT ${ENIQ_CONF_DIR}/san_details | $EGREP "^SAN_DEVICE=" | $AWK -F\= '{print $2}'`
        fi
    fi

else
    #Setting SAN DEVICE value for Rack
    _san_device_="local"
fi

if [ ! "${_san_device_}" ]; then
    _err_msg_="Could not read _san_device_ param"
    abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
fi

#>>>>>>>>>>>>>>>>>>>>
    if [ "${DEBUG}" ]
    then
	$ECHO "STORAGE_TYPE : ${STORAGE_TYPE}"
        $ECHO "\n"
    elif [ "${VERBOSE}" ]
    then
        $ECHO "\n"
    fi
#<<<<<<<<<<<<<<<<<<<<
}

### Function: usage_msg ###
#
#   Print out usage message
#
# Arguments:
#       none
# Return Values:
#       none
###########################
usage_msg()
{
  $ECHO "
  Usage: `$BASENAME $0` [ -f -d <delim_string>  ] [ -r ] [ -v ] [ -D ]

  options:

  -f  : Print the full details of the disk in a formatted output

  -d  : Delimiter for formatted output. Each field will be delimited
        by this string

  -r  : Return list of disks without the root disk(s). Any SVM root mirror(s)
        will also be excluded. Any ZFS root pool disks will be excluded

  -v  : Verbose output. This is optional.
  
  -D  : Detailed execution of the script. This is optional.
  "
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Main Program
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
RUN_TIME=`$DATE '+%Y-%b-%d_%H.%M.%S'`

# Determine absolute path to software
get_absolute_path

while getopts ":d:e:fmnrRvD" arg
do
  case $arg in
      d)  DELIMITER="$OPTARG" ;;
      f)  FMT_OUTPUT="YES" ;;
      r)  EXCLUDE_ROOT_DISKS="YES" ;;
      v)  VERBOSE="Y" ;;
      D)  DEBUG="Y" ;;
      *)  usage_msg
          exit 1 ;;
  esac
done

check_id root

if [ "${DELIMITER}" ]
then
    if [ ! "${FMT_OUTPUT}" ]
    then
        usage_msg
        exit 1
    fi
fi

if [ "${DELIMITER}" ]
then
    PG=$CAT
fi

#Read the storage type
read_storage_type
if [ $? -ne 0 ]; then
    _err_msg_="Could not get the value of storage type"
    abort_script "${_err_msg_}" "${EXEC_SHELL_CMD}"
fi

if [ "${EXCLUDE_ROOT_DISKS}" ]
then
    get_root_devs
fi

get_disks_details_list


   
if [ ! "${FMT_OUTPUT}" ]
    then
    display_disk_information
    exit
fi
    
get_included_disks_sizes

display_disk_information

exit 0
