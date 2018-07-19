oVirt Hosts
===========

All oVirt hosts in PHX have CentOS 7 installed with a hardware
RAID5 setup and bonding on all interfaces.

Hosts are split across datacenters. There is one that hosts the [hosted engine]
and production VMs while others host CI workloads.

  [hosted engine]: /Hosted_Engine_Howto


PHX oVirt datacenter organization
---------------------------------

There are several datacenters defined: Production for critical VMs
that uses shared storage and local datacenters to host CI workloads.

The Production datacenter consists of three hosts which are located
in the DMZ VLAN and have static IPs defined:

| Host        | IP           |
| ----------- | ------------ |
| ovirt-srv01 | 66.187.230.3 |
| ovirt-srv02 | 66.187.230.4 |
| ovirt-srv03 | 66.187.230.5 |

These hosts are connected to the [Storage array](Storage_Hosts)

Other datacenters are of the Local Storage type so there is
one host per datacenter. These reside in the infra VLAN with
IPs also assigned statically according to the hostname:

| Host        | IP           |
| ----------- | ------------ |
| ovirt-srv09 | 172.19.11.9  |
| ovirt-srv10 | 172.19.11.10 |
| ovirt-srv11 | 172.19.11.11 |
| ovirt-srv12 | 172.19.11.12 |
| ovirt-srv13 | 172.19.11.13 |
| ovirt-srv14 | 172.19.11.14 |

There is also two POWER8 hosts in use by oVirt hosting ppc64le VMs:

| Host        | FQDN                      |
| ----------- | ------------------------- |
| ovirt-srv15 | ovirt-srv15.phx.ovirt.org |
| ovirt-srv16 | ovirt-srv16.phx.ovirt.org |

See the [network layout](Networking) for more details about PHX VLANs.


### Production VMs ###
VMs in this datacenter can be installed through Foreman or using
templates imported from Glance.

Some of the vms that are located in the Production datacenter:

* foreman: Foreman master
* foreman-phx: Foreman proxy serving the phoenix network, includes
  DHCP, TFTP and DNS services. Also serves (or will) as DNS for the
  network.
* HostedEngine: VM with the hosted engine, is not actually managed by
  itself but by the hosted engine services.
* resources02-phx-ovirt-org: Frontend to serve repositories in
  resources.ovirt.org. It's connected to a special shared disk where
  the repos are stored, so it's easy to plug-unplug it from the vm if
  need upgrading or anything.
* proxy-phx-ovirt-org: This will be the local network squid proxy
  used to conserve traffic and increase speed when building with mock.
* gw02.phx.ovirt.org: PHX gateway for routing internal VLANs


### Jenkins VMs ###
The jenkins local DCs have all the slaves and templates used to build
them. The amount and oses/distros varies often but the organization
should be quite stable.

The slaves are named following the pattern:

    vm${NUMBER}

The number is used only to distinguish between the vms from one another
so it's only requirement is to be unique.

Currently the number ranges are used as follows:

| first VM | last VM | distro |
| -------- | ------- | ------ |
| vm0001   | vm0049  | el7    |
| vm0050   | vm0063  | fedora |
| vm0064   | vm0099  | el7    |
| vm0100   | vm0199  | fedora |
| vm0200   | vm0299  | el7    |

These are located in the workers VLAN and have IPs assigned via DHCP
based on the MAC address used during VM creation. Some examples:

| VM     | MAC               | IP            |
| ------ | ----------------- | ------------- |
| vm0001 | 00:16:3e:11:00:01 | 172.19.12.1   |
| vm0100 | 00:16:3e:11:01:00 | 172.19.12.100 |
| vm0222 | 00:16:3e:11:02:22 | 172.19.12.222 |
| vm1001 | 00:16:3e:11:10:01 | 172.19.15.233 |

The workers VLAN has a /22 subnet assigned so it can contain up to 1024 hosts.
IPs in this subnet are internal and are not reachable from the outside.

The templates are named the same way the slaves are, but instead of
using the `vm${NUMBER}` suffix you only have two suffixes, `-base` and
`-worker`. The `-base` template (sometimes you'll see also a vm
with that name, used to update the template) is a template you can use
to build any server, it has only the base foreman hostgroup
applied. The `-worker` template has the cloud-init config defined to
install software to act as a Jenkins slave.

Also keep in mind that puppet may be run again by the foreman
finisher script when creating a new machine to make sure to apply the
latest puppet manifests and configurations.


Network configuration
---------------------

All interfaces are bonded and the first one has PXE enabled.
If a rebuild is needed, use the first interface and then bond
using this "custom" bondiing mode in the oVirt Admin Interface.

    "mode=4 miimon=100 lacp_rate=1"

This will ensure the keepalive rate matches that on the switch.


Hosted engine management
------------------------

The three first hosts (when writing this), `ovirt-srv01`,
`ovirt-srv02` and `ovirt-srv03` are the ones that manage the hosted
engine vm. That hosted engine is not handled by itself but by a couple
of services and scripts installed bu the hosted-engine rpms.

To check the current status of the hosted engine cluster, you can run
from any of those hosts:


    [root@ovirt-srv01 ~]# hosted-engine --vm-status
    
    
    --== Host 1 status ==--
    
    Status up-to-date                  : True
    Hostname                           : 66.187.230.3
    Host ID                            : 1
    Engine status                      : {"health": "good", "vm": "up", "detail": "up"}
    Score                              : 2400
    Local maintenance                  : False
    Host timestamp                     : 1415642612
    Extra metadata (valid at timestamp):
        metadata_parse_version=1
        metadata_feature_version=1
        timestamp=1415642612 (Mon Nov 10 11:03:32 2014)
        host-id=1
        score=2400
        maintenance=False
        state=EngineUp
    
    
    --== Host 2 status ==--
    
    Status up-to-date                  : True
    Hostname                           : 66.187.230.4
    Host ID                            : 2
    Engine status                      : {"reason": "vm not running on this host", "health": "bad", "vm": "down", "detail": "unknown"}
    Score                              : 2400
    Local maintenance                  : False
    Host timestamp                     : 1415642616
    Extra metadata (valid at timestamp):
        metadata_parse_version=1
        metadata_feature_version=1
        timestamp=1415642616 (Mon Nov 10 11:03:36 2014)
        host-id=2
        score=2400
        maintenance=False
        state=EngineDown
    
    
    --== Host 3 status ==--
    
    Status up-to-date                  : True
    Hostname                           : ovirt-srv03.ovirt.org
    Host ID                            : 3
    Engine status                      : {"reason": "vm not running on this host", "health": "bad", "vm": "down", "detail": "unknown"}
    Score                              : 2400
    Local maintenance                  : False
    Host timestamp                     : 1415642615
    Extra metadata (valid at timestamp):
        metadata_parse_version=1
        metadata_feature_version=1
        timestamp=1415642615 (Mon Nov 10 11:03:35 2014)
        host-id=3
        score=2400
        maintenance=False
        state=EngineDown


You can see that the engine is running only on one of the hosts. You
can set one host into maintenance mode executing:


    [root@ovirt-srv01 ~]# hosted-engine --set-maintenance=local

From the selected host. You can also handle the vm engine with
hoset-endine command (**don't do it through the engine ui**).


Tips and Tricks
---------------------------------

### Strange routing/network issues ###
For example, once saw that ping was unable to resolve any names, while
dig/nslookup worked perfectly, that was caused by having wrong custom routing
rules in a routing table aside from the main one, to see all the routing rules
you can type:

```
ip route show table all
```

Those were defined in the /etc/network-scripts/rules-ovirtmgmt file.


### VDSM did not create the ovirtmgmt libvirt network ###
In one of the hosts, after messing the network, vdsm did not automatically
create the ovirtmgmt network in the libvirt setting, you can create it manually
by:

```
$ echo <<EOC > ovirtmgmt_net.xml
<network>
  <name>vdsm-ovirtmgmt</name>
  <forward mode='bridge'/>
  <bridge name='ovirtmgmt'/>
</network>
$ virsh -c qemu:///system
user: vdsm@ovirt
pass: shibboleth
(virsh)$ net-create ovirtmgmt_net.xml
# this creates the network in non-persistent mode, to force persistent we can 
# just edit it and add a newline at the end
(virsh)$ net-edit ovirtmgmt
(virsh)$ net-autostart ovirtmgmt
```
