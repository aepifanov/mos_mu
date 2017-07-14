.. _usage_old:

Usage for MOS 6.x/7.0/8.0
=========================

Conditions and Limitations
--------------------------

- Should be run on Fuel Master under root
- Supports only MOS versions: 6.x, 7.0, 8.0 and 9.x.
- Supports only Ubuntu
- Doesn't start puppet which means that doesn't apply fixes which are in puppet manifests
- Doesn't change configuration files
- Needs separate restart for some non OpenStack services (RabbitMQ, MySQL, CEPH and etc)
- Patches should have absolute target path

Local repos mirrors
-------------------

If nodes don't have access to http://mirror.fuel-infra.org/ you can create and sync
local mirrors on Fuel if it has:

.. code-block:: console

 ansible-playbook playbooks/create_mirrors.yml -e '{"env_id":<env_id>}'

Then for the using them you to add **fuel_url** external variable:

.. code-block:: console

 ansible-playbook playbooks/apply_mu.yml -e '{"env_id":<env_id>,"fuel_url":"http://<FUEL_IP>:8080"}'

.. _`Step flags`: ../playbooks/vars/steps.yml


Preparations
------------

#. First of all we would recommend to gather current customizations:

   .. code-block:: console

    ansible-playbook playbooks/gather_customizations.yml -e '{"env_id":<env_id>}'

   `Step flags`_:

   * ``"health_check":false`` to skip the health checks task
   * ``"apt_update":true`` to repeat the generation of APT files
   * ``"gather_customizations":true`` to repeat gathering of customizations
   * ``"md5_check":true`` to repeat MD5 hash verification

   .. code-block:: console

    ansible-playbook playbooks/gather_customizations.yml -e '{"env_id":<env_id>,"gather_customizations":true}'

   The output contains:

   #. List of upgradable packages for each node:

      .. code-block:: console

       TASK [Show upgradable packages] ***********************
       ok: [node-5.domain.tld] => {
           "msg": [
               "Reading package lists...",
               "Building dependency tree...",
               "Reading state information...",
               "The following packages were automatically installed and are no longer required:",
               "  cloud-guest-utils eatmydata python-oauth python-serial python3-pycurl",
               "  python3-software-properties software-properties-common unattended-upgrades",
               "Use 'apt-get autoremove' to remove them.",
               "The following packages will be upgraded:",
               "  ceph ceph-common dh-python fuel-ha-utils fuel-misc hpsa-dkms i40e-dkms",
               "  libcephfs1 librados2 librbd1 libvirt-bin libvirt-clients libvirt-daemon",
               "  libvirt-daemon-system libvirt0 nailgun-agent nailgun-mcagents neutron-common",
               "  neutron-plugin-openvswitch-agent nova-common nova-compute nova-compute-qemu",
               "  puppet puppet-common python-cephfs python-cinderclient python-glanceclient",
               "  python-keystoneclient python-keystonemiddleware python-neutron",
               "  python-neutronclient python-nova python-novaclient python-oslo.concurrency",
               "  python-oslo.config python-oslo.context python-oslo.db python-oslo.log",
               "  python-oslo.messaging python-oslo.middleware python-oslo.reports",
               "  python-oslo.serialization python-oslo.service python-oslo.utils",
               "  python-oslo.versionedobjects python-pycadf python-rados python-rbd",
               "48 upgraded, 0 newly installed, 0 to remove and 0 not upgraded."
           ]
       }

   #. Current MU of each node:

      .. code-block:: console

        TASK [Show current MU] ******************************
        ok: [node-5.domain.tld] => {
            "msg": [
                "fuel"
            ]
        }

   #. MD5 verification of all packages on each node:

      .. code-block:: console

       [Show verification results] *************************
       ok: [node-1.domain.tld] => {
          "msg": [
                  "[REINSTALL] Unknown upgradable package 'dh-python' (1.20140128-1ubuntu8.2) will be reinstalled on the new available version.",
                  "neutron-common",
                  "nova-common"
          ]
       }

   Please read the whole output and make sure that everything looks good and nothing strange is there.


#. Then check that all customizations are applied on new versions:

   .. code-block:: console

    ansible-playbook playbooks/verify_patches.yml -e '{"env_id":<env_id>}'

   `Step flags`_:

   * ``"use_current_customization":false`` to skip handling gathered customizations from
     "customizaions" folder and use only patches that are already present in folder
     "patches"
   * ``"ignore_applied_patches": true`` to ignore if patches already contains in
     new package. Please go on one node and double checked that this pached already contains
     to avoid any issues.

   The output contains:

   #. The consistency verification of the OpenStack packages. The
      customization for same package should be the same on all nodes.
      For example, the ``python-nova`` package should have the same ``0``
      patch ID on every node:

      .. code-block:: console

       TASK [Show results of customizations consistency Verification] ******
       ok: [node-3.test.domain.local] => {
           "msg": [
               "Legenda:",
               " '-' - no patch (customization) for the package on this node",
               " 'x' - ID of patch",
               "",
               "nodes/packages  python-nova",
               "node-1          0",
               "node-2          0",
               "node-3          0"
           ]
       }

   #. The result of the customizations applied to the updated versions of
      the OpenStack packages:

      .. code-block:: console

       TASK [Show results of Patches Verification] *******
       ok: [node-1.domain.tld] => {
           "msg": [
               "",
               "-------- ./00-customizations/python-neutron_customization.patch",
               "patching file usr/lib/python2.7/dist-packages/neutron/__init__.py",
               "[OK]     python-neutron is customized successfully",
               "",
               "-------- ./00-customizations/python-nova_customization.patch",
               "patching file usr/lib/python2.7/dist-packages/nova/__init__.py",
               "[OK]     python-nova is customized successfully"
           ]
       }

   Sometimes playbooks can stop with failing and recommend to use
   some flags for the solving the situation, for example, when different patches
   are applied on different nodes.

   It is also strongly recommended to identify and copy original patches to
   **patches** folder on Fuel and disable **use_current_customization** flag and
   manage patches to successfully execute previous **verify_patches.yml** step.

   After that please go to the nodes **/root/mos_mu/verification/** and make sure
   that all patches are applied correctly.


Apply MU
--------

#. Update Fuel node (skip for MOS6.0):

   .. code-block:: console

    ansible-playbook playbooks/update_fuel.yml

#. Make a back up of MySQL:

   .. code-block:: console

    ansible-playbook playbooks/backup_mysql.yml -e '{"env_id":<env_id>}'

#. Apply MU:

   This playbook contains gathering and verifying steps which are already described
   above and then it upgrades all packages, applies patches and finaly restarts
   services.

   .. code-block:: console

    ansible-playbook playbooks/apply_mu.yml -e '{"env_id":<env_id>}'

#. Verify current version:

   .. code-block:: console

    ansible-playbook playbooks/get_version.yml -e '{"env_id":<env_id>}'

   The current MU should be the latest on all nodes.

   .. code-block:: console

     TASK [Show current MU] ********************************
     ok: [node-5.domain.tld] => {
         "msg": [
             "mu-8"
         ]
     }



Rollback
--------

Rollback (actually pseudo rollback) playbook can return your cluster on any
specified release and apply only gathered customizations on the current node:

.. code-block:: console

 ansible-playbook playbooks/rollback.yml -e '{"env_id":<env_id>,"rollback":"<release_name>"}'

