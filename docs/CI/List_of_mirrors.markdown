List of CI mirrors
==================
Following is a list of all [transactional mirrors][1] that are currnetly available
for use by [Standard-CI][2] jobs running in the oVirt CI system.

This list has last been updated in Feb 28th, 2017. The oVirt Infra team tries to
keep this list up to date. When in doubt, the authoritative source of
information about the CI mirrors is the [list of mirror synchronization jobs in
Jenkins][3].

At this time, all mirrors contain only x86_64 packages.

Mirror 'repo id'            | What it mirrors
--------------------------- | ---------------------------------------------
centos-base-el6             | CentOS 6 'base' repo
centos-updates-el6          | CentOS 6 'updates' repo
epel-el6                    | EPEL for el6
centos-base-el7             | CentOS 7 'base' repo
centos-updates-el7          | CentOS 7 'updates' repo
centos-extras-el7           | CentOS 7 'extras' repo
epel-el7                    | EPEL for EL7
glusterfs-3.7-el7           | CentOS storage SIG GlusterFS 3.7 repo for EL7
glusterfs-3.8-el7           | CentOS storage SIG GlusterFS 3.8 repo for EL7
glusterfs-3.10-el7          | CentOS storage SIG GlusterFS 3.10 repo for EL7
glusterfs-3.12-el7          | CentOS storage SIG GlusterFS 3.12 repo for EL7
centos-ovirt-common-el7     | CentOS virt SIG common repo for EL7
centos-ovirt-4.0-el7        | CentOS virt SIG oVirt 4.0 repo for EL7
centos-ovirt-4.2-el7        | CentOS virt SIG oVirt 4.2 repo for EL7
centos-kvm-common-el7       | CentOS virt SIG KVM repo for EL7
centos-qemu-ev-release-el7  | CentOS virt SIG Enterprise Virtualization repo for EL7
centos-opstools-testing-el7 | CentOS OPS tools SIG repo (pre-release)
fedora-base-fc24            | Fedora 24 'base' repo
fedora-updates-fc24         | Fedora 24 'updates' repo
fedora-base-fc25            | Fedora 25 'base' repo
fedora-updates-fc25         | Fedora 25 'updates' repo
fedora-base-fc26            | Fedora 26 'base' repo
fedora-updates-fc26         | Fedora 26 'updates' repo
fedora-base-fc27            | Fedora 27 'base' repo
fedora-base-fcraw           | Fedora Rawhide 'base' repo

[1]: Transactional_mirrors.markdown
[2]: Build_and_test_standards.markdown
[3]: http://jenkins.ovirt.org/search/?q=system-sync_mirrors
