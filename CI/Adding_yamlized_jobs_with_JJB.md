Adding yamlized jobs to Jenkins with jenkins-job-builder
========================================================
This doc describes how to use jenkins-job-builder (JJB) in the CI environment
for creating/updating Jenkins jobs.

**Note:** This doc is intended for infra maintainers. If you are not an infra
 maintainer, and would like to add jobs to oVirt-Jenkins, please send
a patch to [jenkins repo][jenkins_git_repo] for review.

Introduction
------------
There are two ways to create/update a job on the Jenkins server from yaml
confs:

1. Run the Jenkins deploy job from an existing patch
2. Run jenkins-job-builder manually for an existing gerrit patch

**Important note:**
Any manual change made using this procedure, on a job that is already configured
in yaml on the Jenkins repo master branch, will be overwritten automatically
once the jenkins_master_deploy-configs_merged job runs.

Running the Jenkins deploy job
------------------------------
The deploy job on the Jenkins server is used for updating Jenkins jobs from a
gerrit patch containing a change/update in the yaml config. You can specify the
gerrit patch refspec and the name (or glob) of the job(s) to be updated.

A link to the job: <br>
http://jenkins.ovirt.org/job/jenkins_master_deploy-configs_merged_custom_notrigger

Running jenkins-job-builder manually
------------------------------------
JJB can be used in order to test/update jobs from yaml files on
jenkins.ovirt.org.
It can be found in the following repo:
http://resources.ovirt.org/repos/ci-tools

#### General steps for running jjb test/update:
1. Have a configuration file ready for the appropriate jenkins server.
2. Checkout the Jenkins repository of the relevant server and make the changes.
3. cd to the parent directory of the yaml directories (see below *Jenkins yaml confs repository*).
4. Run the jjb test command.
5. If the test went ok, run the jjb update command for the specific job.

#### Creating a jjb config file for jenkins.ovirt.org:
The config file should include the following lines:

    [jenkins]
    user=<your user name on the jenkins server>
    password=<api token from user settings->configure->show API token>
    url=http://jenkins.ovirt.org

    [job_builder]
    keep_descriptions=True
    recursive=True
    allow_empty_variables=True

#### Jenkins yaml confs repository:
Yaml directories located at the following location (yaml and project sub-directories)
https://gerrit.ovirt.org/gitweb?p=jenkins.git;a=tree;f=jobs/confs;hb=refs/heads/master

#### Testing your changes:
Run the following commands from the jobs/confs dir in order to test your code:

    jenkins-jobs --conf <jjbconfig file path>  --allow-empty-variables -l debug test -o <temp xml output dir> yaml:projects

#### Deploy your changes on the Jenkins server:
If the test went ok, run the following commands in order to update your code

    jenkins-jobs --conf  <jjbconfig file path>  -l debug update yaml:projects <job_name>

[jenkins_git_repo]: https://gerrit.ovirt.org/#/admin/projects/jenkins
