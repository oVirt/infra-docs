OpenShift
=========

This chapter documents the OpenShift setup in Phoenix.

Instances
=========

Currently, two instances are deployed: Staging and Production.
Both have a matching configuration with 3 masters, 3 nodes
and a load balancer handling both API/UI and application traffic.

API endpoints
-------------

| Instance   | API endpoint                                                                         | First master                         | Note |
| ---------- | ------------------------------------------------------------------------------------ | ------------------------------------ | ---- |
| Production | [https://shift.ovirt.org:8443](https://shift.ovirt.org:8443)                         | shift-m01.phx.ovirt.org              | |
| Staging    | [https://staging-shift.phx.ovirt.org:8443](https://staging-shift.phx.ovirt.org:8443) | staging-shift-master01.phx.ovirt.org | API reachable via [OpenVPN](OpenVPN.markdown) only |

Remote access using oc
----------------------

External authentication is used, so to log in remotely using
the 'oc' console tool please first authenticate in the UI,
click on the username in the top right corner and select
"Copy Login Command" - this will generate an authentication
token and copy the complete login command into the clipboard.

Administrative console
======================

To perform administrative tasks on the cluster, such as upgrades
and permission modification, please log in as root to the first
master node indicated in the table above. All changes should be
tested on Staging first.

Adding a new user
=================

Authentication happens using Google Auth so anyone can log in.
For this reason, a new user cannot do anything and permissions
must be granted to create projects. To do that, first ask the
new user to log into the UI so that a user mapping is created.
Then list users to confirm the new user's email is visible:

    oc get users

Single project access
---------------------

To provide access to an existing project, run the following command:

    oadm policy add-role-to-user admin newuser@test.com -n NAME_OF_EXISTING_PROJECT

Project creation permission
---------------------------

To allow the new user to create projects, add the self-provisioner role:

    oadm policy add-cluster-role-to-user self-provisioner newuser@test.com

Cluster admin role
------------------

In rare cases when a user needs to have instance-wide admin access, add the cluster-admin role:

    oadm policy add-cluster-role-to-user cluster-admin newadmin@test.com

For more info, check out the official docs on [user](https://docs.openshift.com/container-platform/3.6/admin_guide/manage_users.html) and [role](https://docs.openshift.com/container-platform/3.6/admin_solutions/user_role_mgmt.html) management.

Managing persistent storage
===========================

Persistent volumes are used to save data across pod restarts and are provisioned manually.
To view existing volumes and their states, run:

    oc get pv

The "STATUS" column equals to "Bound" for volumes used by pods.

To add a new volume - create a new YAML listing the name, size and NFS path to use.
More info is provided in [official docs](https://docs.openshift.com/container-platform/3.6/install_config/persistent_storage/persistent_storage_nfs.html).

A sample persistent volume definition is presented below:

    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: new-pv-name
    spec:
      capacity:
        storage: 4Gi
      accessModes:
      - ReadWriteOnce
      nfs:
        path: /nfs/export/path
        server: NFS_SERVER_IP
      persistentVolumeReclaimPolicy: Recycle

Upgrading an instance
=====================

At the moment of this writing, the ansible hosts file and playbooks are stored on the first Master.
The playbooks are stored in /root/openshift-ansible and to update them run a "git pull" in this dir.

To perform maintenance tasks please follow the [official docs](https://docs.openshift.com/container-platform/3.6/install_config/install/advanced_install.html), testing them on Staging first.