#!/bin/bash
# ********************************************************************
# Ericsson Radio Systems AB                                     SCRIPT
# ********************************************************************
#
#
# (c) Ericsson Radio Systems AB 2001 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Radio Systems AB, Sweden. The programs may be used 
# and/or copied only with the written permission from Ericsson Radio 
# Systems AB or in accordance with the terms and conditions stipulated 
# in the agreement/contract under which the program(s) have been 
# supplied.
#
# Name    : label_disks
# Date    : 01/11/2016
# Revision: B
# Purpose : This function will label a disk.
#
#
#	    NOTE : THIS IS A DESTRUCTIVE SCRIPT. USE CAREFULLY
# Revision
# History :
# ********************************************************************

# ********************************************************************
#
#       ERROR CODE DEFINITION
#
# ********************************************************************
# ERROR 
# CODE  EXPLANATION
#

# ********************************************************************
#
# 	Command Section
#
# ********************************************************************
AWK=/usr/bin/awk
BASENAME=/usr/bin/basename
CAT=/usr/bin/cat
CFGADM=/usr/sbin/cfgadm
CHMOD=/usr/bin/chmod
CLEAR=/usr/bin/clear
CP=/usr/bin/cp
CUT=/usr/bin/cut
DEVFSADM=/usr/sbin/devfsadm
DF=/usr/bin/df
DFSHARES=/usr/sbin/dfshares
DHCPINFO=/sbin/dhcpinfo
DIRNAME=/usr/bin/dirname
ECHO=/usr/bin/echo
EEPROM=/usr/sbin/eeprom
EGREP=/usr/bin/egrep
ENV=/usr/bin/env
EXPR=/usr/bin/expr
FDISK=/sbin/fdisk
FMTHARD=/usr/sbin/fmthard
FORMAT=/usr/sbin/format
GETBOOTARGS=/sbin/getbootargs
GETENT=/usr/bin/getent
GREP=/usr/bin/grep
HALT=/usr/sbin/halt
HEAD=/usr/bin/head
HOSTNAME=/usr/bin/hostname
ID=/usr/bin/id
IFCONFIG=/usr/sbin/ifconfig
LS=/usr/bin/ls
MKDIR=/usr/bin/mkdir
MORE=/usr/bin/more
MV=/usr/bin/mv
NAWK=/usr/bin/nawk
NETSTAT=/usr/bin/netstat
PG=/usr/bin/pg
PING=/usr/sbin/ping
PS=/usr/bin/ps
PRTCONF=/usr/sbin/prtconf
PRTVTOC=/usr/sbin/prtvtoc
PWD=/usr/bin/pwd
RM=/usr/bin/rm
RCP=/usr/bin/rcp
RSH=/usr/bin/rsh
SED=/usr/bin/sed
SLEEP=/usr/bin/sleep
SORT=/usr/bin/sort
SU=/usr/bin/su
TAIL=/usr/bin/tail
TOUCH=/usr/bin/touch
UNAME=/usr/bin/uname
WC=/usr/bin/wc


# ********************************************************************
#
#       Pre-execution Operations
#
# ********************************************************************
I386=`$UNAME -p|grep -w i386`

SUN_ARCH=`$UNAME -p`

TEM_DIR=/tmp/tem_label_disks

# Determine Solaris OS version
unset SOLARIS_10
OS_VERSION=`$UNAME -r`
if [ "${OS_VERSION}" == "5.10" ]; then
    SOLARIS_10="YES"
fi

# Set executing shell value
RUN_SHL=/usr/bin/sh
if [ ! "${SOLARIS_10}" ]; then
    RUN_SHL=/usr/bin/bash
fi

# ********************************************************************
#
# 	functions
#
# ********************************************************************
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
    $ECHO "You must be $1 to execute this script."
    $RM -rf ${TEM_DIR}
    exit 1
fi
}

### Function: confirm_user_input ###
#
# Confirm with user that values entered are correct
#
# Arguments:
#       none
# Return Values:
#       none
confirm_user_input()
{
while :; do
    $CLEAR
    $PG -p "Press any key to continue" -e  ${TEM_DIR}/temp_disk_list.$$.$$

    $ECHO "\n\nAre you sure you wish to label the disks above [Y/Nn] (case sensitive)"
    read USER_CONF
  
    # If the User hit nothing and there is a default. that will do
    if [ ! "${USER_CONF}" ]; then
        continue
    fi

    # Did the user input (Y/y) 
    if [ "${USER_CONF}" = "Y" ]; then
        break
    elif [ "${USER_CONF}" = "N" -o "${USER_CONF}" = "n" ]; then
	break
    else
        :
    fi
done
}

### Function: get_absolute_path ###
#
# Determine absolute path to software
#
# Arguments:
#	none
# Return Values:
#	none
get_absolute_path() 
{
_dir_=`$DIRNAME $0`
SCRIPTHOME=`cd $_dir_ 2>/dev/null && pwd || $ECHO $_dir_`
}

### Function: label_disks ###
#
# Label the list of disks
#
# Arguments:
#       $1 : File containing disks to be labeled
# Return Values:
#       none
label_disks()
{
_disk_list_file_=${1}
_formatting_=0

# This is the first format pass. I will ignore the fact that
# EFI label disks require different label answers
if [ -s ${_disk_list_file_} ]; then 

    # Create the response files
    $MKDIR -p ${TEM_DIR}/script_dir ${TEM_DIR}/disklabel
    $ECHO "label\n0\n\n\n\nq\n" > ${TEM_DIR}/disklabel/label_vtoc
    $ECHO "label\n1\n\n\nq\n" > ${TEM_DIR}/disklabel/label_smi_efi_sparc
    $ECHO "label\n0\n\n\nq\n" > ${TEM_DIR}/disklabel/label_smi_smi_sparc
    cnt=0

    # Do I do this quietly
    if [ ! "${QUIET_LABEL}" ]; then
	$ECHO "Labeling Disks...Please Wait"
    fi
    for _dsk_ in `$CAT ${_disk_list_file_}`; do
	_formatting_=1

	if [ "${LABEL_TYPE}" ]; then 
	    ${RUN_SHL} ${SCRIPTHOME}/label_disk_template.sh -d ${_dsk_} -D "${TEM_DIR}/disklabel" -S "${TEM_DIR}/script_dir" -t ${LABEL_TYPE} "${QUIET_LABEL}"  &
	else
	    ${RUN_SHL} ${SCRIPTHOME}/label_disk_template.sh -d ${_dsk_} -D "${TEM_DIR}/disklabel" -S "${TEM_DIR}/script_dir" "${QUIET_LABEL}"  &
	fi

        cnt=`$EXPR $cnt + 1`
        if [ $cnt -eq 25 ]; then
	    cnt=0
	    wait
	fi

    done
fi
if [ ${_formatting_} -eq 1 ]; then
    while :; do
	$PS -eaf|$GREP -vw grep|$GREP "\/label_disk_template.sh" >> /dev/null 2>&1
	if [ $? -ne 0 ]; then
	    break
	fi
	$SLEEP 2
    done
fi
wait
}

### Function: usage_msg ###
#
#   Print out the usage message
#
# Arguments:
#   none
# Return Values:
#   none
usage_msg() 
{
$CLEAR
$ECHO "Usage: `$BASENAME $0` { -d <disk1,disk2,....,diskn> | -f <path_disk_file> } [ -t {EFI|SMI} ] 
                      
options:

-d  : Parameter specifying the list of disk(s) that are to be labeled.
      The disk designation must be as appears in the /usr/sbin/format 
      command. 
      Multiple disks can be specified by delimiting each of the disks
      specified with a comma (No Spaces).

      E.g. -d c1t0d0,c1t1d0,c2t0d0,c2t1d0

-f  : Parameter specifying the full path to the file which contains  
      a list of disk(s) that are to be labeled. Each line can only contain
      one disk and the disk designation must be as appears in the 
      /usr/sbin/format command.

      E.g. c1t0d0
           c1t1d0
           c2t0d0
           c2t1d0

-t  : Optional parameter specifying the disk label type {EFI|SMI}. If not 
      specfied, then SMI label will be applied.
      
NOTE : There will be one user partition supplied on the disk after labelling.
       It can be identified from the prtvtoc command eg.

       prtvtoc /dev/rdsk/c1t3d0s2|nawk '{if (\$2 == 4)print \$0}'

"
}

# ********************************************************************
#
# 	Main body of program
#
# ********************************************************************
#
# Determine absolute path to software
get_absolute_path

# Check that the effective id of the user is root
check_id root

while getopts ":d:f:Nqt:" arg; do
  case $arg in
    d) DISK_LIST="$OPTARG"
       ;;
    f) DISK_FILE_LIST="$OPTARG"
       ;;
    N) NO_CONFIRM="YES"
       ;;
    q) QUIET_LABEL="Y"
       ;;
    t) LABEL_TYPE="$OPTARG"
       ;;
   \?) usage_msg
       exit 1
       ;;
  esac
done
shift `expr $OPTIND - 1`

if [ ! "${DISK_FILE_LIST}" -a ! "${DISK_LIST}" ]; then
    usage_msg
    exit 1
fi

if [ "${DISK_FILE_LIST}" -a "${DISK_LIST}" ]; then
    usage_msg
    exit 1
fi

if [ "${LABEL_TYPE}" ]; then
    if [ "${LABEL_TYPE}" != "SMI" -a "${LABEL_TYPE}" != "EFI" ]; then
	usage_msg
	exit 1
    fi
fi
 
if [ ! -s ${SCRIPTHOME}/label_disk_template.sh ]; then
    $ECHO "File ${SCRIPTHOME}/label_disk_template.sh\n does not exist or is empty"
    $RM -rf ${TEM_DIR}
    exit 1
fi

if [ ! "${QUIET_LABEL}" ]; then
    QUIET_LABEL=""
fi
 
# Loop until I get a unique name for the tem DIR
while :; do
    $LS ${TEM_DIR} >> /dev/null 2>&1
    if [ $? -ne 0 ]; then
        break
    fi
    TEM_DIR=${TEM_DIR}.$$
done

# Make the temporary directory.
$MKDIR -p ${TEM_DIR}
if [ $? -ne 0 ]; then
    $ECHO "Error creating directory ${TEM_DIR}"
    exit 1
fi

$RM -f ${TEM_DIR}/temp_disk_list.$$.$$ ${TEM_DIR}/temp_disk_list1.$$.$$
if [ "${DISK_FILE_LIST}" ]; then
    if [ ! -s ${DISK_FILE_LIST} ]; then
	$ECHO "Disk file does not exist or is empty"
	$RM -rf ${TEM_DIR}
	exit 1
   fi
    $CP ${DISK_FILE_LIST} ${TEM_DIR}/temp_disk_list.$$.$$
else
    $RM -f ${TEM_DIR}/temp_disk_list.$$.$$
    for _disk_ in `$ECHO ${DISK_LIST}|$SED -e 's|,| |g'`; do
	$ECHO ${_disk_} >> ${TEM_DIR}/temp_disk_list1.$$.$$
    done
    $CAT ${TEM_DIR}/temp_disk_list1.$$.$$ |$SORT -u > ${TEM_DIR}/temp_disk_list.$$.$$
fi

# Check that all disks specified are correct
_err_=0
$FORMAT </dev/null | $EGREP '^[ ]+[0-9]+\.[ ]+' |$NAWK '{print $2}' > ${TEM_DIR}/total_disk_list
for _dsk_ in `$CAT ${TEM_DIR}/temp_disk_list.$$.$$`; do
    $GREP -w ${_dsk_} ${TEM_DIR}/total_disk_list >> /dev/null 2>&1
    if [ $? -ne 0 ]; then
	if [ "${DISK_FILE_LIST}" ]; then
	    $ECHO "Disk ${_dsk_} specified in file does not exist"
	else
	    $ECHO "Disk ${_dsk_} does not exist"
	fi
	_err_=1
    fi
    if [ ${_err_} -eq 1 ]; then
	exit 1
    fi
done


if [ ! "${NO_CONFIRM}" ]; then
    USER_CONF="N"
    # Confirm the User Input
    confirm_user_input
else
    USER_CONF="Y"
fi

if [ "${USER_CONF}" = "Y" ]; then
    label_disks  "${TEM_DIR}/temp_disk_list.$$.$$"
fi
$RM -rf ${TEM_DIR}
exit 0
