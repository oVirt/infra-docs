CI Templates Server
===================


The CI templates server is a static web server which stores VM disk templates used by CI of several projects. The user-facing URL is https://templates.ovirt.org yet it is served by a CentOS 8 VM hosted in the PHX oVirt cluster - templates02.phx.ovirt.org

Images are spread accross four main directories:


| Path                       | Description                    | URL
| -------------------------- | ------------------------------ |--------------------------------------
| /var/www/html/repo         | used for storing lago images   | https://templates.ovirt.org/repo/
| /var/www/html/bundles      | contains the 'ovirt-demo-tool' | https://templates.ovirt.org/bundles/
| /var/www/html/yum          | mainly for ost-images          | https://templates.ovirt.org/yum/
| /var/www/html/kubevirt     | stores images for kubevirt ci  | https://templates.ovirt.org/kubevirt/


Please note that kubevirt directory should be accessible only from restricted number of allowed CI systems. These restrictions are enforced by a configuration file containing specific whitelisted subnets. The file is located at /etc/httpd/conf.d/templates.conf of templates02 VM.

At the time of writing this document there are no offical backups for the contents of these directories, however recovering from data loss/corruption is feasible in a timely manner.


Disks Layout
-------------

templates02.phx.ovirt.org VM has three disks that are separate from it and stored on storage02-data1

The Disks are:

- boot
- templates02-PV01
- templates02-PV02

The first disk stores the OS and some specific configuration. The two remaining disks form a volume group for storing the images.


Data Recovery
-------------

### Lago Templates

Most lago images are cached under /var/lib/lago/store/ across different nodes, but require some steps before it is possible to copy them back to the templates machine:

- Remove the 'phx_repo:' prefix and the ':v1' from suffix. Note that *.lock files are not needed. For instance, phx_repo:el8.2-base:v1.hash  -->  el8.2-base.hash

- Compress the image files only using the following command: ```xz --compress --keep --threads=0 --best --force --verbose --block-size=16777216 /path/to/image/file```

- Make sure the hashes match the compressed images. If not just create a new hash.

- Copy back the files to /var/www/html/repo. Note that for each image, three files have to be copied:

    - image_name.xz
    - image_name.hash
    - image_name.metadata


### OST Images

Regarding ost-images, due to recent efforts they can be recreated and published back to their relevant path. Make sure /var/www/html/yum holds sufficient permissions for the images owner to be able to reupload them.


### Kubevirt

Similar to Lago tempalates, images for kubevirt are cached under /var/lib/stdci/shared/kubevirt-images/
accross bare metal nodes used by KubeVirt. This path contains directories for different operating systems. Files under each sub-directory have to be renamed before they are copied back to the server.

Before renaming the files, verify the image names KubeVirt actually uses:

- [Windows](https://github.com/kubevirt/common-templates/blob/master/automation/test.sh#L138)
- [RHEL](https://github.com/kubevirt/common-templates/blob/master/automation/test.sh#L110)

For instance, the rhel8/ dir contains these files:

- disk.img
- disk.img.sha1

Make sure to rename them to:

- rhel8.qcow2
- rhel8.qcow2.sha1


Also make sure the hashes match the original files.
