Using mock_runner to run Standard-CI stages
===========================================

`mock_runner.sh` is a Linux command line tool for running [standard build and
test stages][1]. The main benefit of using `mock_runner.sh` is being able to
build and test compatible projects without needing to know what build tools or
dependencies that project may need.

`mock_runner.sh` uses [mock][2] to generate isolated build and test environments
and emulate specific Linux distributions. This means that one can use
`mock_runner.sh` to run builds or tests targeting a different distribution then
one may be running. For example you can use `mock_runner.sh` to build 'CentOS 7'
packages on a Fedora laptop.

[1]: Build_and_test_standards.markdown
[2]: https://github.com/rpm-software-management/mock/wiki

Setting up mock_runner
----------------------

To use `mock_runner.sh`, one needs to first install and configure *mock* and
then obtain `mock_runner.sh` itself and the distribution configuration files
for it.

### How to install 'mock'

Mock can be installed on any Red Hat family distorbution including Fedora, RHEL
and CentOS.

First you'll need to install the 'mock' package if its not installed:

    sudo yum install -y mock

Add your user name to the 'mock' group in order to run it:

    usermod -a -G mock $username

Apply changes by re-logging in with your user:

    su - $username

Verify you're now part of the mock group:

    groups

For more info, check the [mock project page][2].

### Installing mock_runner

`mock_runner.sh` itself does not require much of an installation procedure. To
obtain it you can simply clone the [`jenkins` repository][3]. It will be
located in it under the `mock_configs` directory along with all the
configuration files it requires.

[3]: https://gerrit.ovirt.org/#/admin/projects/jenkins

Using mock_runner
-----------------

### Basic usage

`mock_runner.sh` needs to find the chroot configuration files from then
`mock_configs` directory in the [jenkins repo][3]. To let it do that simply pass
the full path to the `mock_configs` directory on your machine to the
`--mock-configs-dir` or `-C` option when invoking `mock_runner.sh`.

To run a standard build or test stage you need be in the root directory of your
project source tree (Where the `automation` directory is located) and specify
the stage and the distribution to run it on.

For example, to run the *check-patch* stage on CentOS 7:

    cd /path/to/your_project
    /path/to/jenkins/mock_configs/mock_runner.sh \
        -C /path/to/jenkins/mock_configs -p el7

Please be careful about specifying all the required parameters.
`mock_runner.sh` has some deprecated behaviour where it can run all stages on
all platform sequentially, and it will fall back to that behaviour if not all
parameters are specified.

Here are the options that can be used to make `mock_runner` run the various
standard stages:

Standard stage name | Long option        | Short option
--------------------|--------------------|-------------
build-artifacts     | `--build-only`   | `-b`
check-patch         | `--patch-only`   | `-p`
check-merged        | `--merged-only`  | `-m`

You can also use the `--execute-script` or `-e` to execute a custom script
as if it was a standard stage script (Including full support for its own
packages, repos, etc. files). For example, to emulate the
'*poll-upstream-sources*' stage you can run:

    /path/to/jenkins/mock_configs/mock_runner.sh \
        -C /path/to/jenkins/mock_configs -e poll-upstream-sources.sh el7

The distribution you can specify can be one of:

Distribution   | Name on the mock_runner command line
---------------|-------------------------------------
CentOS 6       | el6
CentOS 7       | el7
Fedora 23      | fc23
Fedora 24      | fc24
Fedora 25      | fc25
Fedora 26      | fc26
Fedora 27      | fc27
Fedora rawhide | fcraw

The CI team adds more supported distributions are they are released.

### Obtaining shell access

`mock_runner.sh` has a useful feature where it can provide shell access into
the build or test environment it creates. This can be very useful to debug
issues in stage scripts or if one needs to quickly access a clean version of
CentOS or Fedora.

To access a shell for the environment that would be created for the
*check-patch* stage when targeting Fedora 26 for example, use the following
command:

    /path/to/jenkins/mock_configs/mock_runner.sh \
        -C /path/to/jenkins/mock_configs -p --shell fc26

Please note that `--shell` must be the last option specified before the
distribution name. Syntactically speaking, the distribution name is actually an
option given to the `--shell` flag.

One inside the shell you can use the `cd` command (without arguments) to get
to where the source code is available inside the test environment. The source
will be accessible in a path identical to the one where it is on your local
machine.


### Note about environment requirements


#### Secrets/credentials

If your project requires secrets as environment variables you will need to
create a local **secrets file**.
See [Writing STDCI secrets file documentation](Writing_STDCI_secrets_file.markdown)

**How to tell that my project requires secrets as environment variables?**

Open the corresponding `automation/${standard_stage_name}.environment.yaml`
for the stage you want to execute locally via mock_runner. You will see a
variable that requires it's value from secret key reference:

    valueFrom: secretKeyRef

**Possible exceptions**

    RuntimeError: Could not find matching secret for <secret_name>

May raise from two reasons:

1. Missing *ci_secrets_file.yaml*. Make sure you write a local secrets file.
2. A secret that was requested in
   *automation/${standard_stage_name}.environment.yaml* is missing from
   *ci_secret_file.yaml*. Make sure you added the requested variable to your
   local secrets file.

#### Runtime environment

If your project requires variables from the runtime environment which in this
case is the environment from the **shell** that you will run mock_runner from,
you will need to export the required variable and it's value.

    export REQUIRED_VAR_NAME=VALUE

**How to tell that my project requires variable from runtime environment?**

Open the corresponding `automation/${standard_stage_name}.environment.yaml`
for the stage you want to execute locally via mock_runner. You will see a
variable that requires it's value from runtimeEnv:

    valueFrom: runtimeEnv

**Possible exceptions**

    RuntimeError: [DBM_RESOLVER] No such key <requested_variable> in env runtime.

1. A variable that was requested in
   *automation/${standard_stage_name}.environment.yaml is missing from the
   environment. Make sure you export the correct variable name.

Full environment.yaml specifications are under
[Build and tests standards doc](Build_and_test_standards.markdown)
