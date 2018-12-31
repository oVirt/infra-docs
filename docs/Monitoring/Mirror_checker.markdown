oVirt Yum Mirrors Liveness Monitoring
=======================================
oVirt site has multiple mirror sites hosting the official
oVirt releases, hosted on [oVirt Releases][resources].

A list of the current mirrors can be found [here][ovirt_mirrors]

In order to verify each of these mirrors are updated,
the oVirt Infra team brought up a service called
'Mirror Checker', which runs on a container inside
OpenShift.

More info on the tool can be found on it dedicated
documentation page on [mirror_checker docs page][mirror_rtd]

[resources]: http://resources.ovirt.org/pub
[mirror_rtd]: https://mirrorchecker.readthedocs.io/en/latest/
[ovirt_mirrors]: https://www.ovirt.org/develop/infra/repository-mirrors.html
