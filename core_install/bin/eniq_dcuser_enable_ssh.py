#!/usr/bin/python

import sys
import os
import subprocess

sys.path.insert(0, '/ericsson/security/bin')
#from dcuser_ssh_login import enable_internal_dcuser_ssh_access

host = []
user_list = ""
with open("/eniq/sw/conf/server_types",'r') as a_file:
    for line in a_file:
        hostname = line.strip().split('::')
        hostname = hostname[-2]
        user_list += hostname+","
    #print(user_list.strip(","))
user_list = user_list.strip(",")

#print(user_list)
os.system("/ericsson/security/bin/dcuser_ssh_login.py %s" % user_list)
