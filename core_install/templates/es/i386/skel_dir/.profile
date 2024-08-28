# ----------------------------------------------------------------------
# Ericsson Network IQ dcuser bash_profile-file
#
# ----------------------------------------------------------------------
# Copyright (c) 1999 - 2006 AB LM Ericsson Oy  All rights reserved.
# ----------------------------------------------------------------------
_server_type_=`cat /eniq/installation/config/installed_server_type 2>/dev/null`
_os_=`uname`
if [ "${_os_}" == "SunOS" ]; then
	PS1=`uname -n`'[${_server_type_}] '\{`/usr/ucb/whoami`\}' #: '
	export PS1
fi

if [ "${_os_}" == "Linux" ]; then
	PS1=`uname -n`'[${_server_type_}] '\{`/usr/bin/whoami`\}' #: '
	export PS1
	# For Linux OS only
	# Set java path
	PATH=$PATH:$HOME/bin
	export JAVA_HOME="/usr/java/jdk1.6.0_30"
	export HQ_JAVA_HOME=$JAVA_HOME
	export PATH
fi


	# Sybase IQ related environment variables
	
	SYBASE=/eniq/sybase_iq
	export SYBASE
	

	SQLANY16=/eniq/sql_anywhere
	export SQLANY16
	
	SQLANY11=/eniq/sql_anywhere
	export SQLANY11
	
	SQLANY=/eniq/sql_anywhere
	export SQLANY

	IQTMP16=/eniq/database/tmp/iq
	export IQTMP16
	
        SATMP16=/eniq/database/tmp/iq
        export SATMP16

	. ${SYBASE}/IQ.sh 1>/dev/null 

# Internal directory variable

        CONF_DIR=/eniq/sw/conf
        export CONF_DIR

        BIN_DIR=/eniq/sw/bin
        export BIN_DIR

        RT_DIR=/eniq/sw/runtime
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

        LD_LIBRARY_PATH_64=${LD_LIBRARY_PATH_64}:${SQLANY11}/lib64
        export LD_LIBRARY_PATH_64

DISPLAY=127.0.0.1:0.0
export DISPLAY

TERM=vt100
export TERM

# Aliases
alias ll='ls -l'

# Misc
umask 027
