s390x (Mainframe) slave VM
==========================

The oVirt project had been allowed to use an s390x (mainframe) VM for the
purpose of creating s390x builds of some of the oVirt packages.

This VM is shared buy the oVirt project as well as other projects such as 'qemu'
and 'libvirt'.

The contact for person for handling issues that have to do with the s390x VM
is Dan Horak (dhorak@redhat.com).

The VM is attached as a slave to both the production Jenkins instance as well as
the staging instance. The instances use the 'ovirt' and 'ovirt-staging' user
accounts respectively. Those accounts are accessible over SSH via the same keys
used by the respective Jenkins server to access other slaves.

Note that our user accounts on the s390x VM do not have any sudo permissions,
nor are all packages that we typically install available there, so some STDCI
features, such as Docker support, may not be usable.
