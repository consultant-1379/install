import sys


sys.path.insert(0, '/ericsson/security/bin')
from enable_ssh_login import ssh_user

ssh_status = ssh_user(1)

admin_ssh_enable_output = ssh_status

print(admin_ssh_enable_output)
print "Boolean value=",admin_ssh_enable_output
