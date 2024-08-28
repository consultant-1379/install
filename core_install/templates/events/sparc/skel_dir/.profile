# ----------------------------------------------------------------------
# Ericsson Network IQ dcuser bash_profile-file
#
# ----------------------------------------------------------------------
# Copyright (c) 1999 - 2006 AB LM Ericsson Oy  All rights reserved.
# ----------------------------------------------------------------------
PS1=`uname -n`\{`/usr/ucb/whoami`\}' #: '
export PS1

# Sybase IQ related environment variables

SYBASE=<CHANGE><IQ_SYB_DIR>
export SYBASE

SQLANY11=<CHANGE><ASA_SYB_DIR>
export SQLANY11

. ${SYBASE}/SYBASE.sh

# Internal directory variable

CONF_DIR=<CHANGE><CONF_DIR>
export CONF_DIR

BIN_DIR=<CHANGE><BIN_DIR>
export BIN_DIR

RT_DIR=<CHANGE><RT_DIR>
export RT_DIR

# ASN.1 library stuff
OSS_ASN1_JAVA="${RT_DIR}/nokalva/asn1pjav/solaris.tgt/3.0"
export OSS_ASN1_JAVA

OSSINFO=${OSS_ASN1_JAVA}
export OSSINFO

# Path extension
PATH=${PATH}:${OSS_ASN1_JAVA}:/usr/local/bin:${BIN_DIR}
export PATH

LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${OSS_ASN1_JAVA}/lib:${SQLANY11}/lib64
export LD_LIBRARY_PATH

DISPLAY=127.0.0.1:0.0
export DISPLAY

TERM=vt100
export TERM

# Aliases
alias ll='ls -l'

# Misc
umask 027

