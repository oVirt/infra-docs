oVirt Infra Docs
================

This repo contains documentation regarding the [oVirt][1] project infrastructure
and CI system.

This documentation can be read at its [permanent home on readthedocs][2] or
directly from [here][3] if you are using a source browser that supports
[markdown][4] display such as GitHub.

[1]: http://www.ovirt.org
[2]: http://ovirt-infra-docs.readthedocs.io
[3]: docs/index.markdown
[4]: http://daringfireball.net/projects/markdown

Contributing to this repo
-------------------------

This repo is primarily hosted on the [oVirt project Gerrit server][5]. Please
submit any changes to this repository there.

### Building the documentation

The documentation found in this repository can be built using the [mkdocs][6]
tool. The tool is packaged for many Linux distributions and can also be obtained
using "`pip`".

This repository also conforms to the [oVirt CI standards][7] and can therefore be
built using "`mock_runner.sh`" with the following command (Assuming the [oVirt
`jenkins` repo][8] is cloned to "`../jenkins`"):

    ../jenkins/mock_configs/mock_runner.sh -C ../jenkins/mock_configs -b el7

The generated documentation will be available from the "`exported-artifacts`"
directory.

[5]: https://gerrit.ovirt.org/#/admin/projects/infra-docs
[6]: http://www.mkdocs.org/
[7]: docs/CI/Build_and_test_standards.markdown
[8]: https://gerrit.ovirt.org/#/admin/projects/jenkins

### Running a local test server

[mkdocs][6] has a nice feature where it can run a local server that displays the
generated documentation and updates dynamically as local files change.

If you have it installed, the local server can be started by simply running:

    mkdocs serve

The documentation will then be available on [http://127.0.0.1:8000][9].

At the time of writing this document, the "serve" feature does not work with
the [mkdocs][6] version available on RHEL/CentOS 7. The included
"`requirements.txt`" file can be used to install a properly functioning version
inside a [Python virtualenv][10]. Alternatively, "`mock_runner.sh`" can be used
to launch the server in an isolated environment with the following command:

    ../jenkins/mock_configs/mock_runner.sh -C ../jenkins/mock_configs \
        -e automation/run_local_server.sh el7

[9]: http://127.0.0.1:8000
[10]: https://virtualenvwrapper.readthedocs.io/en/latest/
