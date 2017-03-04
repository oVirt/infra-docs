oVirt Jenkins Server
=================================
jenkins.ovirt.org is a VM running in the PHX data center, under the
Production_CentOS cluster. It serves as our main CI server.

#### DNS
ovirt.org zone has a CNAME record jenkins.ovirt.org pointing to
jenkins.phx.ovirt.org

#### HTTP Server
The Jenkins application is sitting behind Apache web server, configured
with a local reverse proxy.


#### Storage
The VM has a secondary block device connected, which has no partition
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
What that isn't configured by Puppet is:
Global Jenkins configuration, credentials and Jenkins users.

The puppet code can be found in git://gerrit.ovirt.org/infra-puppet.git
under site/ovirt_jenkins directory.


#### Installing or upgrading plugins

From past experience, almost every Jenkins upgrade broke some plugin.
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

#### Upgrading Jenkins
1. Pick the version you want to upgrade to from [here][jenkins_repo].
2. Create a patch which changes the jenkins_ver parameter in common.yaml:
	ovirt_jenkins::jenkins_ver: x.xxxxxxxx
3. Stop puppet on jenkins.phx.ovirt.org
4. Merge the patch and run manually puppet on Jenkins with SSH to monitor.

This procedure was tested successfully on upgrading between 1.6x LTS and
from 1.6 LTS to none-stable versions(2.x).

#### Points to consider before upgrading Jenkins
As bundled plugins tend to break between upgrades, first check which
plugins are included in the new version. Download the proposed jenkins.war
from the [official repo][jenkins_war] and also download [plugin_discover.py][plugin_disc],
and run:

		> python plugins_discover.py --jenkins_war /path/to/war/jenkins.war
		script-security : 1.13
		antisamy-markup-formatter : 1.1
		windows-slaves : 1.0
		ssh-slaves : 1.9
		ssh-credentials : 1.10
		javadoc : 1.1
		pam-auth : 1.1
		cvs : 2.11
		external-monitor-job : 1.4

Compare the results with the plugins we already have in common.yaml, they
might need to be updated. Either way, at least when tested on Jenkins 1.x,
the plugins which are in common.yaml will always be used, over the bundled
ones.


### Testing new plugins or new Jenkins version in a development environment
1. Create a new VM in foreman(or use jenkins-staging.phx.ovirt.org).
2. Setup a new puppet testing environment following [this][p_dev].
3. Move your new VM to that testing environment.
4. Attach ovirt_jenkins Puppet class to the VM(in foreman).
5. Push your changes of common.yaml into the testing branch you created.
6. Run puppet and iterate as needed.



### Monitoring
Currently we have 2 types of monitoring,
1. [Icinga alerts][icinga_mon] -
The alerts configuration can be found in the Puppet manifest.

2. [Quantitative monitoring using Graphite and Grafana][graphite_mon] -
These metrics are collected using a [daemon][jenkins_graphite] that samples
Jenkins every few seconds. Its installation and dashboard configuration
should also be moved to puppet in the future.



[p_dev]: ../General/Puppet.markdown
[plugin_disc]: https://github.com/nvgoldin/jenkins-scripts/blob/master/plugins_discover.py
[jenkins_repo]: http://pkg.jenkins-ci.org/redhat-stable/
[jenkins_war]: http://mirrors.jenkins-ci.org/war-stable
[icinga_mon]: https://monitoring.ovirt.org/icinga/cgi-bin/extinfo.cgi?type=1&host=jenkins.phx.ovirt.org
[graphite_mon]: http://graphite.phx.ovirt.org/dashboard/db/jenkins-monitoring
[jenkins_graphite]: https://github.com/nvgoldin/jenkins-graphite
