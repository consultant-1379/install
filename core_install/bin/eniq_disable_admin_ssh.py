#!/usr/bin/python

import sys
import os
import subprocess

sys.path.insert(0, '/ericsson/security/bin')
from remove_privileged_ssh_access import remove_user_ssh


user_list = []
with open("/eniq/admin/etc/user_removal_data.txt",'r') as a_file:
    for line in a_file:
	user=line.strip()
	
	user_list.append(user)
	
user_status = remove_user_ssh(user_list)


print("Boolean value=",user_status)


