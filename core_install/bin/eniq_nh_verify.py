import sys

sys.path.insert(0, '/ericsson/security/bin')
from nh_verification import nh_check

variable_status = nh_check()

print "Boolean value=",variable_status

