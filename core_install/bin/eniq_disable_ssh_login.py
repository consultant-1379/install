import sys

sys.path.insert(0, '/ericsson/security/bin')
from disable_ssh_login import disable_ssh_access


status = disable_ssh_access()
#disable_ssh_output = disable_ssh_access()

#print(disable_ssh_output)
