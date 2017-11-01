Using oVirt Standard-CI with Gerrit
===================================

When projects are hosted in [oVirt's Gerrit server][1], the oVirt CI system can
provide automated building, testing and release services for them if they comply
with the [Build and Test standards][2].

[1]: https://gerrit.ovirt.org
[2]: Build_and_test_standards.markdown

Automated functionality of the oVirt CI system
----------------------------------------------

When projects are configured to use the oVirt CI system, the system responds
automatically to various event as they occur in the project source code in
Gerrit.

Here are actions that the CI system can be configured to carry out automatically:

1. The '*check-patch*' stage is run automatically when new non-draft patch sets
   are pushed to Gerrit. Note that the CI system can skip testing for trivial
   changes sure as changes that are made only to the commit message.
2. The '*check-merged*' stage is run automatically when patches are merged.
3. The '*build-artifacts*' stage is run automatically when patches are merged,
   and those artifacts are then submitted to the oVirt change queues for
   automated system testing with [ovirt-system-tests][3].
4. An automated check for upstream source changes followed by an invocation of
   the '*poll-upstream-sources*' is performed periodically.

[3]: http://ovirt-system-tests.readthedocs.io

Manual functionality of the oVirt CI system
-------------------------------------------

Certain parts of the CI system can be activated manually by adding certain
trigger phrases as comments on Gerrit patches.

The following table specifies which trigger phrases can be used:

Trigger phrase     | What it does
-------------------|----------------------------------
ci please build    | Run the '*build-artifacts*' stage
ci re-merge please | Re-run post-merge behaviour. [*](#fn1)

<small><a name="fn1">\*</a> This should only be used on the latest merged patch of a
project. **Using this on an unmerged or an older patch will yield unexpected
resuts!**</small>

The contributors white list
---------------------------

Gerrit is configured to allow anyone to send patches to any project. This is a
reasonable policy for an open source project, but it can pose a risk to the CI
system because one can send a patch with a malicious `check-patch.sh` script.

To mitigate this risk, the CI system only checks patches by white-listed oVirt
members. The white list is stored as a plain text file containing E-Mail
addresses in the [jenkins-whitelist repository][8].

For new oVirt contributors, patches should be sent to the repository to add ther
addresses to the white list files. **Care should be taken to review patches for
malicios code before doing so**.

[8]: https://gerrit.ovirt.org/#/admin/projects/jenkins-whitelist

Configuring the oVirt CI system for a project
---------------------------------------------
When a project complies with the oVirt [Build and Test standards][2], the CI
system can gather most of the information it need in order to build and test the
project from the project's own source code repository. There are, however, a few
critical pieces of information that system needs that are not currently included
within the standards and need to be specified elsewhere:

1. Which processing architectures (E.g. `x86_64` or `ppc64le`) does the project
   need to be built and tested on.
2. Which Linux distribution versions does the project need to be tested on.
3. Which branches of the project source code are meant to be released as part of
   oVirt and which version of oVirt does each branch target.
4. Which parts of the CI system should be enabled for the given project.

To specify the information above, a YAML file needs to be added to the
[jenkins][4] source code repository by submitting a patch to Gerrit.

Once the patch is merged The YAML file will be read by the
[jenkins-job-builder][6] tool and CI jobs will be created on the [oVirt Jenkins
server][5] to provide the desired CI functionality.

You can find more information about tools you can use to edit and test YAML
files for `jenkins-job-builder` [here][7].

[4]: https://gerrit.ovirt.org/#/admin/projects/jenkins
[5]: http://jenkins.ovirt.org
[6]: https://docs.openstack.org/infra/jenkins-job-builder/
[7]: Adding_yamlized_jobs_with_JJB.markdown

### Creating a project YAML file:
First, a project directory should be created in [jenkins repo][4] under
`jobs/confs/projects`. Within this directory, a project YAML file named
`{project name}_standard.yaml` should be created with content that resembles the
following example:

    - project: &base-params  # this syntax is used for inheritance
        name: ovirt-dwh_standard
        project:
          - ovirt-dwh
        version:
          - master:
              branch: master
          - 4.1:
              branch: ovirt-engine-dwh-4.1
          - 4.0:
              branch: ovirt-engine-dwh-4.0
        stage:
          - check-patch
          - check-merged
          - poll-upstream-sources
        distro:
          - el7
          - fc24
          - fc25
        exclude:
          - { version: master, distro: fc24 }
          - { version: 4.0,    distro: fc25 }
          - { version: 4.1,    distro: fc25 }
        trigger: 'on-change'
        arch: x86_64
        jobs:
          - '{project}_{version}_{stage}-{distro}-{arch}'

    - project:
        <<: *base-params  # this syntax indicates inheritance
        name: ovirt-dwh_build-artifacts
        stage: build-artifacts  # the stage parameter is overwritten
        jobs:
          - '{project}_{version}_build-artifacts-{distro}-{arch}'
          - '{project}_{version}_{stage}-on-demand-{distro}-{arch}'


The following parameters must be specified under the `project` entry in the
file:

* **project** - The name of the project(s) to create the jobs for
* **version and branch name** - The oVirt versions that the project targets, and
  the branches in the project source directory that match them should be
  specified. Only supported oVirt versions should be used. If other versions are
  specified, they will not be processed by the automated system testing and
  release jobs.
  For example, if a project has the `master` and `1.0` branches targeting the
  `master` and `4.1` oVirt versions respectively, this should be set as
  following:

        version:
          - master:
              branch: master
          - 4.1:
              branch: '1.0'

    The same branch can be set to target multipile oVirt versions. If the same
    branch targets all oVirt versions, a short-hand syntax like the following
    could be used:

        version: [ master, '4.1' ]
        branch: master

* **stage** - The standard stage(s) to create the jobs for. Can be one or more
  of:
    * *check-patch*
    * *check-merged*
    * *build-artifacts* - See below an important note for this stage
    * *build-artifacts-manual* - See below an important note for this stage
    * *poll-upstream-sources*
* **trigger** - How should jobs be triggered. Can be either:
    * *on-change* - This will trigger the jobs automatically on the appropriate
      source code events as specified above. This is what you will use in most
      cases.
    * *timed* - In some rare cases it may be desirable to have certain stages be
      triggered on a scheduled basis as opposed to on source code changes for
      performence reasons. Please consult with the CI team before trying to use
      this.
    * *manual* - This value is specifically for the build-artifacts-manual
      stage. See the note below.

The following paramters can be specified in YAML to customize various setting
for the project. If left unspecified, default values would be used:

* **distro** - One or more distributions that should be tested (e.g. `el7`,
  `fc24`), If unspecified only `el7` jobs will be created.
* **arch** - One or more architectures that should be tested (e.g. `x86_64`,
  `ppc64le`). If unspecified, only `x86_64` will be tested.
* **scmtype** - The type of SCM to use - Currently only `gerrit` is supported.
* **gerrit-subpath** - A sub directory in the Gerrit server where the project
  could be found. This can be used for working with Gerrit servers that include
  sub directories.
* **git-proto** - The protocol to use for cloning from git. The default value
  should work in most cases.
* **git-server** - The GIT server to clone source from. This should only be
  changed in rare cases.
* **gerrit-server** - The Gerrit server to listen for events from. This should
  only be changed in rare cases, and should typically be set to the same value
  as `git-server`.

The jobs that will be created will be given a name in the form of:

    {project}_{version}_{stage}-{distro}-{arch}

For each configuration option specified above, multiple values can be given by
using the YAML list syntax. If multiple values are given, a cartesian product of
all the possible combinations of all values for all options will be calculated
and jobs will be created for each combination.

Specific combinations can be excluded by specifying them in YAML with the
`excludes` option.

More examples for project YAML files can be found in the [jenkins source code
repository][4] under the `jobs/confs/projects` directory.

### A note about adding build-artifacts jobs:
When creating build-artifacts jobs, the `jobs` parameter value under the
project's definition should be in the following form:

    {project}_{version}_build-artifacts-{distro}-{arch}

This is because the way that the YAML template of the *build-artifacts* jobs is
configured. As a result, there should be a separate project definition block for
the *check-patch*/*check-merged* and the *build-artifacts* jobs as seen in the
example above.

To enable triggering of the *build-artifacts* stage when adding the 'ci please
build' comment in Gerrit, the following line should also be added as a value
under the `jobs` parameter:

    {project}_{version}_{stage}-on-demand-{distro}-{arch}

See the example above for how to cofigure the job for '*build-artifacts*'.

#### A note for adding build-artifacts-manual jobs:
When creating build-artifacts-manual jobs, the 'trigger' parameter should be
set to 'manual', and the 'jobs' parameter value should be in the form of:

    {project}_{version}_build-artifacts-manual-{distro}-{arch}

As a result there should be a separate project definition for the
build-artifacts-manual jobs. See example below:

    # Only needed to allow building from TARBALLs
    - project:
        <<: *base-params  # this syntax indicates inheritance
        name: ovirt-dwh_build-artifacts-manual
        stage: build-artifacts-manual  # the stage parameter is overwritten
        trigger: manual  # the trigger parameter is overwritten
        jobs:
          - '{project}_{version}_build-artifacts-manual-{distro}-{arch}'

Additionally, for *build-artifacts-manual*, another job should be created, named
`{project}_any_build-artifacts-manual`. In this job the user will upload a local
tarball, and select the version of the product from a drop-down menu. The job
will then call the relevant distro-specific *build-artifacts-manual* jobs for
the specified version, and pass the tarball to them. The triggered jobs will
then run the `build-artifacts-manual.sh` script inside a mock environment.

In order to create this job, another project configuration should be added to
the project YAML file, specifying the project name and the list of supported
versions (this list will be shown to the user as a drop down menu).

An example for adding the `{project}_any_build-artifacts-manual` to YAML:

    - project:
        project: ovirt-dwh  # you may also use inheritance for the project name
        name: ovirt-dwh_build-artifacts-manual-any
        version:
          - '3.6'
          - '4.0'
          - 'master'
        jobs:
          - '{project}_any_build-artifacts-manual'



