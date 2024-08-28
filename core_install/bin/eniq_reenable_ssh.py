import sys


sys.path.insert(0, '/ericsson/security/bin')
from reenable_ssh_login import reenable_ssh_login

#ssh_status = ssh_user(1)
reenable_ssh_output = reenable_ssh_login()

print(reenable_ssh_output)
#print "Boolean value is ",admin_ssh_enable_output
