import sys

sys.path.insert(0, '/ericsson/security/bin')
from ssh_rollback_adminrole import rollback_ssh_eniq_admin_role

variable_status = rollback_ssh_eniq_admin_role ()

#print(variable_status)

print "Boolean value=",variable_status
