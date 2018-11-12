How to add a new oVirt mirror
=============================
* Email the admin of the mirror site:

        Hi ADMIN NAME,
        We are really excited that you decided to contribute to the oVirt project.
        To add you as a mirror site I will need the following details:
        1) The IP address from which you will access our site.
        2) Your public ssh key.
        3) The email/organization which you want to be published in our wiki page.
        Thanks,
        YOUR NAME

* Once he replies, Email servicedesk_redhat_dot_com:

        Hi,
        Please allow access from <mirror ip> to resources.ovirt.org(66.187.230.28) port 22(SSH)

* Create a new patch with the public ssh-key in [infra-puppet][infra_puppet] repository,
see [this][ssh_key_patch] for reference.
* Once the patch is merged and the ip is whitelisted, ask the mirror
admin to test it by running the following command:

        rsync -rltHvvP mirror@resources.ovirt.org:/var/www/html his/mirror/path

* If everything goes well the new mirror rsync logs will appear at:
resources.ovirt.org:/var/log/mirrors

After a few days that everything is running well do the following:

* Create a new patch which updates the mirrorlist file, see [this][mirror_list_patch] for reference.
* Update the [repository mirrors page][web_repo] with the links/email/organization.
* Email oVirt community lead in order to update [the Downloads page][ovirt_download]

Mirror monitoring
=================

Once the mirror is included into the mirrorlist its content
needs to be monitored to ensure it serves the latest package versions.
This is done using a pod in [OpenShift][openshift] that periodically updates
timestamp files on resources.ovirt.org and verifies their age on mirrors.

The list of mirrors to verify is defined in the [ovirt-mirrorchecker] repo.
Submit a patch to this repository and merge it, then log in to [OpenShift][openshift]
and trigger a new build of the ovirt-mirrorchecker image:

    oc start-build ovirt-mirrorchecker -n ovirt-mirrorchecker

This will build a new container image and deploy it.
The new mirror should be present in the output of the mirror checker:

    https://web-ovirt-mirrorchecker.apps.ovirt.org/mirrors

Once this works, set up monitoring.ovirt.org to check the mirror along with the others.
The following nagios configuration file contains the mirror monitor:

    /etc/nagios/conf.d/hosts/web-ovirt-mirrorchecker.apps.phx.ovirt.org.cfg


If a mirror gets out of sync, report this in the infra list and CC the contact person
asking them to verify the reason and fix the sync issue.

In case the issue persists for more than a week and there is no fix, remove the mirror
from the mirrorlist to ensure users do not get outdated content (see previous section).

[ssh_key_patch]: https://gerrit.ovirt.org/51101/
[mirror_list_patch]: https://gerrit.ovirt.org/52384/
[infra_puppet]: https://gerrit.ovirt.org/#/admin/projects/infra-puppet
[web_repo]: https://www.ovirt.org/develop/infra/repository-mirrors/
[ovirt_download]: https://www.ovirt.org/download/
[ovirt-mirrorchecker]: https://gerrit.ovirt.org/#/admin/projects/ovirt-mirrorchecker
[openshift]: Phoenix_Lab/OpenShift
