#!/bin/bash
# ********************************************************************
# Ericsson Radio Systems AB                                     SCRIPT
# ********************************************************************
#
#
# (c) Ericsson Radio Systems AB 2017 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson Radio Systems AB, Sweden. The programs may be used 
# and/or copied only with the written permission from Ericsson Radio 
# Systems AB or in accordance with the terms and conditions stipulated 
# in the agreement/contract under which the program(s) have been 
# supplied.
#
# Name    : label_disk_template.sh
# Date    : 24/01/2017
# Revision: D 
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
DATE=/usr/bin/date
DD=/usr/bin/dd
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
IOSTAT=/usr/bin/iostat
LS=/usr/bin/ls
MKDIR=/usr/bin/mkdir
MORE=/usr/bin/more
MPATHADM=/usr/sbin/mpathadm
MV=/usr/bin/mv
NAWK=/usr/bin/nawk
NETSTAT=/usr/bin/netstat
OD=/usr/bin/od
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
DEF_SMI_PART=0
DEF_EFI_PART=0
SUN_ARCH=`$UNAME -p`

# Default first sector for partition 0 on EFI labelled disks.
# Clarion uses 64k stripes.  We need to align IO on 64k allocation units.
# The first data sector should start at 128 (or multiples of 128)
FIRST_SECTOR_OFFSET=128

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

dump_disk()
{
  TS=`$DATE +"%Y%m%d%H%M%S"`
  ${ECHO} "******************************" >> ${DEBUG_LOG} 2>&1
  ${ECHO} "${TS} Start dump_disk" >> ${DEBUG_LOG} 2>&1
  ${ECHO} "******************************" >> ${DEBUG_LOG} 2>&1

  INPUT=$1
  ${ECHO} "Running ${CFGADM} -al" >> ${DEBUG_LOG} 2>&1
  ${CFGADM} -al >> ${DEBUG_LOG} 2>&1

  ${ECHO} "Running ${MPATHADM} show LU" >> ${DEBUG_LOG} 2>&1
  ${MPATHADM} show LU >> ${DEBUG_LOG} 2>&1

  ${ECHO} "Running ${ECHO} | ${FORMAT}" >> ${DEBUG_LOG} 2>&1
  ${ECHO} | ${FORMAT} >> ${DEBUG_LOG} 2>&1

  ${ECHO} "Running ${IOSTAT} -En" >> ${DEBUG_LOG} 2>&1
  ${IOSTAT} -En >> ${DEBUG_LOG} 2>&1

  ${ECHO} "Running ${PRTVTOC} ${INPUT}" >> ${DEBUG_LOG} 2>&1
  ${PRTVTOC} ${INPUT} >> ${DEBUG_LOG} 2>&1

  ${ECHO} "Running ${PRTVTOC} /dev/rdsk/${DISK}" >> ${DEBUG_LOG} 2>&1
  ${PRTVTOC} /dev/rdsk/${DISK} >> ${DEBUG_LOG} 2>&1

  # Dump first 34 512b blocks
  ${ECHO} "Running ${DD} if=${INPUT} bs=512 count=34 | ${OD} -c" >> ${DEBUG_LOG} 2>&1
  ${DD} if=${INPUT} bs=512 count=34 2>> ${DEBUG_LOG} | ${OD} -c >> ${DEBUG_LOG} 2>&1

  # Dump first 34 512b blocks
  ${ECHO} "Running ${DD} if=/dev/rdsk/${DISK} bs=512 count=34 | ${OD} -c" >> ${DEBUG_LOG} 2>&1
  ${DD} if=/dev/rdsk/${DISK} bs=512 count=34 2>> ${DEBUG_LOG} | ${OD} -c >> ${DEBUG_LOG} 2>&1

  TS=`$DATE +"%Y%m%d%H%M%S"`
  ${ECHO} "****************************" >> ${DEBUG_LOG} 2>&1
  ${ECHO} "${TS} End dump_disk" >> ${DEBUG_LOG} 2>&1
  ${ECHO} "****************************" >> ${DEBUG_LOG} 2>&1
}

# ********************************************************************
#
# 	Main body of program
#
# ********************************************************************

# Determine absolute path to software
get_absolute_path

# Check that the effective id of the user is root
check_id root

while getopts ":d:D:S:qt:" arg; do
  case $arg in
    d) DISK="$OPTARG"
       ;;
    D) DISKLABEL_DIR="$OPTARG"
       ;;
    q) QUIET_LABEL="Y"
       ;;
    S) SCRIPT_DIR="$OPTARG"
       ;;
    t) LABEL_TYPE="$OPTARG"
       ;;
   \?) exit 1
       ;;
  esac
done
shift `expr $OPTIND - 1`

if [ ! "${DISK}" -a ! "${DISKLABEL_DIR}" -a ! "${SCRIPT_DIR}" ]; then
    exit 1
fi

if [ "${LABEL_TYPE}" ]; then
    if [ "${LABEL_TYPE}" != "SMI" -a "${LABEL_TYPE}" != "EFI" ]; then
	exit 1
    fi
else
    LABEL_TYPE="SMI"
fi
 
if [ ! "${QUIET_LABEL}" ]; then
    $ECHO "Labeling ${DISK}"
fi

#
# Create debug log file
#
${MKDIR} -p /var/tmp/debug
TIMESTAMP=`$DATE +"%Y%m%d%H%M%S"`
DEBUG_LOG="/var/tmp/debug/${TIMESTAMP}_${DISK}_label_disk_template.sh_debug_log"
${TOUCH} ${DEBUG_LOG}

${ECHO} "DISK = ${DISK}" >> ${DEBUG_LOG} 2>&1
${ECHO} "DISKLABEL_DIR = ${DISKLABEL_DIR}" >> ${DEBUG_LOG} 2>&1
${ECHO} "SCRIPT_DIR = ${SCRIPT_DIR}" >> ${DEBUG_LOG} 2>&1
${ECHO} "LABEL_TYPE = ${LABEL_TYPE}" >> ${DEBUG_LOG} 2>&1

dump_disk /dev/rdsk/${DISK}s2

# Test if disk has a valid vtoc
${ECHO} "Running $PRTVTOC /dev/rdsk/${DISK}s2" >> ${DEBUG_LOG} 2>&1
$PRTVTOC /dev/rdsk/${DISK}s2 >> ${DEBUG_LOG} 2>&1

$PRTVTOC /dev/rdsk/${DISK}s2 >>/dev/null 2>&1
if [ $? -ne 0 ]; then
    _valid_vtoc_=0
else
    _valid_vtoc_=1
fi

${ECHO} "_valid_vtoc_ = ${_valid_vtoc_}" >> ${DEBUG_LOG} 2>&1

# Does it have a valid vtoc
if [ ${_valid_vtoc_} -eq 1 ]; then
    # This is required to ensure we blow away SVM metadb info
    ${ECHO} "Running $DD if=/dev/zero of=/dev/rdsk/${DISK}s5 oseek=16 bs=512 count=1" >> ${DEBUG_LOG} 2>&1
    $DD if=/dev/zero of=/dev/rdsk/${DISK}s5 oseek=16 bs=512 count=1 >> /dev/null 2>&1
    # This is required to ensure we blow away VXVM fencing info
    ${ECHO} "Running $DD if=/dev/zero of=/dev/rdsk/${DISK}s2 bs=2048 count=1000" >> ${DEBUG_LOG} 2>&1
    $DD if=/dev/zero of=/dev/rdsk/${DISK}s2 bs=2048 count=1000 >> /dev/null 2>&1
fi

dump_disk /dev/rdsk/${DISK}s2

if [ "${SUN_ARCH}" = "i386" ]; then
    dump_disk /dev/rdsk/${DISK}p0
    # Remove any previous partitions
    $RM -f /tmp/fdisk_file.${DISK}p0
    ${ECHO} "Running $DD if=/dev/zero of=/dev/rdsk/${DISK}p0 bs=2048 count=1000" >> ${DEBUG_LOG} 2>&1
    $DD if=/dev/zero of=/dev/rdsk/${DISK}p0 bs=2048 count=1000 >> /dev/null 2>&1

    # Put an FDISK partition on the disk
    ${ECHO} "Running $FDISK -B \"/dev/rdsk/${DISK}p0\"" >> ${DEBUG_LOG} 2>&1
    $FDISK -B "/dev/rdsk/${DISK}p0" >> /dev/null 2>&1
    dump_disk /dev/rdsk/${DISK}p0
else
    ${ECHO} "${DISKLABEL_DIR}/label_vtoc =" >> ${DEBUG_LOG} 2>&1
    ${CAT} ${DISKLABEL_DIR}/label_vtoc >> ${DEBUG_LOG} 2>&1
    ${ECHO} "Running $FORMAT -e -s -d ${DISK} -f ${DISKLABEL_DIR}/label_vtoc" >> ${DEBUG_LOG} 2>&1
    $FORMAT -e -s -d ${DISK} -f ${DISKLABEL_DIR}/label_vtoc >> /dev/null 2>&1
    dump_disk /dev/rdsk/${DISK}s2
fi

_vtoc_file_=${SCRIPT_DIR}/prtvtoc_${DISK}
${ECHO} "Running $PRTVTOC /dev/rdsk/${DISK}s2 2>/dev/null > ${_vtoc_file_}" >> ${DEBUG_LOG} 2>&1
$PRTVTOC /dev/rdsk/${DISK}s2 >> ${DEBUG_LOG} 2>&1
$PRTVTOC /dev/rdsk/${DISK}s2 2>/dev/null > ${_vtoc_file_}
if [ $? -ne 0 ]; then
    $ECHO "\nCould not read new VTOC of disk ${DISK}"
    exit 1
fi

# If the required Disk Label type is SMI, I need to check whether, the disk is greater 
# than 1 TB. If it is, I will need to make an EFI label
if [ "${LABEL_TYPE}" = "SMI" ]; then
    # Get number of bytes per sector
    _bps_=`$CAT ${_vtoc_file_} |$NAWK '/bytes\/sector/ {print $2}'`

    _access_sectors_=`$CAT ${_vtoc_file_} |$EGREP '^[ 	]*\*.*accessible[ 	]+sectors'|$NAWK '{print \$2}'`
    if [ "${_access_sectors_}" ]; then
        # Subtract 16384 sectors because of EFI label
	_num_sec_=`$EXPR ${_access_sectors_} - 16384`
    else
	_access_cyls_=`$CAT ${_vtoc_file_} |$EGREP '^[ 	]*\*.*accessible[ 	]+cylinders'|$NAWK '{print $2}'`
	_sec_cyl_=`$CAT ${_vtoc_file_} |$EGREP '^[ 	]*\*.*sectors\/cylinder'|$NAWK '{print $2}'`
	_num_sec_=`$EXPR ${_access_cyls_} \* ${_sec_cyl_}`
    fi
    _dsk_size_bytes_=`$EXPR ${_bps_} \* ${_num_sec_}`

    # A TByte in bytes
    tb_in_bytes=1099511627776

    if [ ${_dsk_size_bytes_} -ge ${tb_in_bytes} ]; then
	LABEL_TYPE="EFI"
    fi
fi

${ECHO} "LABEL_TYPE = ${LABEL_TYPE}" >> ${DEBUG_LOG} 2>&1

_err_loop_cnt_=1
while [ ${_err_loop_cnt_} -le 3 ]; do
# Do I need to create an EFI label
    if [ "${LABEL_TYPE}" = "EFI" ]; then
	if [ "${SUN_ARCH}" = "i386" ]; then
        # I need to put an FDISK partition on the disk
            ${ECHO} "Running $FDISK -E \"/dev/rdsk/${DISK}p0\"" >> ${DEBUG_LOG} 2>&1
	    $FDISK -E "/dev/rdsk/${DISK}p0" >> /dev/null 2>&1
	    if [ $? -ne 0 ]; then
                dump_disk /dev/rdsk/${DISK}p0
		_err_loop_cnt_=`$EXPR ${_err_loop_cnt_} + 1`
		continue
	    fi
            dump_disk /dev/rdsk/${DISK}p0
	fi
        ${ECHO} "${DISKLABEL_DIR}/label_smi_efi_sparc =" >> ${DEBUG_LOG} 2>&1
        ${CAT} ${DISKLABEL_DIR}/label_smi_efi_sparc >> ${DEBUG_LOG} 2>&1
        ${ECHO} "Running $FORMAT -e -s -d ${DISK} -f ${DISKLABEL_DIR}/label_smi_efi_sparc" >> ${DEBUG_LOG} 2>&1
	$FORMAT -e -s -d ${DISK} -f ${DISKLABEL_DIR}/label_smi_efi_sparc >> /dev/null 2>&1
	if [ $? -ne 0 ]; then
            dump_disk /dev/rdsk/${DISK}s2
	    _err_loop_cnt_=`$EXPR ${_err_loop_cnt_} + 1`
	    continue
	fi
        dump_disk /dev/rdsk/${DISK}s2
    else
	if [ "${SUN_ARCH}" = "i386" ]; then
        # I need to put an FDISK partition on the disk
            ${ECHO} "Running $FDISK -B \"/dev/rdsk/${DISK}p0\"" >> ${DEBUG_LOG} 2>&1
	    $FDISK -B "/dev/rdsk/${DISK}p0" >> /dev/null 2>&1
	    if [ $? -ne 0 ]; then
                dump_disk /dev/rdsk/${DISK}p0
		_err_loop_cnt_=`$EXPR ${_err_loop_cnt_} + 1`
		continue
	    fi
            dump_disk /dev/rdsk/${DISK}p0
	fi
        ${ECHO} "${DISKLABEL_DIR}/label_smi_smi_sparc =" >> ${DEBUG_LOG} 2>&1
        ${CAT} ${DISKLABEL_DIR}/label_smi_smi_sparc >> ${DEBUG_LOG} 2>&1
        ${ECHO} "Running $FORMAT -e -s -d ${DISK} -f ${DISKLABEL_DIR}/label_smi_smi_sparc" >> ${DEBUG_LOG} 2>&1
	$FORMAT -e -s -d ${DISK} -f ${DISKLABEL_DIR}/label_smi_smi_sparc >> /dev/null 2>&1
	if [ $? -ne 0 ]; then
            dump_disk /dev/rdsk/${DISK}s2
	    _err_loop_cnt_=`$EXPR ${_err_loop_cnt_} + 1`
	    continue
	fi
        dump_disk /dev/rdsk/${DISK}s2
    fi
    break
done

if [ ${_err_loop_cnt_} -ge 3 ]; then
    $ECHO "Could not write known label to ${DISK}"
    $RM -rf ${TEM_DIR}
    exit 1
fi

# Create file to hold new vtoc
_new_vtoc_file_=${SCRIPT_DIR}/new_prtvtoc_${DISK}
_part_list_=${SCRIPT_DIR}/part_list_${DISK}
$RM -f  ${_new_vtoc_file_}

# Get the partition info for the disk 
${ECHO} "Running $PRTVTOC /dev/rdsk/${DISK}s2 2>/dev/null > ${_vtoc_file_}" >> ${DEBUG_LOG} 2>&1
$PRTVTOC /dev/rdsk/${DISK}s2 >> ${DEBUG_LOG} 2>&1
$PRTVTOC /dev/rdsk/${DISK}s2 2>/dev/null > ${_vtoc_file_}

# Get the partition details for all system partitions 
$CAT  ${_vtoc_file_}| $EGREP -v '^[ 	]*\*'                       \
    | $EGREP -v '^[ 	]*[0-9]+[ 	]+(2|3|4|5|6|7|8)[ 	]+' \
    | $NAWK '{print $4"@@"$5"@@"$6}' | $SORT -k 1,1n > ${_part_list_}

# Got to figure out the starting sector
_first_sector_offset_=0
_last_sector_offset_=0
for _part_det_ in `$CAT ${_part_list_}`; do
    _first_sec_=`$ECHO ${_part_det_}|$NAWK -F"@@" '{print $1}'`
    _sec_cnt_=`$ECHO ${_part_det_}|$NAWK -F"@@" '{print $2}'`
    _last_sec_=`$ECHO ${_part_det_}|$NAWK -F"@@" '{print $3}'`

    # Does this partition start at sector zero. If so set my offset to
    # the last sector + 1
    if [ ${_first_sec_} -eq 0 ]; then
	_first_sector_offset_=`$EXPR ${_last_sec_} + 1`
    else
	# Does this partition start at my existing ${_first_sector_offset_}. 
	# If so, I will assume it is a continuation of offset from start of
	# disk and set my offset to the last sector + 1
	if [ ${_first_sec_} -eq ${_first_sector_offset_} ]; then
	    _first_sector_offset_=`$EXPR ${_last_sec_} + 1`
	else 
            # Assume this is the offset from end of disk
	    _last_sector_offset_=`$EXPR ${_first_sec_} - 1`
	fi
    fi
done

# Did we get a start sector offset
if [ ${_first_sector_offset_} -eq 0 ]; then
    if [ "${LABEL_TYPE}" = "SMI" ]; then
        # We will not use the first cylinder. We will get the number of sectors 
        # per cylinder and start the partition there. 
	_first_sector_offset_=`$CAT ${_vtoc_file_} |$EGREP '^[ 	]*\*.*sectors\/cylinder'|$NAWK '{print $2}'`
    else
        # We will set the offset to the standard EFI offset (was 34)
	_first_sector_offset_=${FIRST_SECTOR_OFFSET}
    fi
fi

if [ "${LABEL_TYPE}" = "SMI" ]; then
    # Read original sector details
    _backup_label_details_=`$CAT ${_vtoc_file_}|$EGREP '^[ 	]*2[ 	]+5[ 	]+`
    _old_sec_count_=`$ECHO ${_backup_label_details_}|$NAWK '{print $5}'`
    _user_part_=${DEF_SMI_PART}
else
    _user_part_=${DEF_EFI_PART}
fi

if [ ${_last_sector_offset_} -eq 0 ]; then
    _last_sector_offset_=`$ECHO ${_backup_label_details_}|$NAWK '{print $6}'`
fi

# Get the new sector count
_new_sec_count_=`$EXPR ${_last_sector_offset_} - ${_first_sector_offset_} + 1`

$ECHO "${_user_part_} 4 00 ${_first_sector_offset_} ${_new_sec_count_} ${_last_sector_offset_}" >> ${_new_vtoc_file_}
# Get the partition details for all system partitions 
$CAT  ${_vtoc_file_}| $EGREP -v '^[ 	]*\*'                       \
    | $EGREP -v '^[ 	]*[0-9]+[ 	]+(2|3|4|6|7|8)[ 	]+' \
    >> ${_new_vtoc_file_}

${ECHO} "${_new_vtoc_file_} =" >> ${DEBUG_LOG} 2>&1
${CAT} ${_new_vtoc_file_} >> ${DEBUG_LOG} 2>&1
${ECHO} "Running $FMTHARD -s ${_new_vtoc_file_} /dev/rdsk/${DISK}s2" >> ${DEBUG_LOG} 2>&1
$FMTHARD -s ${_new_vtoc_file_} /dev/rdsk/${DISK}s2 >> /dev/null 2>&1
dump_disk /dev/rdsk/${DISK}s2

exit 0
