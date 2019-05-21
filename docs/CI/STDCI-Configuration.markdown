STDCI Configuration
===================

The way projects interact with STDCI is through an STDCI configuration file.
It is a YAML file which specifies every aspect of the CI environment for the
project. The file resides in the project's root and has one of the following
names:

- _stdci.yaml_
- _automation.yaml_
- _seaci.yaml_
- _ovirtci.yaml_

The file name can be prefixed with a _._ (dot) to make it hidden and have the
_.yml_ suffix instead of _.yaml_.

STDCI provides a set of defaults that allows a project to specify only what is
important for it and keep the configuration clean and easy to read. We will
specify the default values and behaviours for every available configuration
throughout this doc.


## The basics

Let's start with an example of an STDCI configuration that reflects a typical
master branch of many projects that use STDCI:

    ---
    Architectures:
      - x86_64:
          Distributions: ["el7", "fc27"]
      - ppc64le:
          Distribution: el7
      - s390x:
          Distribution: fc27
    Release Branches:
      master: ovirt-master

Note: since the file is committed into the project’s own repo, having different
configuration for different branches can be done by simply having different
files in the different branches, so there is no need for a big convoluted file
to configure all branches.

Since the above file does not mention stages, any STDCI scripts that exists in
the project repo and belong to a particular stage will be run on all specified
distribution and architecture combinations. Since it is sometimes desired to run
‘check-patch.sh’ on less platforms then build-artifacts for example, a slightly
different file would be needed:

    ---
    Architectures:
      - x86_64:
          Distributions: ["el7", "fc27"]
      - ppc64le:
          Distribution: el7
      - s390x:
          Distribution: fc27
    Stages:
      - check-patch:
          Architecture: x86_64
          Distribution: el7
      - build-artifacts
    Release Branches:
      master: ovirt-master

The above file makes 'check-patch' run only on el7/x86_64, while build-artifacts
runs on all platforms specified and check-merged would not run at all because it
is not listed in the file.

Great efforts have been made to make the file format very flexible but intuitive
to use. Additionally there are many defaults in place to allow specifying
complex behaviours with very brief YAML code. We will cover all the possible
configuration and features of STDCI configuration.


### Defaults

Thanks to strong defaults, the most basic configuration file a project can
have is no configuration at all (or an empty configuration). In this case,
STDCI will search for a script that it's name matches to the current running
stage `(check-patch, check-merged, build-artifacts, ...)` and platform which
in the empty case is `el7.x86_64`.

For example, if the current stage is check-patch, STDCI will run the first
script it finds in the following order:

1. automation/check-patch.sh.el7.x86_64
2. automation/check-patch.sh.el7
3. automation/check-patch.sh

If no script was found, STDCI will not execute the stage.

Note that STDCI searches supplementary configuration files for the script such as
repos, packages and environment under the same directory with the script
and they should match the same naming as the script
(but with corresponding suffix). For example, if the current stage is
_check-patch_, the corresponding repos configuration file is the first one
found out of:

1. automation/check-patch.repos.el7.x86_64
2. automation/check-patch.repos.el7
3. automation/check-patch.repos

For more information about supplementary configuration files, please refer to
_"Declaring build and test dependencies"_ section under
[Build and test standards][1] doc.


### STDCI is case insensitive

All option-names (stage, sub-stage, distro and arch) are case-agnostic.
Hyphens (-) underscores (_) and spaces ( ) in their names are ignored.


### STDCI supports synonyms for options

STDCI supports multiple forms of the same word so you don’t need to remember if
the key should be ‘distro’, ‘distros’, ‘distributions’,
‘operating-systems’ or ‘OperatingSystems’ as all these forms works the have the
same meaning:

**Architectures**: arch, archs architecture, architectures

**Distribution**: distro, distros, distribution, distributions, os,
operating-system, operating-systems

**Stage:** stage, stages

**Sub stages:** substage, substages



## Explicitly specify path to a script

If you want to explicitly specify a script to execute, use the `script:`
option in the YAML file:

    ---
    script:
        from-file: my_dir/my_script.py

In this example, for every stage, STDCI will search for a script under the
specified path _my_dir/my_script.py_. If the script exists, it will be executed
for every STDCI stage. Note that since the script's path and name was changed,
the path and names of the supplementary configuration files should be changed
accordingly.

## Choose distribution and architecture

If not otherwise specified, STDCI will execute your script on a default
configuration: _CentOS 7_ running on an _x86_64_ machine. You can alter this
behaviour by explicitly specifying the distribution/architecture.

You can alter the default distribution/architecture using the YAML file:

    ---
    distro: fc27
    arch: ppc64le

In this example, since no script was specified nor a stage/substage, STDCI
will search for a matching script depending on the current stage. For example,
if the current stage is _check-merged_, STDCI will search and execute the first
match from the following:

1. _automation/check-merged.sh.fc27.ppc64le_
2. _automation/check-merged.sh.fc27_
2. _automation/check-merged.sh_

You can choose which script to execute on a particular architecture:

    ---
    distro:
      - fc27:
          script:
            from-file: scripts/fc27_script.sh
      - el7:
          script:
            from-file: scripts/el7_script.sh


### Build a matrix

In some cases, we want to specify a combination of distributions and
architectures:

    ---
    distro: [el6, el7]
    arch: [x86_64, ppc64le]

In this example, STDCI will compute a build matrix of the following platforms:
`(el6, x86_64), (el6, ppc64le), (el7, x86_64), (el7, ppc64le)`. For each
combination, since script was not specified, STDCI will search for the default.

Some may prefer to explicitly specify a script for a certain distro/arch:

    ---
    distro:
        - el6:
            script:
                fromfile: scripts/my_script.sh
        - el7
    arch: [x86_64, ppc64le]

In this example, all combinations that include `el6` will execute
_scripts/my_script.sh_ while build on `el7` will run the default script.
Both will run on _x86_64_ and _ppc64le_.

We can explicitly attach a distro to an architecture distro:

    ---
    arch:
        - x86_64:
            distro: [el6, el7]
        - ppc64le

In this example, since we haven't specified distro for _ppc64le_ architecture,
it will be running with the default _el7_, while _x86_64_ will be running with
_el6_ and _el7_.


### Indentation matters

In the YAML file, you can nest configurations under _stage_, _sub-stage_,
_distro_ and _arch_ options. It allows users to fine-tune their environment
exactly for their needs:

    ---
    distro:
      - el7:
          arch:
            - x86_64
            - ppc64le
      - fc26
      - fc27

In this example, since stage was not specified nor a script, STDCI will
search for the default scripts that matches the specified environments as
described in the first section of this doc. The given configuration specifies
that _el7_ scripts will run on _x86_64_ and _ppc64le_ machines and since
we haven't specified architecture for _fc26_ and _fc27_, they will be running
on the default _x86_64_ machines.

Configurations are being propogated from the outside inside. It means that
a top level configuration will apply for all lower level configurations unless
overridden. You can override a configuration by specifying it with a different
value:

    ---
    distro:
      - el7:
          arch: [x86_64 ,ppc64le]
      - fc26
      - fc27
    arch: [x86_64, ppc64le, ppc64le]

In this example, since architecture was configured at a top level, it will
apply on the _fc26_ and _fc27_ distributions, but it was overridden under
the _el7_ configuration.


## Run a script on a particular event with STDCI stages

STDCI stages represent the current status of a change in the project's
repository. They allow a user to execute a script that will verify/test/build
the project along with the new change.

1. *check-patch* runs when a patch was created/updated or a draft was published
   in Gerrit, or a Pull Request was sent in GitHub. It's used for quick
   verifications of the current change.
2. *check-merged* runs when a patch was submitted in Gerrit or a PR was merged
   in GitHub. It's used for verifications of the change with the current HEAD
   of the project.
3. *build-artifacts* is used to build the project. It runs in the following
   cases:
     - A patch was submitted in Gerrit or a PR was merged in GitHub.
     - A build was manually requested by a user by submitting a comment in the
       patch: _"ci build please"_.

For a detailed documentation of STDCI stages, please refer to
[Build and test standards][1].

As specified in the previous section, if a stage was not explicitly specified
in the YAML file, STDCI will execute stages that have a corresponding script to
execute. Some projects prefer to be more explicit about which stages are being
executed:

    ---
    stage:
        - check-patch
        - build-artifacts

In this example, STDCI will search for the matching script for the specified
stages. **Note** that since a stage was explicitly specified, the defaults
won't apply. In this example, _check-merged_ won't run **even if** there is a matching
script under _automation/check-merged.sh_.

If one prefers to alter the default script path for a stage:

    ---
    stage:
        - check-patch:
            script:
                from-file: check/verify_stuff.sh
        - build-artifacts:
            script:
                from-file: build/build_project.sh

In this example, STDCI will run _check/verify_stuff.sh_ for check-patch stage,
and _build/build_project.sh_ for build-artifacts stage.

We can run different stages on different architectures and distributions:

    ---
    stage:
        - check-patch:
            script:
                from-file: check/verify_stuff.sh
        - build-artifacts:
            script:
                from-file: build/build_project.sh
            distro: [el7, fc27, fc28]
            arch: [x86_64, ppc64le]

Since we haven't specified a distribution nor an architecture for _check-patch_,
it will run on the default combination: _CentOS 7_, _x86_64_. _build-artifacts_
on the other hand, will run on a combination of _(el7, x86_64)_,
_(el7, ppc64le)_, _(fc27, x86_64)_, _(fc27, ppc64le)_ _(fc28, x86_64)_,
_(fc28, ppc64le)_.


## Running more than one script per stage using sub-stages

In some cases, more than one script is needed in order to verify/test/build
the project. For such cases, STDCI provides **sub-stages**. With sub-stages,
we can specify several scripts that will run in *parallel* on *separated
hosts* for a single stage. Choose whatever name you like for a substage:

    ---
    stage: check-patch
    sub-stages:
        - verify_stuff
        - lint_stuff

In the example above, since we've explicitly specified a stage, it will be the
only stage that will run. The two sub-stages we've specified, will run in
parallel on different hosts when check-patch will be triggered. Notice that
in this example, no script was specified - STDCI will fallback to search for
the first matching script under the default `automation/` directory, but this
time, since we have specified _sub-stages_, the defaults are different.
For the **verify_stuff** sub-stage, STDCI will search for the first matching
script from the following:

1. _automation/check-patch.verify_stuff.sh.el7.x86_64_
2. _automation/check-patch.verify_stuff.sh.el7_64_
3. _automation/check-patch.verify_stuff.sh_

If we want to also have a 'default' sub-stage, that will search for a script
that doesn't contain the sub-stage name in it's name, we can explicitly
specify it in the YAML file:

    ---
    stage: check-patch
    sub-stages:
        - verify_stuff
        - lint_stuff
        - default

For the default sub-stage, STDCI will search for the first matching script
from the following:

1. _automation/check-patch.default.sh.el7.x86_64_
2. _automation/check-patch.default.sh.el7_64_
3. _automation/check-patch.default.sh_
4. _automation/check-patch.sh.el7.x86_64_
5. _automation/check-patch.sh.el7_64_
6. _automation/check-patch.sh_

To explicitly attach a script to a sub-stage, we just specify the `script`
option nested under the name of the sub-stage:

    ---
    stage: check-patch
    sub-stages:
        - verify_stuff:
            script:
                from-file: check-patch-scripts/verify_stuff.sh
        - lint_stuff:
            script:
                from-file: check-patch-scripts/lint_stuff.sh

We can specify different sub-stages for different stages by nesting the
sub-stages configurations under the name of the stage:

    ---
    stage:
        - check-patch:
            sub-stages:
                - verify_stuff:
                    script:
                        from-file: check-patch-scripts/verify_stuff.sh
                - lint_stuff:
                    script:
                        from-file: check-patch-scripts/lint_stuff.sh
        - build-artifacts:
            sub-stages:
                - build-docs
                - build-project

In this example, check-patch have two sub-stages configured (the same from
the previous example), and build-artifacts has two sub-stages as well:
one to build documentation, and one to build the project. Note that they both
fallback to the default location of script.

Sub-stages can run on different distributions and architectures:

    ---
    stage: check-patch
    sub-stages:
      - test:
          distro: [el7, fc27]
          arch: x86_64
      - lint
      - check-docs
    arch: [x86_64, ppc64le]

In this example, we have three sub-stages for check-patch. Since we have
configured _arch_ in a higher level configuration, the configuration propogates
to the indented configurations. _"lint"_ and _"check-docs"_ will run on:
_(el7, x86_64)_ and _(el7, ppc64le)_. Since _"test"_ overrides this
configuration, it runs on a different combination: _"(el7, x86_64)"_ and
_"(fc27, x86_64)"_.


## Runtime requirements

By default, STDCI runs your build on one of the available hosts we have. This
host can be a virtual machine or a bare-metal host. If one of your builds
requires a bare-metal host (if you need virtualization capabilities for
example), you can specify your requirements in the YAML file:

    ---
    stage:
      - check-patch:
          runtime-requirements:
            support_nesting_level: 2
      - build-artifacts

In this example, we require a machine that supported a nesting level of 2 which
is a bare metal.

- support_nesting_level: 2 -> bare-metal.
- support_nesting_level: 1 -> virtual-machine.
- support_nesting_level: 0 (or unspecified) -> first available host.


## Conditional execution

In some cases, we'd prefer to run a script only if some file(s) were modified.
STDCI provides a conditional execution mechanism to allow such behavior:

    ---
    stage: check-patch
    sub-stages:
      - pylint:
          run-if:
            file-changed: '*.py'
      - check-docs:
          run-if:
            file-changed: 'docs/*'

In this example, we have configued two substages for a single _check-patch_ stage.
_"pylint"_ sub-stage will run 'automation/check-patch.pylint.sh' only if the
commit includes a file that matches the '*.py' pattern. _"check-docs"_ will run
'automation/check-patch.check-docs.sh' if the commit includes a change to a
file under the _docs/_ dir.

**Note** that the conditions support Unix-Shell style wildcard expantion.

We can also specify several patterns in the same condition:

    ---
    run-if:
      file-changed: ['pattern-1', 'pattern-2', ...]

In this case, it's enough for one of the patterns to match the modified files
to run the conditions.


## Use Jinja2 templates for enhanced functionality

STDCI allows the use of Jinja2 templates to avoid repetitive typing. For that
purpose, STDCI exposes [Jinja2 variables][6] to be used in the YAML file. The
available variables are: **{{ stage }}**, **{{ substage }}**, **{{ distro }}** and
**{{ arch }}**. Depanding on where they are used in the file, they will
evaluate to the corresponding _stage_, _substage_, _distro_ and _arch_.
The expantion applies to all specified paths in the YAML file:

    ---
    stage:
      - check-patch:
          sub-stage:
            - lint
            - check
    script:
      from-file: 'CI_scripts/{{ stage }}/{{ substage }}.sh'

In this example, we have one stage: _check-patch_ which have two sub-stages
configured: _"lint"_ and _"check"_. Since _script_ was configured as a higher
level option, it applies to both of the sub-stages. The scripts that will be
used for each sub-stage are under the following paths:

1. CI_scripts/check-patch/lint.sh
2. CI_scripts/check-patch/check.sh

Each script will be running on the corresponding sub-stage.


## Projects that already use STDCI cfg

The following projects are using STDCI configuration. You can use them as a
reference for your project.

|    Project name    |        Git repo      |    STDCI config web view    |
|:------------------:|:--------------------:|:---------------------------:|
| ovirt-system-tests | [gerrit repo][2]     | [STD CI config web view][3] |
| Jenkins            | [gerrit repo][4]     | [STD CI config web view][5] |

[1]: Build_and_test_standards.markdown
[2]: https://gerrit.ovirt.org/#/admin/projects/ovirt-system-tests
[3]: https://github.com/oVirt/ovirt-system-tests/blob/master/stdci.yaml
[4]: https://gerrit.ovirt.org/#/admin/projects/jenkins
[5]: https://github.com/oVirt/jenkins/blob/master/stdci.yaml
[6]: http://jinja.pocoo.org/docs/2.10/templates/#variables
