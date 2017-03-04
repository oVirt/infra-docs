Gerrit server-side hooks
=========================

In order to automate some checks on each patch that is sent, we have some
custom gerrit hooks installed on our gerrit instance.
There's a detailed explanation in the [gerrit hooks official docs] of the way
they work in a generic view.

Here are some of the oVirt-only details about how we use them.


Configurations
-----------------
**NOTE**: This info is very likely to be outdated, **do not rely on it's
freshness**, if the info you want has to be reliable, always check the gerrit
server itself for the current info.

We have hooks configuration on several different places:


### /home/gerrit2/review_site/hooks/config
    #!/bin/bash
    ## Credentials to use when connecting to bugzilla
    BZ_USER='automation@ovirt.org'
    BZ_PASS='******'
    ## Gerrit credentials/url used to review the patches (through ssh cli)
    GERRIT_SRV="gerrit-hooks@localhost"
    ## Gerrit credentials/url used to review the patches as jenkins
    JENKINS_GERRIT_SRV="jenkins@localhost"
    ## Tracker id on bugzilla for the autotracker hook
    ## 81 -> oVirt gerrit
    TRACKER_ID='81'
    TRACKER_NAME="oVirt gerrit"
    PRODUCT='oVirt'
    PRODUCTS=('oVirt' 'Red Hat Enterprise Virtualization Manager')
    CLASSIFICATION='oVirt'

### /home/gerrit2/review_site/git/infra-docs.git/hooks/config
    CHECK_TARGET_RELEASE=("master|^.*") 

### /home/gerrit2/review_site/git/lago.git/hooks/config
    CHECK_TARGET_RELEASE=("master|^.*") 
    PRODUCTS=('lago')

### /home/gerrit2/review_site/git/lago-images.git/hooks/config
    CHECK_TARGET_RELEASE=("master|^.*") 
    PRODUCTS=('lago')

### /home/gerrit2/review_site/git/ovirt-engine.git/hooks/config
    #!/bin/bash
    ## Branches to take into account
    BRANCHES=('ovirt-engine-3.6' 'ovirt-engine-3.6.0' 'ovirt-engine-3.6.1' 'ovirt-engine-3.6.2')
    STABLE_BRANCHES="ovirt-engine-3.6 ovirt-engine-3.6.5 ovirt-engine-3.6.6"
    CHECK_TARGET_RELEASE=("ovirt-engine-3.6|^3\.[6543210].*") 
    CHECK_TARGET_MILESTONE=('ovirt-engine-3.6|^.*3\.6.*') 
    PRODUCT="oVirt"

### /home/gerrit2/review_site/git/ovirt-hosted-engine-ha.git/hooks/config
    #!/bin/bash
    STABLE_BRANCHES="ovirt-hosted-engine-ha-1.1 ovirt-hosted-engine-ha-1.2 ovirt-hosted-engine-ha-2.0"
    CHECK_TARGET_RELEASE=("ovirt-hosted-engine-ha-1.1|^3\.4.*$" "ovirt-hosted-engine-ha-1.2|^3\.5.*$" "ovirt-hosted-engine-ha-2.0|^4\.0.*$") 

### /home/gerrit2/review_site/git/ovirt-hosted-engine-setup.git/hooks/config
    #!/bin/bash
    STABLE_BRANCHES="ovirt-hosted-engine-setup-1.1 ovirt-hosted-engine-setup-1.2 ovirt-hosted-engine-setup-2.0"
    CHECK_TARGET_RELEASE=("ovirt-hosted-engine-setup-1.1|^3\.4.*$" "ovirt-hosted-engine-setup-1.2|^3\.5.*$" "ovirt-hosted-engine-setup-2.0|^4\.0.*$") 

### /home/gerrit2/review_site/git/ovirt-system-tests.git/hooks/config
    CHECK_TARGET_RELEASE=("master|^.*") 
    PRODUCTS=('lago')

### /home/gerrit2/review_site/git/repoman.git/hooks/config
    CHECK_TARGET_RELEASE=("master|^.*") 
    PRODUCTS=('Repoman')

### /home/gerrit2/review_site/git/vdsm.git/hooks/config
    #!/bin/bash
    ## Branches to take into account
    BRANCHES=('ovirt-3.6')
    STABLE_BRANCHES="ovirt-3.6"
    CHECK_TARGET_RELEASE=("ovirt-3.5|^3\.[54321].*")
    CHECK_TARGET_MILESTONE=('ovirt-3.6|^.*3\.6.*')
    PRODUCT="oVirt"


List of projects and the hooks they use
----------------------------------------

**NOTE**: This list is very likely to be outdated, **do not rely on it's
freshness**, if the info you want has to be reliable, always check the gerrit
server itself for the current info.


### Common to all the projects
* [comment-added.propagate_review_values]

### All-Projects.git
* No hooks

### All-Users.git
* No hooks

### chrooter.git
* [change-abandoned.update_tracker]
* [change-merged.set_MODIFIED]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.bz.1.is_public]
* [patchset-created.bz.2.correct_product]
* [patchset-created.bz.98.set_POST]
* [patchset-created.bz.99.review_ok]
* [patchset-created.update_tracker]

### cockpit-ovirt.git
* No hooks

### cpopen.git
* [comment-added.propagate_review_values]

### fabric-ovirt.git
* [comment-added.propagate_review_values]

### gerrit-admin.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### gluster-nagios-monitoring.git
* No hooks

### imgbased.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### infra-docs.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* **HAS CUSTOM CONFIGURATION**: see the config file
* [patchset-created.update_tracker]

### infra-puppet.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ioprocess.git
* [comment-added.propagate_review_values]

### jasperreports-server-rpm.git
* [comment-added.propagate_review_values]

### jenkins.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### jenkins-whitelist.git
* No hooks

### lago.git
* [change-abandoned.update_tracker]
* [change-merged.set_MODIFIED]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* **HAS CUSTOM CONFIGURATION**: see the config file
* [patchset-created.bz.1.is_public]
* [patchset-created.bz.2.correct_product]
* [patchset-created.bz.98.set_POST]
* [patchset-created.bz.99.review_ok]
* [patchset-created.update_tracker]

### lago-images.git
* [change-abandoned.update_tracker]
* [change-merged.set_MODIFIED]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* **HAS CUSTOM CONFIGURATION**: see the config file
* [patchset-created.bz.1.is_public]
* [patchset-created.bz.2.correct_product]
* [patchset-created.bz.98.set_POST]
* [patchset-created.bz.99.review_ok]
* [patchset-created.update_tracker]

### mom.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### otopi.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-appliance.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-container-engine.git
* [comment-added.propagate_review_values]

### ovirt-container-node.git
* [comment-added.propagate_review_values]

### ovirt-docs.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-dwh.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-engine-api-explorer.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-engine-api-metamodel.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-engine-api-model.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-engine-cli.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-engine-dashboard.git
* No hooks

### ovirt-engine-extension-aaa-jdbc.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-engine-extension-aaa-ldap.git
* [comment-added.propagate_review_values]

### ovirt-engine-extension-aaa-misc.git
* [comment-added.propagate_review_values]

### ovirt-engine-extension-logger-log4j.git
* [comment-added.propagate_review_values]

### ovirt-engine.git
* [change-abandoned.update_tracker]
* [change-merged.set_MODIFIED]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* **HAS CUSTOM CONFIGURATION**: see the config file
* [patchset-created.bz.0.has_bug_url]
* [patchset-created.bz.1.is_public]
* [patchset-created.bz.2.correct_product]
* [patchset-created.bz.3.correct_target_milestone]
* [patchset-created.bz.98.set_POST]
* [patchset-created.bz.99.review_ok]
* [patchset-created.update_tracker]
* [patchset-created.warn_if_not_merged_to_previous_branch]

### ovirt-engine-sdk.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-engine-sdk-java.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-engine-sdk-js.git
* [comment-added.propagate_review_values]

### ovirt-engine-sdk-ruby.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-engine-sdk-tests.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-guest-agent.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-host-deploy.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-hosted-engine-ha.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* **HAS CUSTOM CONFIGURATION**: see the config file
* [patchset-created.bz.0.has_bug_url]
* [patchset-created.bz.1.is_public]
* [patchset-created.bz.2.correct_product]
* [patchset-created.bz.3.correct_target_release]
* [patchset-created.bz.98.set_POST]
* [patchset-created.bz.99.review_ok]
* [patchset-created.update_tracker]

### ovirt-hosted-engine-setup.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* **HAS CUSTOM CONFIGURATION**: see the config file
* [patchset-created.bz.0.has_bug_url]
* [patchset-created.bz.1.is_public]
* [patchset-created.bz.2.correct_product]
* [patchset-created.bz.3.correct_target_release]
* [patchset-created.bz.98.set_POST]
* [patchset-created.bz.99.review_ok]
* [patchset-created.update_tracker]

### ovirt-imageio.git
* No hooks

### ovirt-image-proxy.git
* [comment-added.propagate_review_values]

### ovirt-image-uploader.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-iso-uploader.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-jboss-modules-maven-plugin.git
* [comment-added.propagate_review_values]

### ovirt-live.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-log-collector.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-node-dbus-backend.git
* [comment-added.propagate_review_values]

### ovirt-node.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-node-iso.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-node-ng.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-node-plugin-hosted-engine.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-node-plugin-vdsm.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-node-tests.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-optimizer.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-register.git
* [comment-added.propagate_review_values]

### ovirt-release.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-reports.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-scheduler-proxy.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-setup-lib.git
* [comment-added.propagate_review_values]

### ovirt-system-tests.git
* [change-abandoned.update_tracker]
* [change-merged.set_MODIFIED]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* **HAS CUSTOM CONFIGURATION**: see the config file
* [patchset-created.bz.1.is_public]
* [patchset-created.bz.2.correct_product]
* [patchset-created.bz.98.set_POST]
* [patchset-created.bz.99.review_ok]
* [patchset-created.update_tracker]

### ovirt-testing-framework.git
* No hooks

### ovirt-testing-framework-tests.git
* No hooks

### ovirt-tools-common-python.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-vdsmfake.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-vmconsole.git
* [comment-added.propagate_review_values]

### ovirt-wgt.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### ovirt-wgt-toolchain.git
* [comment-added.propagate_review_values]

### pthreading.git
* [comment-added.propagate_review_values]

### releng-tools.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### repoman.git
* [change-abandoned.update_tracker]
* [change-merged.set_MODIFIED]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* **HAS CUSTOM CONFIGURATION**: see the config file
* [patchset-created.bz.1.is_public]
* [patchset-created.bz.2.correct_product]
* [patchset-created.bz.98.set_POST]
* [patchset-created.bz.99.review_ok]
* [patchset-created.update_tracker]

### safelease.git
* [comment-added.propagate_review_values]

### samples-portals.git
* [comment-added.propagate_review_values]

### samples-uiplugins.git
* [comment-added.propagate_review_values]

### test.git
* No hooks

### vdsm-arch-dependencies.git
* [comment-added.propagate_review_values]

### vdsm.git
* [change-abandoned.update_tracker]
* [change-merged.set_MODIFIED]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* **HAS CUSTOM CONFIGURATION**: see the config file
* [patchset-created.bz.0.has_bug_url]
* [patchset-created.bz.1.is_public]
* [patchset-created.bz.2.correct_product]
* [patchset-created.bz.3.correct_target_milestone]
* [patchset-created.bz.98.set_POST]
* [patchset-created.bz.99.review_ok]
* [patchset-created.update_tracker]
* [patchset-created.warn_if_not_merged_to_previous_branch]

### vdsm-imaged.git
* [comment-added.propagate_review_values]

### vdsm-jsonrpc-java.git
* [change-abandoned.update_tracker]
* [change-merged.update_tracker]
* [comment-added.propagate_review_values]
* [patchset-created.update_tracker]

### vmconsole.git
* [comment-added.propagate_review_values]


  [gerrit hooks official docs]: http://ovirt-gerrit-hooks.readthedocs.io
  [change-abandoned.update_tracker]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Python_hooks.html#update-tracker
  [change-merged.update_tracker]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Python_hooks.html#update-tracker
  [change-merged.set_MODIFIED]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Bash_hooks.html
  [patchset-created.update_tracker]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Python_hooks.html#update-tracker
  [patchset-created.warn_if_not_merged_to_previous_branch]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Python_hooks.html#patchset-created-warn-if-not-merged-to-previous-branch
  [comment-added.propagate_review_values]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Python_hooks.html#comment-added-propagate-review-values
  [patchset-created.bz.0.has_bug_url]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Bash_hooks.html
  [patchset-created.bz.1.is_public]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Bash_hooks.html
  [patchset-created.bz.2.correct_product]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Bash_hooks.html
  [patchset-created.bz.3.correct_target_milestone]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Bash_hooks.html
  [patchset-created.bz.3.correct_target_release]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Bash_hooks.html
  [patchset-created.bz.98.set_POST]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Bash_hooks.html
  [patchset-created.bz.99.review_ok]: http://ovirt-gerrit-hooks.readthedocs.io/en/latest/Bash_hooks.html
