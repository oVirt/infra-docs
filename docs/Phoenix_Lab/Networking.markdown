Networking
==========

The Phoenix lab has several networks used for various purposes.

| Name    | Subnet          | DNS suffix            | Description |
| ------- | --------------- | --------------------- | ----------- |
| DMZ     | 66.187.230.0/25 | phx.ovirt.org         | Internet-facing, used for external services |
| storage | 172.19.10.0/24  | -                     | storage network, isolated (no access to Internet or other nets) |
| infra   | 172.19.11.0     | infra-phx.ovirt.org   | hypervisors are located in this subnet |
| workers | 172.19.12.0/22  | workers-phx.ovirt.org | Jenkins slaves reside in this subnet |

Only the DMZ subnet is reachable from the Internet.
Systems from other subnets are behind NAT served by a dedicated gateway VM, gw01.phx.ovirt.org
which also provides DHCP, DNS and OpenVPN services for these subnets. DHCP and DNS for the DMZ
is provided by foreman.phx.ovirt.org. To connect to systems in internal networks, use any system
from the DMZ network as a jump host or set up OpenVPN.

Note: DNS for the upper level ovirt.org zone is managed by Red Hat IT. To apply changes to it
an internal support ticket mut be opened by a Red Hat employee.