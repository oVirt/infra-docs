Creating Gerrit Projects/Repositories
=====================================

Creating new repositories in Gerrit is an operation which requires a number of
manual steps, both to match existing project configuration, and because there
is no tooling around some of the configuration.

Prerequisites
=============

* Admin access to the Gerrit web UI
* SSH access to gerrt.ovirt.org:22, yielding a shell, and sudo access on that
  host
* Be an owner of the oVirt Project on github to create repos to sync to

Creating a Group in Gerrit
============================

Group creation can be found in the Gerrit web UI under `People`.

The convention used by oVirt is for every project in Gerrit to have a matching
project owner group which includes the project + `-maintainers` name,
comprised of the users who will have permissions to that project.

For example, a `foobar` project should have a `foobar-maintainers` group.

It's easy to add or remove members to a group either
from a specific project => `Access` =>
clicking on `<project>-maintainers` group  => members
or
from `People` => `<project>-mintainers` group => members

Creating a Project in Gerrit
==============================

Once the group is created, proceed to creating the project. This is found
in the Gerrit web UI under `Projects` => `Create New Project`.

Create the project with your desired name and inherit project rights
from All-Projects.

* Project Name: 'your desired project name'
* Rights Inherit From: `All-Projects`

If this is initial development, with
no git history which will be pulled in from Github or elsewhere, check the
"Create initial empty commit" checkbox.

Drill into the project settings (under `Projects/General`, or searching),
and make sure the settings match the following:

* Submit Type: Rebase if Necessary
* Require `Signed-off-by` in commit message: True

Other settings can be changed if necessary, but default to (ignoring
INHERIT):

* State: Active
* Automatically resolve conflicts: FALSE
* Require `Change-Id` in commit message: TRUE

Setting permissions to a project in Gerrit
===========================================

Basically all the default permissions are inherited from `All-Projects` group.
It's set during the project creation.

The default permissions include the following rights:

|   **Right(s)**                        |   **Group(s)**                      |
|---------------------------------------|-------------------------------------|
|   View (Read) projects and patches    |   Anonymous and Registered Users    |
|   Add new patch                       |   Registered Users                  |
|   Forge Author Identity               |   Registered Users                  |
|   Forge Committer Identity            |   Project Owners                    |
|   Add Code Review +2 label            |   Project Owners                    |
|   Add Code Review +1 label            |   Registered Users                  |
|   Add Continuous Integration +1 label |   Project Owners                    |
|   Add Verified +1 label               |   Registered Users                  |
|   Remove a Reviewer                   |   Project Owners                    |
|   Submit a patch                      |   Project Owners                    |
|   Edit a Topic                        |   Registered Users                  |
|   Create Annotated/Signed Tag         |   Project Onwers                    |

In order to give to our group a full permission on the project,
we must to set our group as the project `Owners` group.

Click on the `Access` under `Projects` => `Edit`

Click on the `Add Reference` => change the Reference from `refs/heads/*` to `refs/*`.

Click on the `Add Permission...` drop-down box, it will show
a list of possible rights for our project, select the `Owner`
and it will add it to the list.

Click on the `Add Group` and select the group you created earlier,
and make sure that the `ALLOW` right is granted.

Add a Commit Message => Click on the `Save Changes` button.

Note: You can add a specific permission which will override the default one
but it's not recommended.

For example: you can change the default permission to add Verify +1 label
to a specific group (default: Registered Users)

Enabling Anonymous Cloning
==========================

In order to allow cloning over the git protocol (which also allows for github
mirroring), it's necessary to ssh directly into `gerrit.ovirt.org`.
If you have an alias for it in `ssh_config`, you may need to pass `-p 22`
to ssh to avoid trying to ssh into gerrit.

    ssh -p 22 youruser@gerrit.ovirt.org

Then change to the gerrit2 user

    sudo -i -u gerrit2

Gerrit lives under `~gerrit2/review_site`. chdir to your new project

    cd ~/review_site/git/foobar.git

From here, two steps must be taken. First, gerrit requires the existence of a
file named `git-daemon-export-ok` in the project root in order to serve it
over git://

    touch git-export-daemon-ok

Enabling Default Gerrit Hooks
=============================

oVirt projects supports various verification gerrit hooks which verify
a number of common criteria for patches.
You need to enable those hooks when you create a new project.
This is most easily done by copying them from an existing project
(with `cp -d` to preserve symlinks, since they are links back to base scripts).
You should ensure that the hooks you're copying are links to `~gerrit2/review_site/hooks`

    hooks/change-abandoned.update_tracker -> /home/gerrit2/review_site/hooks/custom_hooks/update_tracker
    hooks/change-merged.update_tracker -> /home/gerrit2/review_site/hooks/custom_hooks/update_tracker
    hooks/comment-added.propagate_review_values -> /home/gerrit2/review_site/hooks/custom_hooks/comment-added.propagate_review_values
    hooks/patchset-created.update_tracker -> /home/gerrit2/review_site/hooks/custom_hooks/update_tracker

Creating the Github repository
==============================

Finally, log into Github, and create a new repository. When creating the repo,
there is a dropdown box preceding the input box for the repository name which
is populated with `yourusername`. Change it to `oVirt`.

The repository name should exactly match the name of the project in gerrit. If
it was `foobar`, Github should also be `foobar`.

The description should be:

    This is a mirror for http://gerrit.ovirt.org, for issues use
    http://bugzilla.redhat.com

It's not necessary to select the "Initialize this repository" checkbox.

TODO: add verify steps to make sure the repo is synced to GitHub.

Enable Gerrit to Gihub mirroring
================================

The mirroring is run using the gerrit replication plugin.
In order to enable gerrit to github mirroring, First we need to make sure
our new repository (foobar) is exist on github.

Second we need to ssh directly into `gerrit.ovirt.org` as explained in the
`Enabling Anonymous Cloning` section.

Third we need to update the replication.config file with our new project
that should be replicated.

	vi ~/review_site/etc/replication.config

Add your new project (foobar) under the `[remote github]` section.
Each project should be on a separate line.
In the next example only foobar project will be replicated.

	projects = foobar

Regex can be used by adding ^ at the begging of the line
In the next example foobar-prod and foobar-test projects will be replicated.

	projects = ^foobar-(prod|test)

You can check the replication_log file to see the status of your replication

	tailf ~/review_site/logs/replication_log

Populating the repository
=========================

Treat this like any other git repository with a couple of nits. If it's a
brand-new project with no existing code, the initial commit you should have
selected in Gerrit will suffice.

If you're pushing from somewhere else, you can clone that repository, add the
gerrit project as a remote, and push. However, in order to push, you'll need
to add the `Push` right to the Gerrit project configuration, with a group
that you're a member of. `Force Push` is available under `Push` for extreme
cases.

If you're not the author of all the commits, `Forge Author` and `Forge
Committer` may need to be set, otherwise the Gerrit hooks will reject your
push, even if forced.
