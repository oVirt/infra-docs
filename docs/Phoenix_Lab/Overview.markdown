Overview
==============

The Poenix Lab infrastructure is composed by (as of today) 10 nodes
separated in two roles. The [storage servers] \(2 hosts) and the
 [oVirt host] servers (8 hosts).

  [storage servers]: /infra/Phoenix_Lab_Storage_Hosts
  [oVirt host]: /infra/Phoenix_Lab_oVirt_Hosts

The access to the servers is restricted to the foreman and jenkins
hosts. So you need to access them first and tunnel through to be able
to access any of the machines.

When connecting to the VMs through spice you'll need some special
setup so your connections are tunneled trough ssh, the details are
[here][ssh_spice_tunnel]

  [ssh_spice_tunnel]: /Infra/Phoenix_Lab_Ssh_Spice_Tunnel
