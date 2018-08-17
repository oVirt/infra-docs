oVirt Jenkins Server
====================
jenkins.ovirt.org is a VM running in the Production cluster
of the PHX data center. It serves as the project's main CI server.

#### DNS
ovirt.org zone has a CNAME record jenkins.ovirt.org pointing to
jenkins.phx.ovirt.org

#### HTTP Server
The Jenkins application is running behind Apache web server
which acts as a reverse proxy.

#### SSL
Apache serves content via both HTTP and HTTPS. The certificate
is provided automatically using Puppet and Let's Encrypt based
on FQDNs in hieradata/hosts/ directory.

#### Storage
The VM has a secondary block device connected which has no partitions
and is configured under a LVM group. The device is mounted at
/var/lib/data and formatted as XFS filesystem. Jenkins itself is installed
on /var/lib/data/jenkins which means that all of Jenkins data is on that device.
In order to increase the mount size, first increase the device(/dev/vdb)
size in ovirt engine-ui and execute:

	pvresize /dev/vdb

	lvextend /dev/mapper/jenkins_lvm-data -LxxxxG
	xfs_growfs /dev/mapper/jenkins_lvm-data

or instead of the above 2 commands use -r option:

	lvextend -r /dev/mapper/jenkins_lvm-data -LxxxxG


#### Puppet
The VM is controlled by Puppet, this includes the installation and
configuration of: Apache, Jenkins, Jenkins plugins and packages dependencies.
What isn't configured by Puppet is:
Global Jenkins configuration, credentials and Jenkins users.

The puppet code can be found in git://gerrit.ovirt.org/infra-puppet.git
under site/ovirt_jenkins directory. As jenkins.ovirt.org is part of the
production Foreman environment, all code is in the respective branch of
this git repo. Other branches are used for test environments.


#### Installing or upgrading plugins

Installation wise there are 2 types of plugins:
1. 'Regular' plugins
2. Bundled plugins - those plugins come pre-installed with Jenkins. Thier .hpi
archive file is included in jenkins.war. If 'pinned' option is not used,
on each Jenkins restart the bundled version will take over.
Most errors we had after upgrades, were due to bundled plugins.

Do not install plugins via the GUI, the list of installed plugins is found in
infra-puppet.git/heiradata/common.yaml file:

	  ....
	  'momentjs':
	    version: '1.1.1'
	  'monitoring':
	    version: '1.55.0'
	  'multi-slave-config-plugin':
	    version: '1.2.0'
	  ...

When puppet runs it verifies these versions are found under
/var/lib/data/jenkins/plugins, if a different version is found, it will
download the correct version and restart Jenkins. This restart is not
graceful(done immediately)

All plugins are 'pinned' by default, this ensures that the versions are
managed via Puppet. Although this is automated the recommended way to see the
new plugins were installed properly is:
1. Disable puppet on jenkins.ovirt.org(pkill puppet should be enough)
2. Merge the patch
3. SSH to jenkins.ovirt.org and run: puppet agent --test --trace, you should
see something similar to:

		Notice: /Stage[main]/Ovirt_jenkins/Jenkins::Plugin[workflow-multibranch]/File[/var/lib/data/jenkins/plugins/workflow-multibranch.hpi.pinned]/ensure: created
		Info: /Stage[main]/Ovirt_jenkins/Jenkins::Plugin[workflow-multibranch]/File[/var/lib/data/jenkins/plugins/workflow-multibranch.hpi.pinned]: Scheduling refresh of Service[jenkins]

4. Watch /var/log/jenkins/jenkins.log if any new exceptions were introduced
by the plugin.

Take into account that puppet does not resolve dependencies between
plugins, so before installing a new plugin check in its official page which
other plugins it requires.

Jenkins upgrade checklist
=========================

### Update staging instance

#### Core

Verify the latest LTS core version at https://jenkins.io/changelog-stable/
If it is a minor version of the same X.Y release, then likely it's just a bugfix
with a reduced (but existing) chance of breaking changes.
The version can be used in the next step to update the hiera YAML

#### Plugins

SSH to jenkins-staging and stop puppet there

    $ ssh jenkins-staging.phx.ovirt.org
    $ sudo su -
    # systemctl stop puppet

Log in to the jenkins-staging web UI and update/install desired plugins:

[Staging Jenkins plugin manager][stg_jenkins_plugins]

Run "Check now" to update the update list (select "All" at the bottomto apply
all available updates) and press "Download now and install after restart"

When the update window appears, click "Restart Jenkins when installation is complete and no jobs are running" at the very bottom and wait till it restarts

Log back in and go to the script console:

[Staging Jenkins script console][stg_scripts]

Run the following groovy script to get installed plugins in a format
suitable for updating the YAML file later:

    Jenkins.instance.pluginManager.plugins.sort(false).each{
      plugin ->
        println ("  '${plugin.getShortName()}':")
        println ("    version: '${plugin.getVersion()}'")
    }


#### Hiera YAML

With this data on hand, the YAML file usea test patch can be created by manually editing the  hiera file:
Puppet configures Jenkins based on the contents of hieradata/common.yaml
To test the changes, first update this file in a test environment.
Currently jenkins-staging is part of the ederevea test environment
and its hiera file can be edited manually on foreman.ovirt.org:

    /etc/puppet/environments/ederevea/hieradata/common.yaml

Update ovirt_jenkins::jenkins_ver with the latest LTS version
and replace ovirt_jenkins::plugins with the list of plugins generated
by the groovy script in the previous step.

Save the file and run puppet on jenkins-staging to apply it.
This will restart jenkins once again with the new core version.

    # puppet agent -t

Verify the output of this command for errors and make changes if necessary.

#### Test the features

After jenkins comes up, verify that slaves are connected successfully and
perform the following tests to ensure that important components are working:

Go to github and trigger the webhook by commenting "ci test please" here:

[GitHub staging project PR page][github_stg_trigger]

Check that this started Jenkins jobs and verify they ran successfully.

Go to gerrit-staging and trigger jobs by commenting "ci test please" here:

[Staging gerrit patch][gerrit_stg_trigger]

Check that this started Jenkins jobs and verify they ran successfully.

#### Submit the patch

If all tests run fine, submit the patch to the production branch of the infra-puppet repo:

[infra-puppet on Gerrit][infra-puppet]

If tests were done manually, create the patch by cloning the above repo.
Replace hieradata/common.yaml with the one created on Foreman and submit
the resulting commit for review. After submitting verify the diff carefully.
If new plugins are introduced by the change, check if they were installed
as dependencies by other plugins:

[Staging Jenkins plugin manager][stg_jenkins_plugins_i]

Plugins installed as dependencies will have the "uninstall" button greyed out
and dependent plugins can be identified by hovering over this button.

If this is not the case the plugin was likely installed manually.
Sync with other team members on whether there is need for it in Production.
Otherwise remove such plugins from the patch to keep production clean.

After the content of the update patch is verified ensure the CI passed
and put it up for review (CI+1, Verified+1, Workflow+1).

#### Production upgrade process

Once new plugin versions are verified to work the upgrade can be scheduled.
Things to consider
* Prefer updating outside EMEA working hours.
* Avoid weekends, first half of the week works best.
* Sync with maintainters to avoid clashing with release dates.

When the change window is approaching, SSH to the production Jenkins and stop puppet on it:

    $ ssh jenkins.ovirt.org
    $ sudo su -
    # systemctl stop puppet

Merge the patch in Gerrit and wait for the system-update-puppet job to complete.

Send a notification e-mail to inform about the planned outage:

    To: infra list
    CC: devel list
    Subject: planned Jenkins restart
    Text:
    I will be performing a planned Jenkins restart within the next hour.
    No new jobs will be scheduled during this maintenance period.
    I will inform you once it is over.

Log in to Jenkins UI and switch it into the "prepare for shutdown" mode:

[Production Jenkins configuration][jenkins_manage]

This ensures no new builds are started before jenkins restarts.

Log in to Nagios and disable notifications for the jenkins host and its services:

[Nagios: disable notifications][nagios_off]

Wait for the jobs to complete (this may take time).
For ones that are stuck for some reason - write them down and kill them forcefully.
Note that all jobs in the build queue will be lost at restart.
Any time-based jobs can be ignored: they will be triggered again by the timer.

If a system reboot is needed, this is the time for it. Otherwise skip
this paragraph. Disable puppet and jenkins via systemctl, run yum update
and reboot the system. Ensure this update is tested on staging first!

Once no jobs are running, run puppet from the SSH session and monitor progress:

    # puppet agent -t

When the run is complete, Jenkins will be restarted by puppet.
It may take up to 15 minutes for the UI to become available.
Until that, monitor the log for signs of normal operation:
* nodes coming online
* webhooks being created
* gerrit polling starting

    # tail -f /var/log/jenkins/jenkins.log

As soon as the UI is back up verify that login is possible,
slaves are online and jobs are defined.

To double-check, re-run the puppet agent.
It should NOT change anything and NOT restart jenkins.
If this happens there may be something wrong, refer to the troubleshooting paragraph.

Wrap up the maintenance by re-enabling notifications in Nagios:

[Nagios: enable notifications][nagios_on]

Also, send a follow-up e-mail to inform about completion:

    Subject: Re: planned Jenkins restart
    Text:
    Maintenance completed, Jenkins back up and running.
    <mention related changes and Jira ticket if needed>
    
    If you see any issues please report them to Jira.

#### Troubleshooting

If something goes wrong during the upgrade, first of all
re-run puppet as sometimes it fails due to network timeouts:

    # puppet agent -t

If this does not help stop puppet to stop it from overwriting manual edits.

    # systemctl stop puppet

Inspect /var/log/jenkins/jenkins.log to identify the possible root cause.
Ensure plugins are not turned off due to unmet dependencies. Use the UI
to install plugins manually. It can also be used to upgrade/downgrade plugins.
Note that puppet does not delete plugins when they are removed from the YAML
so removal is performed manually by deleting plugin files.

If Jenkins does not start at all, verify /etc/sysconfig/jenkins for errors/typos
especially the JENKINS_JAVA_OPTIONS string.

### Setting up a new test instance
1. Create a new VM in foreman
2. Setup a new puppet testing environment following [this][p_dev].
3. Move your new VM to that testing environment.
4. Attach ovirt_jenkins Puppet class to the VM(in foreman).
5. Push your changes of common.yaml into the testing branch you created.
6. Run puppet and iterate as needed.

### Monitoring
Currently we have 2 types of monitoring,
1. [Nagios alerts][nagios_mon] -

2. [Quantitative monitoring using Graphite and Grafana][graphite_mon] -
These metrics are collected using a [daemon][jenkins_graphite] that samples
Jenkins every few seconds.


[p_dev]: ../General/Puppet.markdown
[plugin_disc]: https://github.com/nvgoldin/jenkins-scripts/blob/master/plugins_discover.py
[jenkins_repo]: http://pkg.jenkins-ci.org/redhat-stable/
[jenkins_war]: http://mirrors.jenkins-ci.org/war-stable
[jenkins_manage]: https://jenkins.ovirt.org/manage
[stg_scripts]: https://jenkins-staging.ovirt.org/script
[stg_jenkins_plugins]:   https://jenkins-staging.ovirt.org/pluginManager/
[stg_jenkins_plugins_i]: https://jenkins-staging.ovirt.org/pluginManager/installed
[infra-puppet]: https://gerrit.ovirt.org/#/admin/projects/infra-puppet
[github_stg_trigger]: https://github.com/oVirt/stage-gh-stdci1/pull/2
[gerrit_stg_trigger]: https://gerrit-staging.phx.ovirt.org/#/c/17/
[nagios_mon]: https://monitoring.ovirt.org/icinga/cgi-bin/extinfo.cgi?type=1&host=jenkins.phx.ovirt.org
[nagios_on]: https://monitoring.ovirt.org/nagios/cgi-bin/cmd.cgi?cmd_typ=28&host=jenkins.phx.ovirt.org
[nagios_off]: https://monitoring.ovirt.org/nagios/cgi-bin/cmd.cgi?cmd_typ=29&host=jenkins.phx.ovirt.org
[graphite_mon]: http://graphite.phx.ovirt.org/dashboard/db/jenkins-monitoring
[jenkins_graphite]: https://github.com/nvgoldin/jenkins-graphite
