Build and Test standards
========================

The oVirt project defined a set of standards that allow a source project to
specify how it should be built, tested and released in a generic manner that is
independent from the programming languages and tools that we used to develop the
source project.

These standards are used to create generic build and test tools such as
`mock_runner` that can work in a consistent manner for any oVirt project.

The oVirt CI system uses these standards in order to run build, test and release
processes for projects in an automated manner. This is why these standards are
also known as "Standard-CI" or "STDCI".

The automation directory
------------------------

The basis of the build and tests standards is the `automation` directory. This
directory needs to reside at the root of the project's source code and it
contains all the various files that specify how to preform various operations
with the project's source code.

Standard CI 'Stages'
--------------------

A core concept in the Build and Test standards is the concept of "stages".
Stages refer to various operations that are typically performed on a source code
change as it makes its way from being initially written by a developer to being
included in an official release.

Stages can be 'run' which means that the actions defined for a given stage are
performed.

The following stages are currently defined:

### build-artifacts

This stage defines how to build the source code into a set of user-consumable
artifacts such as RPM packages or Container Images.  This stage is run by the CI
system when a build of the source code is needed to preform tests or it was
either requested manually,

### build-artifacts-manual

This stage defines how to manually build a project from a source TARBALL. It is
used when official releases are composed via a manual process.

### check-patch

This stage defines how to perform correctness, quality, functionality or
regression checks on new code changes. The CI system run this stage to provide
feedback on Gerrit patchs or GitHub pull requests.

### check-merged

This stage is used to perform correctness, quality, functionality or regression
checks on the main project source code branches. The CI system runs this stage
after a patch is merged in Gerrit or commits are pushed to a branch in GitHub
(E.g. via merging a pull request).

### poll-upstream-sources

This stage is used for polling external data sources for information that is
needed to perform automated source code updates. An example for such a polling
process is when source code builds a container that is based on another
container (With e.g. a 'FROM' in in a Dockerfile). The source code typically
needs to specify a specific version of the base container so that builds are
reproducible, but keeping that version up to date can be cumbersome for
developers. The poll stage can be used to query for newer versions and
automatically generate appropriate source code changes.  The CI system run this
stage periodically. This stage is also used in conjunction with the source code
dependency functionality that is described below.

Attaching functionality to stages
---------------------------------

In order to specify what needs to be done in a given stage one needs to simply
drop a script file with the name of that stage and the `.sh` extension in the
`automation` directory. For example, to specify what should be done when the
*'check-patch'* stage is run, create the following file:

    automation/check-patch.sh

Despite the `.sh` extension, the script file could actually be written in any
language as long as the right interpreter is specified in a ["shabeng"][1] line
at the beginning of the script.

Since sometimes it is needed to do different things on different distributions,
it is also possible to specify different scripts per distribution by added a
distribution suffix to the script file name. For example, to have a different
`check-merged` script for 'CentOS 7.x', another different script for 'Fedora 26'
and a 3rd fall back script for all other distributions, create the following
three script files:

    automation/check-merged.sh.el7
    automation/check-merged.sh.fc26
    automation/check-merged.sh

The script files can also be symbolic links in case it is desired to place the
actual script file in a different location or to have the same functionality to
a set of different distributions.

[1]: https://en.wikipedia.org/wiki/Shebang_(Unix)

### Script runtime environment

The scripts are run in an isolated, minimal environments. A clone of the project
source code is made available inside those environments and the current working
directory for the script is set to the root of the project source code tree. The
clone includes the project's Git history, so the `git` command can be used to
query for additional information such as committed changes and tag names.

Runtime dependencies can be specified to make build tools and other resources
available for the build and test scripts. The way to define those is described
in the next chapter.

Declaring build and test dependencies
-------------------------------------

In order to provide reliable and reproducible test and build results, test and
build stage scripts are typically run inside isolated, minimal environments. It
is often the case that more software packages and other data is needed in order
to perform a certain test or a given build process.

It is possible for the stage script to include commands that obtain and install
required software and tools, but this standard also specifies a way to declare
requirements so that they can be provided automatically and efficiently while
the environment for running the build or test script is being prepared.

This standard currently defines and supports several kinds of dependencies:

* *Extra source code dependencies* - A project can specify that it needs to be
  tested or built along with the source code of another repository. This can be
  used for example, for projects that are mainly derived from the source of
  other (Upstream) projects.
* *Package dependencies* - A project can specify additional packages it requires
  for running test or build processes.
* *Package repository dependencies* - A project can specify packages
  repositories it needs to access in order to perform test and build processes
  or to install dependent software packages needed for those processes.
* *Directory or file mounts* - A project can specify that it needs to mount
  certain files or directories into its testing environment. This can be used to
  ensure certain cache files are preserved between different test runs or builds
  of the same project (Typically the test environment is destroyed when a build
  or a test is done), or to gain access to certain system devices or services.

### Dependency definition files

Unless otherwise stated below, project dependencies are defined separately
per-stage. And can additionally be defined separately per-distribution.

Project dependencies are specified via files that are places in the
`automation` directory and take the following form:

    automation/<stage-name>.<dependency-type>

For example, to define package dependencies for the '*check-patch*' stage, you
place them in the following file:

    automation/check-patch.packages

When specifying a per-distribution dependency, a distribution suffix needs to be
added. For example, to define mounts for the '*check-merged*' stage when it runs
on `el7`, use the following file:

    automation/check-merged.mounts.el7

As with script files, multiple files for different distributions can be created,
files can be symbolic links and the file without a distribution suffix is used
as the fall back file for distributions where a more specific file was not
created. There are no inheritance or inclusion mechanisms between different
dependency files, only one file is used to declare dependencies for a given
stage run on a given distribution.

### Dependency caching

System that are based on these build and test standards can utilize caching of
the build and test environments to improve performance. Therefore there is no
guarantee that the test environment will always contain the latest available
versions of required software packages for example.

If there is a need to guarantee installation of the latest version of a certain
component. It is recommended to have the stage scripts perform the installation
directly instead via the dependency definition files.

Doing it this way is almost guaranteed to have a performance impact on the oVirt
CI system for example, so care must be taken to use this technique only where
absolutely needed.

### Defining extra source code dependencies (AKA "Upstream Sources")

A project can define that source code from other source code repositories will
be obtained and merged into its own source code before build or test stages are
performed.

A project can specify this by including an `automation/upstream_sources.yaml`
file. The file format is as in the following example:

    git:
      - url: git://gerrit.ovirt.org/jenkins.git
        commit: a4a34f0f126854137f82701bc24976b825d9d1ae
        branch: master

The `git` key is used as a placeholder for future functionality, currently only
Git source code repositories are supported, but other kinds may be supported in
the future. The key points to a list of one or more definitions which contain
the following details:

* *url* - Specifies the URL of the repository from which to obtain the source
  code
* *commit* - Specifies the checksum identifier of the source code commit to take
  from the specified source code repository.
* *branch* - Specifies the branch to which the source code commit belongs. This
  is used to provide automated updates to this file as specified below.

The way source code dependencies are provided is as following - first all the
files from repositories given in the definitions in the `upstream_sources.yaml`
are checked out in the order in which they are specified in the file, and then
the project's source code repository is checked out on top of them. This means
that if the same file exists in several repositories, if will be taken from the
last specified one, while files from the project's own repository will override
all other files.

One needs to specify the exact dependency source code commit to take source code
from. This is needed to ensure building or testing a specific commit of the
project provides consistent results that are independent of changes done to
dependency source code repositories.

The downside of having to specify the exact commit to take from the dependency
repository is that it can be cumbersome to maintain the `upstream_sources.yaml`
file over time. Therefore an automated update mechanism exists for it. The
dependency source code repositories will be scanned in a scheduled manner, the
latest commits of specified branches will be detected, and source code patches
including the required changes to the file will be created automatically and
submitted for developer review.

This semi-automated update functionality is done as part of the
*'poll-upstream-sources'* stage. The stage script is run after updates are made
to the `upstream_sources.yaml` file and updated source code is collected,
therefore it can be used to automatically check the results of the automated
update process.

Only one `upstream_sources.yaml` file can be specified per-project, therefore it
is not possible to specify different source code dependencies for different
stages or distributions.

### Package dependencies

Package dependencies are specified in dependency definition files with the
`packages` suffix. For example to specify packages for `build-artifacts`
stage, create the following file:

    automation/build-artifacts.packages

The definition files simply list distribution packages, one per line. Here is an
example of the contents of a `check-patch.packages.el6` file:

    pyxdg
    python-setuptools
    python-ordereddict
    python-requests
    pytest
    python-jinja2
    python-pip
    python-mock
    python-paramiko
    PyYAML
    git

Note that the testing environment is very minimal by default, so even packages
that are considered to be ubiquitous such as `git` need to be specified.

Any of the distribution base packages can be asked for. In CentOS and RHEL,
packages from EPEL are also made available. For obtaining packages from other
repositories, these must be made available by defining them as repository
dependencies.

### Package repository dependencies

Package repository dependencies are specified in dependency definition files
with the `repos` suffix. For example to specify repositories for
`build-artifacts` stage running on CentOS7, create the following file:

    automation/build-artifacts.repos.el7

The package repository definition file can contain one or more lines of the
following format:

    [name,]url

Where the optional name can be used to refer to the package repository via `yum`
or `dnf` commands and the `url` point to the actual URL of the repository.

In oVirt's CI system the name will also be used to detect if there is a local
transactional mirror available for that repo and used it instead of using the
repo directly over the internet. It is highly recommended to consult the [list
of CI mirrors][2] and pick repository names and URLs from there.

For more information about the CI transactional mirrors, see the [dedicated
document][3]

[2]: List_of_mirrors.markdown
[3]: Transactional_mirrors.markdown

### Directory or file mount dependencies

Directory and file mount allow you to gain access to files and directories on
the underlying testing host from your testing environment. One must be careful
when using this feature since it is easy to make tests unreliable while using
it.

Directory and file mounts are specified in dependency definition files with the
`*.mounts` suffix. The files consist of one or more lines in the following
format:

    src_path[:dst_path]

Where *src_path* is the path on the host to mount and *dst_path* is the path
inside the testing environment. If *dst_path* is unspecified, the path inside
the testing environment will be the same as the one on the host.

If there is no file on the host in *src_path*, a new empty directory will be
created at that location.

Collecting build and test results
---------------------------------

Test processes are not very interesting unless one can tell if they succeeded or
not. Build processes are equally uninteresting if one cannot obtain the
resulting built artifacts.

Systems that support these build and test standards use the success or failure
return value from the stage script as the way to determine is running a stage
succeeded or failed.

If the build or test stages are run by a CI system, the system gathers up any
files or directories placed in the `exported-artifacts` directory under the
project's source code root directory and makes them available for download and
inspection.

### Specially treated files

A CI system can also provide special treatment to certain files if they are
found in `exported-artifacts` in order to provide richer output. Following is
a list of files the oVirt CI system treats in a special way:

* *RPM package files* - If any `*.rpm` package files are found in
  `exported-artifacts`, the CI system generates *yum* metadata files so that
  the entire directory can be used as a *yum* repository and hence any HTTP URL
  in which it is made accessible
* *HTML index file* - If an `index.html` file is found in
  `exported-artifacts`, it is included in the CI system's job summary page
* *JUNIT XML report files* - If any files with the `*.junit.xml` extension are
  found under `exported-artifacts` or in one of its sub directories, those
  files are read as JUNIT test result XML files. The test results are then made
  available for viewing from the oVirt CI Jenkins server. Test results are also
  tracked over time and changes can be tracked and analysed across builds.
* *Findbugs XML reports* - If any `*.xml` files are found in the
  `exported-artifacts/findbugs` directory, they are read as Findbugs result
  reports and made available for viewing via the ovirt CI Jenkins UI.

### Collecting container images

While container images can be store as plain files, it is typically not very
efficient to do so, instead, containers are typically stored in a deddicated
container storage.

The convention for handling of containers by the oVirt CI system is that when
building containers, a project would leave then on the build host's container
storage and tag then with the `exported-artifacts` tag. The CI system would
then pick up the containers and make them available for use from a dedicated
container repository.

Instruction on how to access the uploaded container images will be displayed in
the job results screen.

The dedicated container registry is currently simply an account on DockerHub,
this may be subject to change in the future.

Running Build and test Stages
-----------------------------

There are two major ways to run build and test stages:

1. Run stages locally on a developer's machine
2. Have stages run automatically by a CI system

### Running build and test stages locally

Running build and stages locally can be very useful when developing stage
functionality scrips. It can be also useful as a quick way to get a project
built or tested without having to worry about the project's specific build or
test requirements.

The currently available tool for running Standard-CI stages locally is
`mock_runner.sh`. for more details see [Using mock_runner to run Standard-CI
stages][4].

[4]: Using_mock_runner.markdown

### Having build and test stages run by a CI system

To have an automated CI system run build stages typically involves submitting
the code changes to a central source code management (SCM) system such as Gerrit
or GitHub and having the CI system pickup changes from there.

oVirt's CI system supports testing code for projects stored on oVirt's own
Gerrit server or on GitHub under the oVirt project. There are currently
different configuration procedures for projects on Gerrit and GitHub. Work is
under way to make the two look and feel the same.

To learn how to setup use the oVirt CI system with projects hosted on oVirt's
Gerrit, please refer to [Using oVirt Standard-CI with Gerrit][5].

To learn how to setup use the oVirt CI system with projects hosted on GitHub,
please refer to [Using oVirt Standard-CI with GitHub][6].

[5]: Using_STDCI_with_Gerrit.markdown
[6]: Using_STDCI_with_GitHub.markdown
