Storage hosts
================

Hardware
--------

There are two storage server in the PHX lab:

| hostname                            | primary IP    |
| ----------------------------------- | ------------- |
| ovirt-storage01.infra-phx.ovirt.org | 172.19.11.201 |
| ovirt-storage02.infra-phx.ovirt.org | 172.19.11.202 |

They are Dell R720 2U machines with 16 900GB disks on each
grouped into several RAID arrays as follows:

| Physical size | RAID   | Logical size | name    | use                 |
| ------------- | ------ | ------------ | ------- | ------------------- |
| 2x900G        | RAID1  | 0.9T         | centos  | OS plus NFS shares  |
| 4x900G        | RAID10 | 1.8T         | jenkins | Jenkins             |
| 6x900G        | RAID50 | 3.6T         | prod-1  | prod systems tier 1 |
| 4x900G        | RAID5  | 2.7T         | prod-2  | prod systems tier 2 |

Both systems have CentOS 7 installed and expose storage via iSCSI and NFS.

Network setup
-------------

Each system has 4 Gigabit NICs bonded for increased reliability and performance.
On top of that, several [VLANs](Networking.markdown) are configured to serve different consumers.

| host             | VLAN911 IP    | VLAN913 IP    | VLAN91 IP     |
| ---------------- | ------------- | ------------- | ------------- |
| ovirt-storage01  | 172.19.11.201 | 172.19.10.201 | 66.187.230.1  |
| ovirt-storage02  | 172.19.11.202 | 172.19.10.202 | 66.187.230.2  |
| ovirt-storage02* | -             | -             | 66.187.230.61 |

Infra VLAN 911 is the native one available directly on the bond.
It has the IP configured statically and used as the default route.

Sample configuration:

Bond member:

    $ cat /etc/sysconfig/network-scripts/ifcfg-eno1
    NAME="eno1"
    DEVICE="eno1"
    ONBOOT=yes
    BOOTPROTO=none
    TYPE=Ethernet
    MASTER=bond0
    SLAVE=yes

Bond master (primary IP from Infra VLAN)

    $ cat /etc/sysconfig/network-scripts/ifcfg-bond0
    DEVICE=bond0
    NAME=bond0
    TYPE=Bond
    BONDING_MASTER=yes
    ONBOOT=yes
    BOOTPROTO=none
    IPADDR=172.19.11.201
    NETMASK=255.255.255.0
    GATEWAY=172.19.11.254
    BONDING_OPTS="mode=4 miimon=100 lacp_rate=1"
    ZONE=public

This network is only used for maintenance tasks and has Internet access.
Other VLANs are used to expose iSCSI and NFS directly to connected systems.

The dedicated Storage VLAN is configured statically and is used for iSCSI.
To access the targets, hypervisors also need to have VLAN913 configured.

Sample configuration:

    $ cat /etc/sysconfig/network-scripts/ifcfg-bond0.913
    DEVICE=bond0.913
    NAME=bond0.913
    VLAN=yes
    ONBOOT=yes
    BOOTPROTO=none
    ZONE=internal
    TYPE=Vlan
    PHYSDEV=bond0
    VLAN_ID=913
    REORDER_HDR=yes
    GVRP=no
    MVRP=no
    IPADDR=172.19.10.201
    PREFIX=24
    DEFROUTE=yes
    IPV4_FAILURE_FATAL=no
    IPV6INIT=no

The DMZ VLAN is enabled for historical reasons used to serve the Hosted Engine
NFS storage domain to the oVirt instance which was deployed in this VLAN.

Sample configuration:

    $ cat /etc/sysconfig/network-scripts/ifcfg-bond0.91
    DEVICE=bond0.91
    NAME=bond0.91
    VLAN=yes
    ONBOOT=yes
    BOOTPROTO=none
    ZONE=public
    TYPE=Vlan
    PHYSDEV=bond0
    VLAN_ID=91
    REORDER_HDR=yes
    GVRP=no
    MVRP=no
    IPADDR=66.187.230.1
    PREFIX=25
    IPV4_FAILURE_FATAL=no
    IPV6INIT=no
    PEERDNS=no

Note that ovirt-srv02 also has a secondary IP assigned in this VLAN that was
used by the old clustering setup. This is done the following way:

    $ cat /etc/sysconfig/network-scripts/ifcfg-bond0.91:61
    DEVICE=bond0.91:61
    NAME=bond0.91:61
    ISALIAS=yes
    ONBOOT=yes
    BOOTPROTO=none
    ZONE=public
    IPADDR=66.187.230.61
    PREFIX=25
    IPV4_FAILURE_FATAL=no
    IPV6INIT=no
    PEERDNS=no

LVM configuration
-----------------

Each of the RAID volumes is a Physical Volume in its own Volume Group:

    # vgs
    VG    #PV #LV #SN Attr   VSize   VFree
    tier0   1   1   0 wz--n-   1.82t      0
    tier1   1   1   0 wz--n-   3.64t      0
    tier2   1   1   0 wz--n-   2.73t      0
    tier3   1   9   0 wz--n- 801.40g 369.40g

Most Volume Groups have just one Logical Volume defined that is then
directly exposed via iSCSI. For NFS smaller volumes are created as needed
on the VG that also has the root filesystem.

iSCSI configuration
-------------------

iSCSI is configured using targetcli and looks the following way:

    # targetcli
    /> ls
    o- / ............................................................................................. [...]
      o- backstores .................................................................................. [...]
      | o- block ...................................................................... [Storage Objects: 3]
      | | o- data ................................... [/dev/mapper/tier1-data (3.6TiB) write-thru activated]
      | | | o- alua ....................................................................... [ALUA Groups: 1]
      | | |   o- default_tg_pt_gp ........................................... [ALUA state: Active/optimized]
      | | o- data2 ................................. [/dev/mapper/tier2-data2 (2.7TiB) write-thru activated]
      | | | o- alua ....................................................................... [ALUA Groups: 1]
      | | |   o- default_tg_pt_gp ........................................... [ALUA state: Active/optimized]
      | | o- jenkins ............................. [/dev/mapper/tier0-jenkins (1.8TiB) write-thru activated]
      | |   o- alua ....................................................................... [ALUA Groups: 1]
      | |     o- default_tg_pt_gp ........................................... [ALUA state: Active/optimized]
      | o- fileio ..................................................................... [Storage Objects: 0]
      | o- pscsi ...................................................................... [Storage Objects: 0]
      | o- ramdisk .................................................................... [Storage Objects: 0]
      o- iscsi ................................................................................ [Targets: 1]
      | o- iqn.2018-08.org.ovirt:storage01 ....................................................... [TPGs: 1]
      |   o- tpg1 ...................................................................... [gen-acls, no-auth]
      |     o- acls .............................................................................. [ACLs: 0]
      |     o- luns .............................................................................. [LUNs: 3]
      |     | o- lun0 ....................... [block/jenkins (/dev/mapper/tier0-jenkins) (default_tg_pt_gp)]
      |     | o- lun1 ............................. [block/data (/dev/mapper/tier1-data) (default_tg_pt_gp)]
      |     | o- lun2 ........................... [block/data2 (/dev/mapper/tier2-data2) (default_tg_pt_gp)]
      |     o- portals ........................................................................ [Portals: 1]
      |       o- 172.19.10.201:3260 ................................................................... [OK]
      o- loopback ............................................................................. [Targets: 0]
    />

There is one target with one TPG and several LUNs mapped to LVM volumes.
Authentication is disabled and the portal only listens to the VLAN913 IP.

To add LUNs it's enough to define a backstore and assign in to a LUN.

NFS configuration
-----------------

NFS is used by the oVirt Hosted Engine and other users such as OpenShift.
Classic NFS configuration is in place, defined in /etc/exports.

To enable a new export - define it in the config, then reload the daemon:

    # exportfs -ra

Firewall configuration
----------------------

Firewalld is used to configure access to various services.
Currently, interfaces are placed into two zones:

| firewalld zones | interfaces        | services        |
| --------------- | ----------------- | --------------- |
| internal        | VLAN913 (storage) | SSH, iSCSI, NFS |
| public          | everything else   | SSH, NFS        |

To add a service - please ensure it is reachable from the desired zone.
If not - add it using firewall-cmd. Example adding NFS to the public zone:

    # firewall-cmd --permanent --zone=public --add-service=mountd
    # firewall-cmd --permanent --zone=public --add-service=rpcbind
    # firewall-cmd --permanent --zone=public --add-service=rpc-bind
    # firewall-cmd --daemon-reload
