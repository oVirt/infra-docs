Website Building
================

The website is built using Middleman 3 and the source in [this repository][1].
The development happens on GitHub directly and does not use Gerrit.

Documentation on the source layout and editorial policy is documented in the
README file at the root of the repository.

PRs are reviewed by oVirt developers and must pass the test build. This build
is run via Travis and a GitHub webhook.

The repository is regularly scrutinized for new merged commits by the web
builder, which is in charge of the final build. If the build is successful,
then it is published on the webserver. The published content is purely static
for performance and security reasons. The web builder is not accessible from
the outside world. The [latest build log][2] is available to help debug build
problems.

[1]: https://github.com/oVirt/ovirt-site
[2]: https://www.ovirt.org/build_log.txt

