Storage hosts
================
Currently we have two storage servers, both of them have a CentOS 6.5
installation on them.

Disk configuration
------------------

The storage servers have a set of 6 disks in a RAID5


Storage replication
-------------------
For the storage replication we are using [DRBD][drbd_src], it was required to
install drbd84, and to do that on centos we had to use some special
repos as it's been discontinued on the official repos. Here are the
specific ones:

    [root@ovirt-storage01 ~]# cat /etc/yum.repos.d/hacluster.repo
    [haclustering]
    name=HA Clustering
    baseurl=http://download.opensuse.org/repositories/network:/ha-clustering:/Stable/CentOS_CentOS-6/
    enabled=1
    gpgcheck=0

You can check specifically the current status using the command:

    [root@ovirt-storage01 ~]# drbd-overview
    0:ovirt_storage/0  Connected Primary/Secondary UpToDate/UpToDate C r----- /srv/ovirt_storage ext4 11T 563G 9.7T 6% 

The DRBD cluster is started/stopped by the pacemaker cluster, so no
need to handle it, but sometimes when the cluster degenerates is
required to manually choose which node has to be master and start the
replication between the nodes. You can check the cdocumentation on how
to fix that type of issues [here][drbd_fix].


  [drbd_src]: http://www.drbd.org/users-guide/
  [drbd_fix]: http://www.drbd.org/users-guide/ch-troubleshooting.html

Clustering
----------
The clustering has been configured using crm and pacemaker. Here are a
few tips on managing it:

To enter the management shell you can just type:

    crm

From there you can see a list of available commands using _tab_
completion.

To see the current status of the cluster you can use:

    [root@ovirt-storage01 ~]# crm status
    Last updated: Sat Nov  8 03:59:18 2014
    Last change: Thu Jul 31 02:41:35 2014 via cibadmin on ovirt-storage01
    Stack: cman
    Current DC: ovirt-storage02 - partition with quorum
    Version: 1.1.10-14.el6_5.3-368c726
    2 Nodes configured
    7 Resources configured
    
    Online: [ ovirt-storage01 ovirt-storage02 ]
    
    Master/Slave Set: ms_drbd_ovirt_storage [p_drbd_ovirt_storage]
        Masters: [ ovirt-storage01 ]
        Slaves: [ ovirt-storage02 ]
    Resource Group: g_ovirt_storage
        p_fs_ovirt_storage	(ocf::heartbeat:Filesystem):	Started ovirt-storage01 
        p_ip_ovirt_storage	(ocf::heartbeat:IPaddr2):	Started ovirt-storage01 
        p_nfs_ovirt_storage	(lsb:nfs):	Started ovirt-storage01
    Clone Set: cl_exportfs_ovirt_storage [p_exportfs_ovirt_storage]
        Started: [ ovirt-storage01 ovirt-storage02 ]



### Showing/editing the config ###

To see and edit the configuration you have to enter the configuration
space from the crm shell, for future reference here's the output form
the current config:

    crm(live)# cd configure
    crm(lise)configure# show

    node ovirt-storage01
    node ovirt-storage02
    primitive p_drbd_ovirt_storage ocf:linbit:drbd \
        params drbd_resource=ovirt_storage \
        op monitor interval=15 role=Master \
        op monitor interval=30 role=Slave
    primitive p_exportfs_ovirt_storage exportfs \
        params fsid=0 directory="/srv/ovirt_storage" options="rw,mountpoint,no_root_squash" clientspec="66.187.230.0/255.255.255.192" \
        op monitor interval=30s \
        meta target-role=Started
    primitive p_fs_ovirt_storage Filesystem \
        params device="/dev/drbd0" directory="/srv/ovirt_storage" fstype=ext4 \
        op monitor interval=10s \
        meta target-role=Started
    primitive p_ip_ovirt_storage IPaddr2 \
        params ip=66.187.230.61 cidr_netmask=26 \
        op monitor interval=30s \
        meta target-role=Started
    primitive p_nfs_ovirt_storage lsb:nfs \
        op monitor interval=30s \
        meta target-role=Started
    group g_ovirt_storage p_fs_ovirt_storage p_ip_ovirt_storage \
        meta target-role=Started
    ms ms_drbd_ovirt_storage p_drbd_ovirt_storage \
        meta master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true target-role=Started
    clone cl_exportfs_ovirt_storage p_exportfs_ovirt_storage
    location cli-prefer-ms_drbd_ovirt_storage ms_drbd_ovirt_storage role=Started inf: ovirt-storage01
    colocation c_all_on_drbd inf: g_ovirt_storage ms_drbd_ovirt_storage:Master
    colocation c_nfs_on_drbd inf: p_nfs_ovirt_storage ms_drbd_ovirt_storage:Master
    colocation c_nfs_on_exportfs inf: g_ovirt_storage cl_exportfs_ovirt_storage
    order o_drbd_first inf: ms_drbd_ovirt_storage:promote g_ovirt_storage:start
    order o_exportfs_before_nfs inf: cl_exportfs_ovirt_storage g_ovirt_storage:start
    property cib-bootstrap-options: \
        dc-version=1.1.10-14.el6_5.3-368c726 \
        cluster-infrastructure=cman \
        expected-quorum-votes=2 \
        stonith-enabled=false \
        no-quorum-policy=ignore \
        last-lrm-refresh=1404978312


### NetworkConfiguration ###

The network is configured to use bonding on all interfaces using
802.3ad bonding protocol (requires special configuration on the
swithes).

Here's the current configuration files:

    [root@ovirt-storage01 ~]# cat /etc/modprobe.d/bonding.conf
    alias bond0 bonding
    ##mode=4 - 802.3ad   mode=6 - alb
    options bond0 mode=4 miimon=100 lacp_rate=1

    [root@ovirt-storage01 ~]# cat /etc/sysconfig/network-scripts/ifcfg-em1
    DEVICE="em1"
    BOOTPROTO=none
    HWADDR="F8:BC:12:3B:22:40"
    NM_CONTROLLED="no"
    ONBOOT="yes"
    TYPE="Ethernet"
    UUID="c0407968-795b-4fdb-9a43-3c70e4803c09"
    SLAVE=yes
    MASTER=bond0
    USERCTL=no

    [root@ovirt-storage01 ~]# cat /etc/sysconfig/network-scripts/ifcfg-bond0
    DEVICE=bond0
    IPADDR=66.187.230.1
    NETWORK=66.187.230.0
    NETMASK=255.255.255.192
    BROADCAST=66.187.230.63
    GATEWAY=66.187.230.62
    USERCTL=no
    BOOTPROTO=none
    ONBOOT=yes

Troubleshooting
---------------

Under certain conditions, the cluster can misbehave and cause shared resources
to become unavailable. Here are some troubleshooting steps to find out the reason
and bring services back up.

### DRBD ###

To check DRBD status, check contents of /proc/drbd to confirm what each of the
nodes reports about sync status

    # cat /proc/drbd
    version: 8.4.4 (api:1/proto:86-101)
    GIT-hash: 599f286440bd633d15d5ff985204aff4bccffadd build by phil@Build64R6, 2013-10-14 15:33:06
     0: cs:WFConnection ro:Primary/Unknown ds:UpToDate/DUnknown C r-----
        ns:0 nr:0 dw:915552296 dr:1377392270 al:23251148 bm:0 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:1271108708

In this example, one of the nodes is down and the other is considered Primary
as seen in values of cs: ro: and ds: parameters.
If both nodes see each other as "Unknown" this may indicate a split brain
with loss of connectivity. In such an event the safest way is to shut down
one of the nodes and restart the cluster on the remaining one.

### Clustering ###

The clustering service is used to ensure resources are only present on a single node.
It manages the following resources:
* DRBD replication - must always work on both nodes
* floating IP - must only be present on a single node in the cluster
* mount of the replicated volume - must be present only on the node with the replicated IP
* NFS export of the replicated volume - must only be present on the node with the mount

If either of these services fails, ones that depend on it will stop working as well.
In case of a busy FS, for example, the cluster manager may fail to unmount and
the services will not be able to migrate to the other node.

To see cluster status use the "crm" tool:

    # crm status
    Last updated: Thu Jul 20 04:04:04 2017
    Last change: Thu Jun 29 00:04:04 2017 via cibadmin on ovirt-storage02
    Stack: cman
    Current DC: ovirt-storage01 - partition WITHOUT quorum
    Version: 1.1.10-14.el6_5.3-368c726
    2 Nodes configured
    7 Resources configured


    Online: [ ovirt-storage01 ]
    OFFLINE: [ ovirt-storage02 ]

     Master/Slave Set: ms_drbd_ovirt_storage [p_drbd_ovirt_storage]
         Masters: [ ovirt-storage01 ]
         Stopped: [ ovirt-storage02 ]
     Resource Group: g_ovirt_storage
         p_fs_ovirt_storage (ocf::heartbeat:Filesystem):    Started ovirt-storage01
         p_ip_ovirt_storage (ocf::heartbeat:IPaddr2):       Started ovirt-storage01
     p_nfs_ovirt_storage    (lsb:nfs):      Started ovirt-storage01
     Clone Set: cl_exportfs_ovirt_storage [p_exportfs_ovirt_storage]
         Started: [ ovirt-storage01 ]
         Stopped: [ ovirt-storage02 ]

    Failed actions:
        p_exportfs_ovirt_storage_monitor_30000 on ovirt-storage01 'not running' (7): call=35, status=complete, last-rc-change='Thu Jan 05 05:05:05 2017', queued=0ms, exec=0ms

In this example, one of the nodes is listed as OFFLINE.
All services will attempt to start on the remaining node.
If both nodes are listed as Online, yet resources are not started
it may mean that the node they were last running on has issues.
Check individual services on both nodes to see if there is a resource that can't be released:

    cat /proc/drbd
    cat /proc/mounts
    cat /proc/fs/nfsd/exports
    ip addr show bond0

A healthy node should have all four resources present: drbd0 active and mounted,
secondary IP present on the interface and the mount exported via NFS.
If some/all of the services are missing or spread between nodes,
check /var/log/messages for possible hardware issues and try to restart the cluster:

1) on a node where a resource seems locked - stop pacemaker

    /etc/init.d/pacemaker stop

2) check the other node's cluster status using "crm"

    crm status

3) if the node is reported as down in "crm" output - re-run resource checks
   shown above to ensure resources were released, then start pacemaker

    /etc/init.d/pacemaker start

If this does not bring resources back up or some of these actions freezes
it's safest to stop both nodes and then just start one of them
to make the cluster re-initialize by clearing the locks.
