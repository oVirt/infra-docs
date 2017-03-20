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

