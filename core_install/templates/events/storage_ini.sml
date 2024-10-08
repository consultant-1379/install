;--------------------------------------------------------------------------
; Storage Manager
;--------------------------------------------------------------------------
[Storage]
Storage_NAS_GENERAL
Storage_NAS_FS_LIST

[Storage_NAS_GENERAL]
SYS_ID=<CHANGE><ENIQ_POOL_ID>
POOL_PRI=<CHANGE><ENIQ_POOL_ID>
POOL_SEC=<CHANGE><ENIQ_SEC_POOL_ID>

[Storage_NAS_FS_LIST]
Storage_NAS_ADMIN
Storage_NAS_ARCHIVE
Storage_NAS_BACKUP
Storage_NAS_ETLDATA
Storage_NAS_ETLDATA_00
Storage_NAS_ETLDATA_01
Storage_NAS_ETLDATA_02
Storage_NAS_ETLDATA_03
Storage_NAS_ETLDATA_04
Storage_NAS_ETLDATA_05
Storage_NAS_ETLDATA_06
Storage_NAS_ETLDATA_07
Storage_NAS_ETLDATA_08
Storage_NAS_ETLDATA_09
Storage_NAS_ETLDATA_10
Storage_NAS_ETLDATA_11
Storage_NAS_ETLDATA_12
Storage_NAS_ETLDATA_13
Storage_NAS_ETLDATA_14
Storage_NAS_ETLDATA_15
Storage_NAS_EVENTDATA_00
Storage_NAS_EVENTDATA_01
Storage_NAS_EVENTDATA_02
Storage_NAS_EVENTDATA_03
Storage_NAS_EVENTDATA_04
Storage_NAS_EVENTDATA_05
Storage_NAS_EVENTDATA_06
Storage_NAS_EVENTDATA_07
Storage_NAS_EVENTDATA_08
Storage_NAS_EVENTDATA_09
Storage_NAS_EVENTDATA_10
Storage_NAS_EVENTDATA_11
Storage_NAS_EVENTDATA_12
Storage_NAS_EVENTDATA_13
Storage_NAS_EVENTDATA_14
Storage_NAS_EVENTDATA_15
Storage_NAS_OPENGEO_SW
Storage_NAS_PUSHDATA_00
Storage_NAS_PUSHDATA_01
Storage_NAS_PUSHDATA_02
Storage_NAS_PUSHDATA_03
Storage_NAS_PUSHDATA_04
Storage_NAS_PUSHDATA_05
Storage_NAS_PUSHDATA_06
Storage_NAS_PUSHDATA_07
Storage_NAS_PUSHDATA_08
Storage_NAS_PUSHDATA_09
Storage_NAS_PUSHDATA_10
Storage_NAS_PUSHDATA_11
Storage_NAS_PUSHDATA_12
Storage_NAS_PUSHDATA_13
Storage_NAS_PUSHDATA_14
Storage_NAS_PUSHDATA_15
Storage_NAS_REJECTED
Storage_NAS_GLASSFISH
Storage_NAS_HOME
Storage_NAS_LOG
Storage_NAS_MEDIATION_SW
Storage_NAS_MEDIATION_INTER
Storage_NAS_NORTHBOUND
Storage_NAS_REFERENCE
Storage_NAS_SENTINEL
Storage_NAS_SNAPSHOT
Storage_NAS_SQL_ANYWHERE
Storage_NAS_SYBASE_IQ
Storage_NAS_SW
Storage_NAS_UPGRADE

[Storage_NAS_ADMIN]
FS_NAME=admin
FS_SIZE=2g
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-admin
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/admin
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=create_admin_dir
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ARCHIVE]
FS_NAME=archive
FS_SIZE=8g
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-archive
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/archive
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_BACKUP]
FS_NAME=backup
FS_SIZE=768g
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-backup
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/backup
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA]
FS_NAME=etldata
FS_SIZE=2g
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_00]
FS_NAME=etldata_/00
FS_SIZE=20g
NFS_HOST=nas3
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-00
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/00
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_01]
FS_NAME=etldata_/01
FS_SIZE=20g
NFS_HOST=nas7
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-01
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/01
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_02]
FS_NAME=etldata_/02
FS_SIZE=20g
NFS_HOST=nas4
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-02
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/02
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_03]
FS_NAME=etldata_/03
FS_SIZE=20g
NFS_HOST=nas8
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-03
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/03
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_04]
FS_NAME=etldata_/04
FS_SIZE=1g
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-04
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/04
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_05]
FS_NAME=etldata_/05
FS_SIZE=1g
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-05
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/05
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_06]
FS_NAME=etldata_/06
FS_SIZE=1g
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-06
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/06
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_07]
FS_NAME=etldata_/07
FS_SIZE=1g
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-07
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/07
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_08]
FS_NAME=etldata_/08
FS_SIZE=1g
NFS_HOST=nas3
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-08
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/08
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_09]
FS_NAME=etldata_/09
FS_SIZE=1g
NFS_HOST=nas7
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-09
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/09
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_10]
FS_NAME=etldata_/10
FS_SIZE=1g
NFS_HOST=nas4
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-10
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/10
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_11]
FS_NAME=etldata_/11
FS_SIZE=1g
NFS_HOST=nas8
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-11
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/11
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_12]
FS_NAME=etldata_/12
FS_SIZE=1g
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-12
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/12
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_13]
FS_NAME=etldata_/13
FS_SIZE=1g
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-13
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/13
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_14]
FS_NAME=etldata_/14
FS_SIZE=1g
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-14
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/14
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_ETLDATA_15]
FS_NAME=etldata_/15
FS_SIZE=1g
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-etldata_-15
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/etldata_/15
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_00]
FS_NAME=eventdata/00
FS_SIZE=30g
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-00
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/00
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_01]
FS_NAME=eventdata/01
FS_SIZE=30g
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-01
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/01
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_02]
FS_NAME=eventdata/02
FS_SIZE=30g
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-02
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/02
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_03]
FS_NAME=eventdata/03
FS_SIZE=30g
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-03
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/03
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_04]
FS_NAME=eventdata/04
FS_SIZE=1g
NFS_HOST=nas3
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-04
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/04
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_05]
FS_NAME=eventdata/05
FS_SIZE=1g
NFS_HOST=nas7
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-05
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/05
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_06]
FS_NAME=eventdata/06
FS_SIZE=1g
NFS_HOST=nas4
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-06
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/06
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_07]
FS_NAME=eventdata/07
FS_SIZE=1g
NFS_HOST=nas8
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-07
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/07
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_08]
FS_NAME=eventdata/08
FS_SIZE=1g
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-08
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/08
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_09]
FS_NAME=eventdata/09
FS_SIZE=1g
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-09
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/09
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_10]
FS_NAME=eventdata/10
FS_SIZE=1g
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-10
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/10
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_11]
FS_NAME=eventdata/11
FS_SIZE=1g
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-11
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/11
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_12]
FS_NAME=eventdata/12
FS_SIZE=1g
NFS_HOST=nas3
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-12
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/12
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_13]
FS_NAME=eventdata/13
FS_SIZE=1g
NFS_HOST=nas7
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-13
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/13
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_14]
FS_NAME=eventdata/14
FS_SIZE=1g
NFS_HOST=nas4
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-14
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/14
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_EVENTDATA_15]
FS_NAME=eventdata/15
FS_SIZE=1g
NFS_HOST=nas8
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-eventdata-15
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pmdata/eventdata/15
NFS_SHARE_OPTIONS="rw,async,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_OPENGEO_SW]
FS_NAME=opengeo_sw
FS_SIZE=1g
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-opengeo_sw
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/opengeo_sw
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=create_directories
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_PUSHDATA_00]
FS_NAME=pushdata/00
FS_SIZE=640m
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-00
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/00
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_01]
FS_NAME=pushdata/01
FS_SIZE=640m
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-01
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/01
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_02]
FS_NAME=pushdata/02
FS_SIZE=640m
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-02
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/02
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_03]
FS_NAME=pushdata/03
FS_SIZE=640m
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-03
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/03
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_04]
FS_NAME=pushdata/04
FS_SIZE=640m
NFS_HOST=nas3
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-04
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/04
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_05]
FS_NAME=pushdata/05
FS_SIZE=640m
NFS_HOST=nas7
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-05
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/05
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_06]
FS_NAME=pushdata/06
FS_SIZE=640m
NFS_HOST=nas4
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-06
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/06
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_07]
FS_NAME=pushdata/07
FS_SIZE=640m
NFS_HOST=nas8
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-07
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/07
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_08]
FS_NAME=pushdata/08
FS_SIZE=640m
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-08
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/08
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_09]
FS_NAME=pushdata/09
FS_SIZE=640m
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-09
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/09
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_10]
FS_NAME=pushdata/10
FS_SIZE=640m
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-10
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/10
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_11]
FS_NAME=pushdata/11
FS_SIZE=640m
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-11
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/11
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_12]
FS_NAME=pushdata/12
FS_SIZE=640m
NFS_HOST=nas3
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-12
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/12
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_13]
FS_NAME=pushdata/13
FS_SIZE=640m
NFS_HOST=nas7
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-13
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/13
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_14]
FS_NAME=pushdata/14
FS_SIZE=640m
NFS_HOST=nas4
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-14
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/14
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_PUSHDATA_15]
FS_NAME=pushdata/15
FS_SIZE=640m
NFS_HOST=nas8
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-pushdata-15
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/pushData/15
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcdata
GROUP=dcdata

[Storage_NAS_REJECTED]
FS_NAME=rejected
FS_SIZE=2g
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-rejected
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/rejected
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_GLASSFISH]
FS_NAME=glassfish
FS_SIZE=10g
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-glassfish
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/glassfish
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_HOME]
FS_NAME=home
FS_SIZE=10g
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-home
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/home
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=create_users
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_LOG]
FS_NAME=log
FS_SIZE=30g
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-log
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/log
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=ALL
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_MEDIATION_SW]
FS_NAME=mediation_sw
FS_SIZE=4g
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-mediation_sw
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/mediation_sw
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_MEDIATION_INTER]
FS_NAME=mediation_inter
FS_SIZE=40g
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-mediation_inter
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/mediation_inter
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_NORTHBOUND]
FS_NAME=northbound
FS_SIZE=100g
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-northbound
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/northbound
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=create_directories
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_REFERENCE]
FS_NAME=reference
FS_SIZE=2g
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-reference
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/data/reference
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_ENIQ_platform
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_SENTINEL]
FS_NAME=sentinel
FS_SIZE=2g
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-sentinel
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/sentinel
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=relocate_sentinel
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_SNAPSHOT]
FS_NAME=snapshot
FS_SIZE=60g
NFS_HOST=nas5
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-snapshot
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/snapshot
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=ALL
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_SQL_ANYWHERE]
FS_NAME=sql_anywhere
FS_SIZE=2g
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-sql_anywhere
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/sql_anywhere
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_sybase_asa
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_SYBASE_IQ]
FS_NAME=sybase_iq
FS_SIZE=5g
NFS_HOST=nas2
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-sybase_iq
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/sybase_iq
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=install_sybaseiq
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_SW]
FS_NAME=sw
FS_SIZE=2g
NFS_HOST=nas6
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-sw
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/sw
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=create_directories
OWNER=dcuser
GROUP=dc5000

[Storage_NAS_UPGRADE]
FS_NAME=upgrade
FS_SIZE=3g
NFS_HOST=nas1
SHARE_PATH=/vx/<CHANGE><ENIQ_POOL_ID>-upgrade
MOUNT_PATH=<CHANGE><ENIQ_BASE_DIR>/upgrade
NFS_SHARE_OPTIONS="rw,no_root_squash"
SNAP_TYPE=optim
STAGE=ALL
OWNER=dcuser
GROUP=dc5000
