Overview
========

The Phoenix Lab infrastructure is composed of 28 physical servers
that are split into three groups:

* [Storage hosts](Storage_Hosts.markdown) (2 servers)
* [oVirt hosts](oVirt_Hosts.markdown) (11 servers)
* Lago hosts (15 servers)

Most of the production workloads for the project are running on this infra,
primarily as VMs inside oVirt.

All servers have CentOS 7 installed on them and are managed by Foreman.
Even though the lab has [public IP ranges](Networking.markdown) to provide
services, outside SSH access is restricted.
To perform management tasks please obtain OpenVPN(OpenVPN.markdown) access.
