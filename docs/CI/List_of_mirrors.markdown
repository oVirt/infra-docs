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
centos-base-el7             | CentOS 7 'base' repo
centos-updates-el7          | CentOS 7 'updates' repo
centos-extras-el7           | CentOS 7 'extras' repo
epel-el7                    | EPEL for EL7
glusterfs-3.12-el7          | CentOS storage SIG GlusterFS 3.12 repo for EL7
glusterfs-5-el7             | CentOS storage SIG GlusterFS 5 repo for EL7
glusterfs-6-el7             | CentOS storage SIG GlusterFS 6 repo for EL7
centos-ovirt-common-el7     | CentOS virt SIG common repo for EL7
centos-ovirt-4.2-el7        | CentOS virt SIG oVirt 4.2 repo for EL7
centos-kvm-common-el7       | CentOS virt SIG KVM repo for EL7
centos-qemu-ev-testing-el7  | CentOS virt SIG EV repo for EL7 (pre-release)
centos-qemu-ev-release-el7  | CentOS virt SIG Enterprise Virtualization repo for EL7
centos-opstools-testing-el7 | CentOS OPS tools SIG repo (pre-release)
centos-opstools-release-el7 | CentOS OPS tools SIG repo
fedora-base-fc28            | Fedora 28 'base' repo
fedora-updates-fc28         | Fedora 28 'updates' repo
fedora-base-fc29            | Fedora 29 'base' repo
fedora-updates-fc29         | Fedora 29 'updates' repo
fedora-base-fc30            | Fedora 30 'base' repo
fedora-updates-fc30         | Fedora 30 'updates' repo

[1]: Transactional_mirrors.markdown
[2]: Build_and_test_standards.markdown
[3]: http://jenkins.ovirt.org/search/?q=system-sync_mirrors
