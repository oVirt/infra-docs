The CI transactional mirrors
============================

The CI transactional mirrors were created to protect CI jobs from failures that
have to do with external package repositories.

There are 3 types of failures that can be caused by using external package
repositories in CI:

1. Failures due to connectivity and communication issues with the external
   repository
2. Failures due to the external repository being updated while the CI job is
   still running
3. Failures due to packages in the external repository being incompatible with
   the code being tested in CI

The transactional mirrors were designed to prevent failures of types 1 and 2 and
also provide means to mitigate failures of type 3.

To prevent failures of type 1 it may be enough to have a local mirror of remote
package repositories or even just a caching proxy server.

To prevent failures of type 2, the mirror needs to be transactional which means
it needs to provide a mechanism by which a job can have a fixed-state view of the
mirror that shows how it looked in a certain point in time (Typically when the
CI job started) while the mirror itself can continue to be updated.

That mechanism is achieved in the CI mirrors via the use of snapshots. When a
mirror is updated, a snapshot of the updated state is created. From that point
on, the snapshot is guaranteed to never be changed. When a job starts, it checks
which are the latests snapshots of the repositories it needs to use, and sets
things up so that the snapshots are used instead of the external repositories.
This process is called "the mirror injection process".

The mirror injection process
----------------------------
The mirror injection process is the process by which the external package
repository URLs a job is made to use are replaced dynamically by the CI system
to poing to the CI mirror snapshots instead.

The mirror injection itself is done by the ["`mirror_client.py`" script][1].

To know which mirror snapshot URLs to inject to which repos, the repos are
identified by their 'repo id', which is the identifier placed in square brackets
in the `yum` configuration files. For example, for the following configuration:

    [centos-base-el7]
    name=CentOS-7 - Base
    baseurl=http://mirror.centos.org/centos/7/os/x86_64/
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

The 'repo id' would be `centos-base-el7`. Given that we have a mirror that is
called "centos-base-el7" (That mirrors the CentOS 7 base repository, as
expected), and that its latest snapshot was created at Dec 13th, 2016, when the
mirror injection process runs and finds the above configuration, it will replace
the repo URL, The resulting configuration would be:

    [centos-base-el7]
    name = CentOS-7 - Base
    baseurl = http://mirrors.phx.ovirt.org/repos/yum/centos-base-el7/2016-12-13-13-30
    gpgcheck = 1
    gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
    proxy = _none_

Note that the mirror injection process also puts settings in place to ensure the
mirrors are accessed directly and not via the [proxy server][2].

When the injection process comes across a 'repo id' for which no mirror exists,
it leaves the configuration for it in place as-is. This means that repo ids need
to be properly specified for the mirrors to be in use.

[1]: https://gerrit.ovirt.org/gitweb?p=jenkins.git;a=blob;f=scripts/mirror_client.py
[2]: Proxy.markdown

Using mirrors for standard-CI jobs
----------------------------------
The CI mirrors were designed to be used primarily by "[Standard-CI][3]" jobs.

Standard CI jobs gain access to repositories in two ways. Some repositories are
pre-configured in the environment by default. Such repositories include the OS
"base" and "updates" repos and some commonly used repos such as "EPEL". For
other repositories, projects can specify "`*.repos`" files in their
"`automation`" directories.

For pre-configured repositories, mirror injection happens automatically.

For repositories defines in "`*.repos`" files, one needs to carefully specify
repo ids for then so that they will be recognised by the mirror injection
process. To do that, one need to prepend the repo id followed by a comma to the
repo url in the "`*.repos`" file. For example, here is how to include the
GlusterFS CentOS SIG repo:

    glusterfs-3.8-el7,http://mirror.centos.org/centos/7/storage/x86_64/gluster-3.8

To get a list of possible repo ids to use, please see the [List of CI
mirrors][4].

[3]: Build_and_test_standards.markdown
[4]: List_of_mirrors.markdown

The mirror sync process
-----------------------
The CI mirrors are synchronised with their equivalent upstream repositories
every 8 hours.

Each mirror has its own set of synchronization jobs, one per supported
architecture (Currently only x86_64 mirrors are supported), that is called
something like:

    system-sync_mirrors-[mirror-name-here]-[arch]

All the synchronization jobs run directly on the "`mirrors.phx.ovirt.org`"
server. The core job functionality is implemented by the ["`mirror_mgr.sh`"
script][5].

Each mirror has a "base" directory that is synchronised with the upstream
repository by using the "`reposync`" tool. If the synchronization job detects
that changes were synchronized from the upstream, it create a snapshot
directory, named after the time in which is was created, that contains a copy of
the "`yum`" metadata in the "base" directory. This way, when the "base"
directory changes, the snapshot keeps pointing to the older package versions.

Each mirror has a "`latest.txt`" file that contains the name of the latest
snapshot. It is updated when a new snapshot is created. This makes it easy to
tell which snapshot is the latest with a tool like "`curl`".

If the mirror was updated, the synchronization job triggers another job that is
called "`system-mk_mirrors_index`". This jobs also runs the ["`mirror_mgr.sh`"
script][5] but with different parameters. This job scans all the mirrors, and
build a mapping data structure mapping the name of each mirror to the URL of its
latest mirror. This data is then saved in the  JSON, YAML and Python structure
source data formats in the "`all_latest.json`", "`all_latest.yaml`" and
"`all_latest.py`" files respectively.

The "all_latest" files make it possible to obtain all the information the mirror
injection process needs with a single HTTP request to the mirrors server.

[5]: https://gerrit.ovirt.org/gitweb?p=jenkins.git;a=blob;f=scripts/mirror_mgr.sh
