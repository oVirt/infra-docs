Community Cage
==============

A few VMs are hosted by OSAS in the Community Cage under the [OSCI][1]
umbrella.

[1]: https://www.osci.io/

Deployment
----------

These hosts are deployed using Ansible and the rules are public in the [Gerrit
repository][2]. You also need the Ansible Vault passphrase, which can be found
in the infra team encrypted file.

[2]: https://gerrit.ovirt.org/#/admin/projects/infra-ansible

Accessing Hosts
---------------

All machines are accessible using the root account directly. The list of admin
SSH keys allowed to log in is also managed via Ansible.

Machines in the `OSAS-Public` VLAN can be accessed directly, whereas those in
the `OSAS-Internal` VLAN require to use a jump host. Ansible is already
configured to use it, but if you need direct SSH access just add the following
option to your ssh call: `-o ProxyJump=tenant@soeru.osci.io`.

