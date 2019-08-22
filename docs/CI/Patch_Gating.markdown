Patch Gating
============

# Why do we want patch gating?

oVirt is a product built by multiple projects composed together.
In order to be able to test the projects patches we have system testing
on the product functionallity called OST(oVirt System Tests).

Before patch gating, OST was running as post-merge CI called `Change Queue`,
which knew how to block patches after bisecting all the patches to
find the relevant faulty patch.
The disadvatages of such design are:<br />
1. There is no early feedback for developers regarding their patches pass OST.<br />
2. Our CI team was monitoring the failures and reported back to developers
   regarding faulty patches.<br />
3. Once you merge before passing OST, you can break the project and you will
   need to send a patch to fix it. The fix might take days and by that time no
   patch will pass the tests.<br />
4. Not all patches passed into the tested repository which is by passing OST,
   as it depends on our team to monitor all the patches in the system.<br />

In order to overcome those disadvantages, we need a CI system that knows
how patches will affect the product before the patch is merged.
Zuul is a CI system that was designed for it and fill up all of the requirements
mentioned above and even more.


# What is Zuul?

Zuul is a CI system that is organized around the concept of pipelines.
In terms of Zuul, a pipeline is a workflow of jobs which are applied to
projects.<br />
For instance, we can create a pipeline called 'gate'.<br />
It will be triggered for every patch which is ready to be merged in the
remote git repository system(Gerrit / GitHub in oVirt).<br />
Pipelines also have events to trigger it.<br />
For example of 'gate' pipeline, Gerrit will trigger the labels for the patch
which are Code-Review +2, Verified +1 and CI +1 events and this will trigger
the 'gate' pipeline.<br />
Once all the jobs for a pipeline have been configured, the pipeline's reporters
are configured to report the results of the jobs. for example the 'gate'
pipeline will leave comments in the gerrit patch link once it's finished and
votes if configured (CI +1 for instance) and can merge automatically.<br />
The items enqueued into a pipeline are associated with git ref. The triggering
event determines the ref, and if it is a proposed changed,
Zuul prepares the ref for that item before running the pipeline jobs.
In this case the pipeline jobs will run with the git repo state of the change
merges.

in oVirt we decided to use Zuul as a pre-merge gating system. As it knows
to speculate the git repository after proposed changes patches, it is a great
system to use for gating before merging.


# Cross Project Gating

The way Zuul works is demonstrated below:

Let's say we have 3 projects: A, B and C.
Those projects needs to be defined in a shared queue within a dependent
pipeline.

We have one patch coming from each project: A~1, B~1 and C~1, and their
representive HEADS before merges: A, B, C.
Once those patches are reviewed and ready to be merged, meaning with
CI passing, verified and code looking good, Zuul will run 3 parallel tests
to those patches:

- (A~1, B, C)
- (A~1, B~1, C)
- (A~1, B~1, C~1)

If all of the tests pass, Zuul will automatically merge them. If not Zuul
can decide based on the successful tests which projects can be merged or not.
Let's say B-1 failed the tests, this means B-1 is dropped from the queue and
we will need to run another test which checks the patches (A-1, C-1).

Project gating examples can be found in [Zuul docs link][2]


# Zuul infrastracture in oVirt

Zuul services runs under softwarefactory project. They maintain it, and if you
encounter any issues with Zuul nodes you need to reach them out.
List of associated components is listed below.
Inside our Zuul node you can watch the associated git repositories,
read the Zuul jobs logs, status screen and more.
We have in our gerrit server our own Zuul configuration that determines
the pipeline jobs, the git repositories Zuul needs to be associated, the gerrit
server and source hosting nodes, servers that act as a git servers during the
gating pipeline.

Zuul components:<br />
1. [oVirt Zuul node][1] - The UI component of oVirt Zuul instance which
   includes the git repositories associated, jobs and more.<br />
2. Zuul executer - Runs the speculative merges and Zuul job ansible playbooks.<br />
3. [oVirt Zuul source hosting node][4] - This is the node which recieves from
   Zuul executers the speculative git repositories of the projects being tested.<br />
4. Gearman - Responsible for scheduling jobs on Zuul's executers.<br />
5. Zuul scheduler - Accepts Gerrit events notifcations and invokes tests on the
   Zuul executers.<br />
6. oVirt Jenkins - Zuul ansible playbooks invokes the gating job in Jenkins
   that runs the actual STDCI code and OST.<br />
7. oVirt OpenShift - The hardware which the tests runs on. Jenkins uses
   Kubernetes plugin to allocate Jenkins slave pods.


# Zuul integration in oVirt
In order to make Zuul works with our STDCI code and infra we made Zuul
interact with our Jenkins to trigger the OST gate pipeline job with the
projects patches.

We created a pipeline job under OST project which is called
[ovirt-system-tests_gate][8].
Once a patch is ready to be merged (Has Verified, CI, CR labels on), Zuul will
enqueue this patch to the gate and test it along other patches. If the patch
passes the gating, Zuul will automatically merge the patch and it's artifacts
will be published to gated-repository which is hosted in OpenShift.


# Onboard projects to Patch Gating

For oVirt project to be gated, you will need to follow the following steps:



1. In order for your project to be added to Zuul, it needs to be added
   to it's project list. the file can be located under git repository
   named [_ovirt-zuul-config_][3].<br />

        clone git repo ovirt-zuul-config
    Add your project in the file:

        resources/projects.yaml

    The file format looks like below:

        ---
        resources:
          projects:
            oVirt-CI:
              description: "Projects that make up oVirt's CI infrastructure"
            mailing-lists:
              - "infra@ovirt.org"
            documentation: |-
              "https://ovirt-infra-docs.readthedocs.io/en/latest/index.html"
            source-repositories:
              - jenkins
              - <your-project-name>

2.  Edit under the jenkins repo:

        playbooks/inventories/zuul_nodes.yaml

    You have to add the project name under the production/staging criteria
    and add it under the list of zuul_projects.

    Example of the file below:

           ---
           all:
              children:
                zuul_nodes:
                  children:
                    production:
                      hosts:
                        jenkins.ovirt.org:
                        zuul01.phx.ovirt.org:
                      vars:
                        zuul_tenant: ovirt
                        zuul_jobs_project: ovirt-zuul-config
                        zuul_projects:
                          - jenkins
                          - <your project name>


3.  Zuul needs SSH key to be able to work with the project repo.
    We use `ansible-playbook` command to create the SSH key. <br />
    The playbook can be found in the jenkins repo under playbooks directory.<br />
    The command to create the SSH key using the playbook file:

        ansible-playbook playbooks/zuul_node_setup.yaml -i
        playbooks/inventories/zuul_nodes.yaml --ask-become-pass -v

4. Zuul will search under the project dir the following file names / directories:

    - _zuul.yaml_
    - _.zuul.yaml_ (with a leading dot)
    - _zuul.d_
    - _.zuul.d_ (with a leading dot)

    You only need to create a zuul.yaml file as the following one:

        - project:
            templates:
              - ost-gated-project

    You can decide if to put it directly in the root of your project, or under
    zuul.d directory.<br />
    This file will tell Zuul that this projects needs to run only the
    ovirt-gated-project pipeline job. the pipeline job is defined in our jenkins
    repository.

Once the playbook is finished, the project is officialy onboard.


# Cross Project dependency

Zuul allows us to check patches that are dependend on other project patches.<br />
To let Zull know on depended patches, add them to the commit-message as shown below.<br />
You can add more than one dependency.

    Depends-On: https://gerrit.ovirt.org/<patch-number>

Zuul will know to test all dependencies together once they are ready.<br />
**Note:** The dependency goes only one direction, like DAG(Directected acyclic graph).<br />


# Patch Gating FAQ

**Q.** What is Patch Gating?<br />
**A.** Today we have post-merge OST that runs the patches after the projects are merged.<br />
Patch Gating is triggered **pre-merge** on patches and running OST as the *gate system tests*.<br />
This means developers get early feedback on their patches if it is passing OST.<br />

**Q.** What causes the gating process to start?<br />
**A.** Once a patch is verified, passed CI and has Code-Review +2 labels, the gating process will be started. You will receive a message in the patch.<br />
Message content is:<br />
`Starting gate-patch jobs.`

**Q.** How does it report results to my patches?<br />
**A.** A comment will be posted in your patch with the job URL failure.<br />
Message content is:<br />

    Build failed (gate pipeline).

    ost-gate http://jenkins.ovirt.org/job/ovirt-system-tests_gate/4 : FAILURE in 1h 23m 53s


**Q.** How will my patch get merged?<br />
**A.** If the patch has passed the gating (OST), Zuul (The new CI system for patch gating) will merge the patch automatically.<br />


**Q.** How do I onboard my project?<br />
**A.** There are 2 steps needed to be done:<br />
1. Open a [JIRA][5] ticket or mail to infra-support@ovirt.org.<br />
2. Creating a file named `zuul.yaml` under your project root OR `zuul.d/zuul.yaml` with the following content:<br />

      - project:
         templates:
          - ost-gated-project


**Q.** My projects run on STDCI V1, is that ok?<br />
**A.** No, the patch gating logic runs on STDCI V2 only! meaning that you will have to shift your project to V2.<br />
If you need help regarding the transition to V2 you can open a [JIRA][5] ticket or mail to infra-support@ovirt.org
and visit the [docs][7].<br />

**Q.** What if I want to merge the patch regardless of OST results?<br />
**A.** If you are a maintainer of the project, you can still merge the patch. We are **not** removing the merge button option.<br />
**Note**: Merging a failing patch can break your project. Merging on failure is not recommended.<br />

**Q.** My Patch is failing due to a cross-project patch dependency, what should I do?<br />
**A.** Patch Gating (Zuul) has a mechanism for cross-project dependency!<br />
To let Zuul know on depended patches, add them to the commit-message, as shown below.<br />
You can add more than one dependency.

    Depends-On: https://gerrit.ovirt.org/patch_number

Zuul will know to test all dependencies together once they are ready.<br />


**Q.** How do I debug OST?<br />
**A.** There are various ways of looking in the logs and output for errors:<br />
1. Blue Ocean view, you can see the jobs that were run inside the gate and find the suites which failed.<br />
2. ci_build_summary view, An internal tool to view the threads and redirect to the specific logs/artifacts.<br />
3. Test results analyzer, available if the tests were run. you can view the failed tests and their output and OST maintainers and your team leads should be able to assist.<br />
For further learning on how to debug OST please visit the [OST FAQ][6]<br />

**Q.** Will the current infrastructure be able to support all the patches?<br />
**A.** The CI team has made tremendous work in utilizing the infrastructure.<br />
The OST gating will run inside OpenShift pods unlike before as bare metals and we can
gain from that right now approximately 50 pods in parallel to run simultaneously and we will review adding more if the need arises.<br />

**Q.** When I have multiple patches, in which order will they be tested by the gating system?<br />
**A.** The patches will be tested as the flow they will be merged. The gating system knows how to simulate patches post merge.<br />

**Q.** What do I do if I think OST failed because of an infra issue and not my patch?<br />
**A.** Contact the CI team by sending mail to infra-support@ovirt.org and explain your concerns + sending the patch URL.<br />

**Q.** Will check-merged scripts be used by the gating system?<br />
**A.** No, they will be used in the current workflow with OST post-merge gating system called Change-Queue.<br />

**Q.** Can I add my own tests to the gating system?<br />
**A.** The gating system is running OST tests, so if it’s a test that should be included in the OST, then yes.<br />

**Q.** What will happen to the old change-queue system now that we have gating?<br />
**A.** At this time, the change-queue system will stay and gate post-merge jobs until all of oVirt projects will be onboarded to patch gating.<br />
We might consider using the change-queue for further coverage of tests in the future.<br />

**Q.** How can I re-trigger a failed patch to the gate again?<br />
**A.** There are 2 options to retrigger:<br />
If the case is to fix your patch, just uploaded a new patchset and turn the Code-Review, Verified and CI labels again.<br />
If you want to re-trigger the same patchset again just write a comment in Gerrit:<br />
`ci gate please`

**Q.** I usually write a series of related patches that should be merged together, can the Gating system test all of them in a single test?<br />
**A.** No, they will be tested in parallel as the number of patches in the series. This is why we’ve increased our capacity to run OST for this case.

[1]: https://ovirt.softwarefactory-project.io/
[2]: https://zuul-ci.org/docs/zuul/user/gating.html
[3]: https://gerrit.ovirt.org/#/admin/projects/ovirt-zuul-config
[4]: zuul01.phx.ovirt.org
[5]: https://ovirt-jira.atlassian.net
[6]: https://ovirt-system-tests.readthedocs.io/en/latest/general/faq/index.html
[7]: https://ovirt-infra-docs.readthedocs.io/en/latest/CI/Build_and_test_standards/index.html
[8]: https://jenkins.ovirt.org/job/ovirt-system-tests_gate/