Standard-CI container-based backend
===================================

The Standard-CI container-based backend is an extension to the CI [Build and
Test Standards][1], that allows having CI workloads run natively as containers
using user-specified container images.

This backend is provided as an alternative to the legacy VM-and-chroot-based
backend, that had been used so far in the STDCI implementation.

The container-based backend uses a somewhat different configuration syntax than
the legacy backend, and provides a somewhat different set of features.

[1]: Build_and_test_standards.markdown

Using the container-based backend
---------------------------------

The container-based backend is enabled by including the `container` options in
the [STDCI YAML configuration file][2]. Following is an example for how to do
so:

    sub-stages:
      - centos7-container:
          container:
            - image: docker.io/centos:7
              args: ['echo', 'Hollow world from container!']

As is typical for standard-CI YAML options, the option can be provided at the
level of a *stage*, a *substage*, a *distro*, an *arch*, or a combination
thereof. It can also be specified at a higher level of the file and be
inherited by lower levels. The plural form `containers` can also be used for the
option name.

The contents of the `container` option is a list of container entries that can
contain the fields specified below.

**Note:** Currently only one container entry may be specified in the list. If more
than one entry is specified, only the last entry would be used. Future
extensions may make use of the other entries.

As a convenience for the case where there is only one entry in the container
list, the `container` option may also contain the container entry structure
directly, without having it be wrapped by a list.

The following fields may be included in a container entry:

Field      | Optional  | Default value     | Meaning
---------- | --------- | ----------------- | ------------------------------
image      | no        | N/A               | The container image to run
args       | yes       | CI script name    | Arguments to pass to the image
command    | yes       | Image entrypoint  | Override the image entry point
workingdir | yes       | /workspace        | Set the working directory

Please note, that the container fields are roughly equivalent to similar fields
specified for a container configuration in Kubernetes.

When specifying the `container` option, the STDCI system will launch the
specified container providing the specified arguments, wait for it to finish and
report whether it succeeded or failed.

**Note:** CI threads that use containers, may be defined in the same configuration
file, alongside threads that used the legacy runtime.

The following sections describe in more detail how the containers behave, and
the relationships between the different configuration options.

[2]: STDCI-Configuration.markdown

Scripts, arguments and entry points
-----------------------------------
Typically, when running a container in a container runtime such as Docker or
Kubernetes, the runtime allows passing arguments to the container, which are
then passed as arguments to its entry point. Passing those arguments is done via
the `args` option.

Is some cases, it may be desirable to override the entry point defined in the
container image. This is done via the `command` option.

If the `args` option is not given, the name of the script associated with the CI
thread being run will be passed instead.

**Note:** There is no guarantee that the script itself would be available for use
by the container (See discussion about source code below).

While the CI script associated with the CI thread being run, may not be used by
the running container at all (As is the case in the example above), it is still
required that the script file will exist. If the file does not exist then:

1. If the file is explicitly defined via the `script` option in the YAML, the
   system will raise an error
2. If `script` option is not explicitly defined, the whole CI thread will be
   skipped, and no container would be launched

Source code
-----------
The system does not currently include any built-in mechanisms to make the
project source code available to the container. It is up to container image
authors and users to make the image obtain the right source code.

To assist with doing this, the CI system provides several environment variables
to the container pointing at where the source code can be obtained from (See
below).

Working directory and `/workspace`
----------------------------------
When the container is launched a temporary volume is mounted at `/workspace`.
The directory is intended to be used as the main workspace for the container,
and future services may use it as a place to exchange information.

By default, the `/workspace` directory is set as the working directory for the
container. This may be changed using the `workingdir` option.

Distribution and Architecture
-----------------------------
In the context of Standard-CI, the target distribution and architecture for a
given CI thread are always defined - either explicitly, or implicitly via
default values.

Those definitions, while being provided as environment variables (see below),
are otherwise ignored by the container backend. Containers are being launched on
*x86_64* machines, and the distribution available is whatever is provided by the
container image.

Future extensions may make the containers run on the appropriate architectures,
and provide automated image selection according to the target distribution.

Environment variables
---------------------
To enable the containers to interact with the rest of the CI system, and with
the project being built and tested, the following environment variables are
provided:

Variable            | Meaning
------------------- | ---------------------------------------------------------
STD_CI_STAGE        | The CI stage the container was launched for
STD_CI_SUBSTAGE     | The CI sub-stage the container was launched for
STD_CI_DISTRO       | The CI target distribution the container was launched for
STD_CI_ARCH         | The CI target architecture the container was launched for
STD_CI_CLONE_URL    | The Git repo URL project code can be cloned from
STD_CI_REFSPEC      | The Git refspec of the source being built or tested
STD_CI_PROJECT      | The name of the project being built or tested
STD_CI_GIT_SHA      | The Git SHA of the source being tested
GIT_COMMITTER_NAME  | The CI system's user name for placing in auto generated Git commits
GIT_COMMITTER_EMAIL | The CI system's email address for placing in auto generated Git commits
BUILD_NUMBER        | The build number from Jenkins
BUILD_ID            | The build ID from Jenkins
BUILD_DISPLAY_NAME  | The display name for the build in Jenkins
BUILD_TAG           | A unique string identifying the build
BUILD_URL           | A URL for the running build in Jenkins
JOB_NAME            | The full name of the running job in Jenkins
JOB_BASE_NAME       | The short name of the running job in Jenkins
JOB_URL             | The URL for the running job in Jenkins
JENKINS_URL         | The URL for the Jenkins master the job is running on

Limitations
-----------
When compared to the legacy Standard-CI backed, the container-based backend has
several limitations, some of which may be mitigated via future extensions:

1. Only the x86_64 architecture is currently supported
2. The CI target distribution configuration is ignored
3. The CI script must exist even if unused
4. The project source code is not provided by the CI framework
5. Only one container may be invoked for a given CI thread
6. The CI system only reports success/failure status, there is no way to yield
   other build artifacts. The STDOUT and STDERR streams of the container will be
   shown, however, in the Job output in Jenkins

Tricks aliases, and shorthands
------------------------------
There are several syntactic alternatives supported, that are meant to allow
writing shorter and nicer YAML.

1. As mentioned above, when using a single container, the container entry
   structure can be placed directly under the `container` option, without being
   a list member.
2. A string can be specified instead of a full container entry. In that case, it
   is taken as the name of the image to use, and the other options are set to
   their default values.

    Along with the single container syntax mentioned above, this allows writing
    very succinct configuration:

        substages:
        - run-container:
           container: docker.io/my-container/image

3. The `args` option supports the `arguments` and `argument` aliases.
4. The `command` options supports the `entrypoint` alias.
5. The `workingdir` options supports the `workdir` and `workingdirectory`
   aliases.
6. The `command` and `args` options may be given as lists of strings or singular
   strings, that are then implicitly converted to lists with a single string
   member.
7. The usual STDCI configuration file rules - for ignoring case, whitespace,
   dashes and underscores - apply. Together with some of the features mentioned
   above, this allows for a "literary" configuration style, like so:

        Container:
          Image: centos/7
          Entry Point:
            - /bin/bash
            - -exc
          Argument: |
            git init .
            git fetch "$STD_CI_CLONE_URL" +"$STD_CI_REFSPEC":myhead
            git checkout myhead
            my_test_script.sh
