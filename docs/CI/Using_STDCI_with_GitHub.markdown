Using oVirt Standard-CI with GitHub
===================================

The oVirt CI system can provide automated building, testing and release services
for projects in GitHub as long as they comply with the [Build and Test
standards][1].

[1]: Build_and_test_standards.markdown

Automated functionality of the oVirt CI system
----------------------------------------------

When projects are configured to use the oVirt CI system, the system responds
automatically to various event as they occur in GitHub.

Here are actions that the CI system can be configured to carry out automatically:

1. The '*check-patch*' stage is run automatically when new pull-requests are created.
2. The '*check-merged*' stage is run automatically when commits are pushed to
   branches. In particular, this happens when pull-requests are merged.
3. If release branches are configured (see below), the '*build-artifacts*' stage
   is run automatically when commits are pushed (Or PRs are merged) to those
   branches. The built artifacts are then submitted to the oVirt change queues
   for automated system testing with [ovirt-system-tests][2].

[2]: http://ovirt-system-tests.readthedocs.io

Manual functionality of the oVirt CI system
-------------------------------------------

Certain parts of the CI system can be activated manually by adding certain
trigger phrases as comments on pull-requets.

The following table specifies which trigger phrases can be used:

Trigger phrase      | What it does
--------------------|--------------------------------------------------------
ci test please      | Run the '*check-patch*' stage
ci build please     | Run the '*build-artifacts*' stage
ci add to whitelist | Add the PR submitter to the *contributors white list*

The contributors white list
---------------------------

GitHub allows anyone to send pull-requests to any project. This is a reasonable
policy for an open source project, but it can pose a risk to the CI system
because one can send a PR with a malicious '`check-patch.sh`' script.

To mitigate this risk, the CI system only checks pull-requests by members of the
GitHub organisation the checked project belongs to (E.g oVirt) automatically.

After checking that a PR from a new contributor does not contain malicious code,
members of the project's GitHub organisation can activate the CI system for it
in one of two ways:

1. Add a comment with `ci test please` on the PR - This will make the CI
   system run the tests once.
2. Add a comment with `ci add to whitlist` on the PR - This will make the CI
   system run the tests and additionally add the user that submitted the PR to a
   temporary white list so that further changes to the same PR or other PRs from
   that user are tested automatically by the system.

The white list is temporary and will be purged from time to time. It is
recommended that long term contributors be added as members to the GitHub
organisation.

The `automation.yaml` file
----------------------------

In order to build or test a project, the CI system requires some extra
information that is not specified by the [Build and Test standards][1]. This
information includes:

1. Which processing architectures (E.g. `x86_64` or `ppc64le`) does the project
   need to be built and tested on.
2. Which Linux distribution versions does the project need to be tested on.
3. Which branches of the project source code are meant to be released as part of
   oVirt and which version of oVirt does each branch target.

To specify this information, an `automation.yaml` file needs to be placed in
the project's root directory with content that resembles the following example:

    archs: x86_64
    distros:
      - fc25
      - fc26
      - el7
    release_branches:
      master: ovirt-master
      ovirt-ansible-1.0: ovirt-4.1

The file can contain the following parameters:

* **archs** - The architectures on which to run tests and builds for the project
  (E.g. `x86_64` or `ppc64le`). Multiple values an be given as a list. A single
  value can also be specified as a plain string. If the parameter is not
  specified the project will be built and tested on `x86_64`.
* **distros** - The Linux distributions on which to run tests and builds for the
  project. The following values are currently supported:

    * `el6` - For 'CentOS 6'
    * `el7` - For 'CentOS 7'
    * `fc24` - For 'Fedora 24'
    * `fc25` - For 'Fedora 25'
    * `fc26` - For 'Fedora 26'
    * `fc27` - For 'Fedora 27'
    * `fcraw` - For 'Fedora rawhide'

    Multiple values can be given as a list. A single value can also be specified
    as a plain string. If the parameter is not specified, the project will be
    build and tested on 'CentOS 7'.

* **release_branches** - A mapping between project branches that should be built
  and released with oVirt, and the oVirt versions they will be released with.
  An oVirt versions is specified as the name of the change queue that tests and
  prepares that version (E.g. `ovirt-master` or `ovirt-4.1`). A list of change
  queues can be given for a single branch, in that case, changes merged to it
  will be submitted to all specified change queues in parallel.

All parameters in the file as well as the whole file itself are optional. If not
specified, projects will be tested on 'CentOS 7' on 'x86_64' by default (As long
as any standard stage scripts are included), and no release branches will be
configured.

Enabling oVirt CI for a GitHub project
--------------------------------------

Given that a project complies with the oVirt [Build and Test standards][1] and
includes an `automation.yaml` file as specified above, a few simple steps need
to be carried out to enable oVirt CI to work with it.

These steps include:

1. Adding permissions for the oVirt CI system in the project repository
2. Enabling the oVirt CI system to handle the project.
3. Adding a GitHub hook for handling PR events.
4. Adding a GitHub hook for handling push events.

Following are detailed instructions for carrying out the steps above. While it
is certainly possible for anyone to try them out, most people should simply open
a [Jira ticket][2] asking the oVirt CI team to do so. This could be done by
simply sending an email to [infra-support@ovirt.org][3] and specifying the
project organisation and name.

[2]: https://ovirt-jira.atlassian.net
[3]: mailto:infra-support@ovirt.org

### Adding permissions for the oVirt CI system in a project repository
It is best to grant 'admin' permissions for the 'ovirt-infra' user in the project.
This will allow the system to automatically configure some of the webhooks it
needs.

At the very least, 'write' permissions should be granted, so that the system
could wrote PR comments and commit test results.

It is possible to use a different user then 'ovirt-infra' so that comments will
come from a different identity, but this requires some work to configure
credentials for that user in the oVirt Jenkins server.

### Enabling the oVirt CI system to handle a project
Since anyone can setup hooks in GitHub that would send data to the oVirt CI
system. Projects need to be explicitly enabled in the system for it to handle
them.

To do that, the project name needs to be specified under the right organisation
section in the `jobs/confs/projects/standard-pipelines.yaml` file in the
[jenkins repo][4]. Here is an example of how the section for the 'oVirt'
organisation looks like:

    - project:
        name: oVirt-standard-pipelines-github
        github-auth-id: github-auth-token
        org: oVirt
        project:
          - ovirt-ansible
        jobs:
          - '{org}_{project}_standard-check-pr'

The `ovirt-ansible` can be seen to be specified in the list under the
`project` sub key. Other projects in the 'oVirt' organisation should be added
to the same list, and a patch with the modified file should be submitted to
Gerrit for review.

[4]: http://jenkins.ovirt.org

### Adding a GitHub hook for handling PR events
If the oVirt CI system user had been given 'admin' permissions to the project
prior to merging the patch to enable the CI system as specified above. This hook
can be configured automatically by the system.

To configure the hook manually, go the project 'Settings' page, select
'Webhooks' from the left menu and click on 'Add webhook'.

In the 'Payload URL' field fill in the following URL:

    http://jenkins.ovirt.org/ghprbhook/

In 'Content Type' fill in '`application/x-www-form-urlencoded`'

Leave the 'Secret' field empty.

Choose the 'Let me select individual events' option and check the following
event check boxes:
* Issue comments
* Pull request

Click on he green 'Add Webhook' button to add the webhook.

### Adding a GitHub hook for handling push events
To configure the hook, go the project 'Settings' page, select
'Webhooks' from the left menu and click on 'Add webhook'.

In the 'Payload URL' field fill in the following URL:

    http://jenkins.ovirt.org/generic-webhook-trigger/invoke

In 'Content Type' fill in '`application/json`'

Leave the 'Secret' field empty.

Choose the 'Just the push event' option.

Click on he green 'Add Webhook' button to add the webhook.
