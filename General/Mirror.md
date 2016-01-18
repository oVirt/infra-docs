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

* Once he replies, Email [servicedesk@redhat.com][service_desk]:

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
* Create a new patch which updates the mirrorlist file, see
[this][mirror_list_patch] for reference.
* Update [http://www.ovirt.org/Repository_mirrors][wiki_repo] with the links/email/organization.
* Email [mariel@redhat.com][community_email] in order to update [http://www.ovirt.org/Download][ovirt_download]

    [ssh_key_patch]: https://gerrit.ovirt.org/#/c/51101/
    [mirror_list_patch]: https://gerrit.ovirt.org/#/c/52384/
    [infra_puppet]: https://gerrit.ovirt.org/#/admin/projects/infra-puppet
    [wiki_repo]: http://www.ovirt.org/index.php?title=Repository_mirrors&action=edit&section=4s
    [ovirt_download]: http://www.ovirt.org/Download
    [community_email]: mariel@redhat.com
    [service_desk]: servicedesk@redhat.com
