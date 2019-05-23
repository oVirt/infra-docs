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

    oc adm policy add-role-to-user admin newuser@test.com -n NAME_OF_EXISTING_PROJECT

Project creation permission
---------------------------

To allow the new user to create projects, add the self-provisioner role:

    oc adm policy add-cluster-role-to-user self-provisioner newuser@test.com

Cluster admin role
------------------

In rare cases when a user needs to have instance-wide admin access, add the cluster-admin role:

    oc adm policy add-cluster-role-to-user cluster-admin newadmin@test.com

For more info, check out the official docs on [user](https://docs.openshift.com/container-platform/3.9/admin_guide/manage_users.html) and [role](https://docs.openshift.com/container-platform/3.9/admin_guide/manage_rbac.html#managing-role-bindings) management.

Managing persistent storage
===========================

Persistent volumes are used to save data across pod restarts and are provisioned manually.
To view existing volumes and their states, run:

    oc get pv

The "STATUS" column equals to "Bound" for volumes used by pods.

To add a new volume - create a new YAML listing the name, size and NFS path to use.
More info is provided in [official docs](https://docs.openshift.com/container-platform/3.9/install_config/persistent_storage/persistent_storage_nfs.html).

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

The ansible hosts file and playbooks are stored on the first Master.
Playbooks are stored in /root/openshift-ansible and to update them run a "git pull" in this dir.

To perform maintenance tasks please follow the [official docs](https://docs.openshift.com/container-platform/3.9/install_config/install/advanced_install.html), testing them on Staging first.

Adding a node
=============

To add a new node to the cluster, please check that the following preparations are made:

* CentOS 7 installed and up-to-date
* docker installed, overlay2 storage configured (default on CentOS7)
* NetworkManager installed and enabled
* firewalld installed and enabled
* SELinux set to Enforcing mode
* the first master's SSH pubkey is installed on the node
* if the node is external, ensure it can connect back to the following services in PHX:
   * apiserver endpoint: https://shift-int.phx.ovirt.org:8443
   * SDN on infra nodes: VxLAN (UDP/4789) open for PHX public subnet 66.187.230.0/25
   * if the node is used for kubevirt, ensure it has access to templates.ovirt.org/kubevirt

Connect to the first master and update the Ansible hosts file /etc/ansible/hosts
Add the node that needs to be added into the [new_nodes] section.

Now run the node scale-up playbook:

    ansible-playbook /root/openshift-ansible/playbooks/openshift-node/scaleup.yml

Ensure the playbook completes without errors. Verify the node is added to the cluster:

    oc get nodes

If the node is present in the list and its status is "Ready", the process is complete.

SSL
===

SSL is managed using [openshift-acme](https://github.com/tnozicka/openshift-acme) which is an automated ACME controller.

Enabling opensift-acme on a route
---------------------------------

The controller will only act on routes that have it explicitly enabled
to avoid abuse and certificate requests for non-existing domains.
The following annotation needs to be added to a route definition:

    metadata:
      annotations:
        kubernetes.io/tls-acme: "true"

Alternatively, patch the route using the CLI:

    oc patch route ROUTE_NAME -p '{"metadata":{"annotations":{"kubernetes.io/tls-acme":"true"}}}'

This will instruct the controller to generate a new certificate and install it on the route.
Upon expiration the controller will renew the certificate automatically.

Deploying openshift-acme
------------------------

Standard upstream instructions can be used to deploy openshift-acme after a reinstall:

    oc new-project acme
    oc create -fhttps://raw.githubusercontent.com/tnozicka/openshift-acme/master/deploy/letsencrypt-live/cluster-wide/{clusterrole,serviceaccount,imagestream,deployment}.yaml -n acme
    oc adm policy add-cluster-role-to-user openshift-acme -z openshift-acme -n acme

The last step provides the service account required access permissions to read routes and change
them by adding generated certificates.

Troubleshooting certificate renewal
-----------------------------------

The controller runs as a pod in the "acme" namespace. In case of issues ensure
that the pod is running and review its logs for further information.