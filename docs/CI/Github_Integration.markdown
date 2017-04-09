Github integration
===================

In order to integrate projects which are hosted on Github server instead
of (default) Gerrit, few steps should be done.

Opening a ticket
-----------------
Everything should be done using oVirt jira ticketing system.

Project transfer
-----------------
First of all the project **MUST** be transferred to oVirt organization.
This is the requirement of GitHub pull request builder plugin oVirt infra uses for the integration.
Project owner **MUST** initialize the transfer. Owner of the project is added as admin to
the new project to manage integration, contributors, whitelists etc.

Granting permissions to ovirt-infra bot on your repository
----------------------------------------------------------
After the project is under the oVirt organization, log into GitHub and go to:
``Project Settings->Colllaborators & Teams-> Add a team``,
choose ``bots`` team, and grant it ``admin`` permissions.
When the jobs will be generated in Jenkins, it will use the bot credentials,
which are already configured in Jenkins global settings, to setup the webhooks.
The webhooks will send POST requests on each PR. There is no need to configure
the webhooks manually.

Project directory
-----------------
Should be created under jenkins/jobs/confs/projects and named as a project in github.
The content of the directory as follows:

> jenkins/jobs/confs/projects/${PROJECT_NAME}/${PROJECT_NAME}_standard.yaml

The content of single yaml file is pretty straightforward.
** NOTE ** %%project_name%% **MUST** be replaced with actual name of the project

### jenkins/jobs/confs/projects/${PROJECT_NAME}/${PROJECT_NAME}_standard.yaml
	- %%project_name%%_common:
	    name: %%project_name%%
	    %%project_name%%_common--key: &%%project_name%%_common
	      project: %%project_name%%
	      version:
	        - 4.1:
	            branch: ovirt-4.1
	        - master:
	            branch: master
	      distro:
	        - el7
	        - fc24
	        - fc25
	      trigger: 'on-change'
	      arch: x86_64
	      deploy-to: ovirt
	      org: oVirt
	      github-auth-id: 'ovirt-infra'
	      repotype: experimental

	- project:
	    <<: *%%project_name%%_common
	    name: %%project_name%%_check_patch_standard
	    stage: 'check-patch'
	    jobs:
	      - '{project}_{version}_github_check-patch-{distro}-{arch}'

	- project: &build-artifacts-params
	    <<: *%%project_name%%_common
	    name: %%project_name%%_checks_standard
	    stage: 'build-artifacts'
	    jobs:
	      - '{project}_{version}_github_{stage}-{distro}-{arch}'


Debugging
---------
1. After the jobs were created, log into GitHub and go to
``Project settings->webhooks``, and choose the webhook which contains
``jenkins.ovirt.org`` inside its endpoint. Check that the recent events
were sent without errors.

2. On Jenkins side, the 'raw' GitHub events can be viewed at:
[GitHub Pull Request Plugin Logs](http://jenkins.ovirt.org/log/org.jenkinsci.plugins.ghprb/)

3. For lower-level interaction between Jenkins and GitHub, see:
[GitHub Plugin logs](http://jenkins.ovirt.org/log/org.kohsuke.github/),
If for some reason you encounter a message similar to:
```
Rate limit now: GHRateLimit{remaining=1, limit=5000, resetDate=Sun Apr 09 13:07:54 UTC 2017}
```
It means we reached the GitHub rate limit of 5000 requests/per hour. This
happens quickly if the projects are configured to use polling. When using
webhooks - it should be difficult to reach that limit.
