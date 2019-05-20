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
ci test please     | Run the '*check-patch*' stage
ci check please    | Run the '*check-patch*' stage
ci build please    | Run the '*build-artifacts*' stage
ci re-merge please | Re-run post-merge behaviour. [*](#fn1)

<small><a name="fn1">\*</a> This should only be used on the latest merged patch of a
project. **Using this on an unmerged or an older patch will yield unexpected
resuts!**</small>

**Note:** The 'please' keyword can actually be omitted or placed between 'ci'
and the second keyword.

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
system can gather most of the information it needs in order to build and test
the project from the project's own source code repository.

To make the CI system process a Gerrit project one needs to simply inform the
system about the project's existence.

To do that, the project name needs to be specified under the right server
section in the `jobs/confs/projects/standard-pipelines.yaml` file in the
[jenkins repo][4]. Here is an example of how the section for the 'oVirt'
production Gerrit server looks like:

    - project:
        name: oVirt-standard-pipelines-gerrit
        gerrit-server: 'gerrit.ovirt.org'
        project:
          - engine-db-query
          - fabric-ovirt

          ...

          - vdsm
        jobs:
          - '{project}_standard-gerrit-jobs'

**Note**: Given the amount of projects listed in that section, we make an effort
to keep the list in alphabetical order.

**Note**: Because '*poll-upstream-sources*' are executed periodically and not as
a response to Gerrit events, configuring them take a little more work and is
discussed below.

Once a patch to modify the YAML file is merged The YAML file will be read by the
[jenkins-job-builder][6] tool and CI jobs will be created on the [oVirt Jenkins
server][5] to provide the desired CI functionality.

You can find more information about tools you can use to edit and test YAML
files for `jenkins-job-builder` [here][7].

[4]: https://gerrit.ovirt.org/#/admin/projects/jenkins
[5]: http://jenkins.ovirt.org
[6]: https://docs.openstack.org/infra/jenkins-job-builder/
[7]: Adding_yamlized_jobs_with_JJB.markdown

Configuring `poll-upstream-sources` jobs for projects
-----------------------------------------------------

To enable automated source code updates to a project (E.g. to update upstream
commit mentioned in the `upstream-sources.yaml` file), one needs to create a
scheduled `poll-upstream-sources` job for each branch that needs to get
automated updates.

To create one or more jobs for a project, one needs to add a YAML section like
the following to the `jobs/confs/projects/standard-poll-stage-pipelines.yaml`
file in the [jenkins repo][4]:

    - project:
        name: ovirt-engine-metrics_standard-poll-upstream-sources
        project:
          - ovirt-engine-metrics
        branch:
          - master
        jobs:
          - '{project}_{branch}_standard-poll-upstream-sources'

All the branches that need to be updated must be listed under the `branch`
section.

If multiple projects have the exact same branch configuration, they can be
listed together under the `project` section.
