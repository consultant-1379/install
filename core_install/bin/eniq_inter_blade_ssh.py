#!/usr/bin/python

import sys
import os
import subprocess

sys.path.insert(0, '/ericsson/security/bin')
from inter_blade_access import enable_internal_root_ssh_access


host = []
with open("/eniq/sw/conf/server_types",'r') as a_file:
    for line in a_file:
        hostname = line.strip().split('::')
        hostname = hostname[-2]
        #print(hostname)
        host.append(hostname)

user_list = []
for var in host:
        user_list.append(var)
#print(user_list)
variable_status = enable_internal_root_ssh_access(user_list)
