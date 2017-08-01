.. _update-env-9-2:

**Caution**

    Carefully read the whole `update to 9.2`_ section
    to understand the update scenario.

    We strongly recommend contacting Mirantis Support if you plan
    to update your Mirantis OpenStack environment.

**Warning**

    Please gracefully SHUT OFF all VMs on the environtment before
    the starting update.


=================================================
Update an existing Mirantis OpenStack environment
=================================================

If you have a running Mirantis OpenStack 9.0 or 9.1 environment, you can
safely update it to version 9.2.

During the update procedure, you create and assess the reports of your
environment customizations, if any. This helps you make a decision on
whether it is worth proceeding with the update since some customizations
can be lost during the update process. Be aware that the detection of
customizations in plugins is not supported.


**To update an existing Mirantis OpenStack environment to 9.2:**

#. Verify that you have updated the Fuel Master node as described in
   `Update Master Node`_
#. Log in to the Fuel Master node CLI as root.
#. Change the directory to ``mos_playbooks/mos_mu/``.


#. Collect the Python OpenStack code customizations:

   **Note**

        If your environment does not contain customizations, skip to
        step 9.

   .. code-block:: console

    ansible-playbook playbooks/gather_customizations.yml -e '{"env_id":<ENV_ID>}'

   **Caution**

        If a Python OpenStack package was customized by adding a new
        file, such file will not be detected.

   You may use flags to manage this procedure. For example:

   * ``"health_check":false`` to skip the health checks task
   * ``"apt_update":true`` to repeat the generation of APT files
   * ``"gather_customizations":true`` to repeat gathering of customizations
   * ``"md5_check":true`` to repeat MD5 hash verification

   **Example:**

   .. code-block:: console

    ansible-playbook playbooks/gather_customizations.yml -e '{"env_id":<ENV_ID>,"gather_customizations":true}'

   Sometimes, playbooks may fail, for example, when a customized package
   was installed not from the ``mos`` repository. Modifying specific flags
   may resolve the issue. But use the flags with caution.

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

   **Note**

        If you have some other patches that should be applied to
        this environment, you can manually add these customizations
        to the ``/fuel_mos_mu/env_id/patches/`` folder
        on the Fuel Master node. Add the ID prefix to every
        patch name, such as ``0x-patch_name``, ``0y-patch_name``,
        starting from the ``01-`` prefix.

        After the update, you can use this folder to apply new
        customizations.

#. Verify that the customizations in the OpenStack packages are the same
   on all nodes. Also, verify that the customizations are applied correctly
   to new versions of packages. Use the following command:

   .. code-block:: console

    ansible-playbook playbooks/verify_patches.yml -e '{"env_id":<ENV_ID>}'

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

#. Make a back up of MySQL:

   .. code-block:: console

    ansible-playbook playbooks/backup_mysql.yml -e '{"env_id":<ENV_ID>}'

#. Perform a preparation playbook for the environment. The playbook adds
   the update repository to each node of the environment, configures the
   ``/etc/apt/preferences.d/`` folder, updates and restarts MCollective,
   Corosync, Pacemaker.

   .. code-block:: console

    ansible-playbook playbooks/mos9_prepare_env.yml -e '{"env_id":<ENV_ID>}'

   **Warning**

        Please make sure that all VMs are in SHUTOFF state to avoid any data lost.

#. Update the environment:

   .. code-block:: console

    fuel2 update --env <ENV_ID> install --repos mos9.2-updates

   To verify the update progress in the Fuel web UI, use the Dashboard tab:

   .. figure:: upgrade_dashboard.png
       :align: center
       :alt:

#. (Should be skipped for MOS9.2) Upgrade the Ubuntu kernel to version 4.4:

   .. code-block:: console

    ansible-playbook playbooks/mos9_env_upgrade_kernel_4.4.yml -e '{"env_id":<ENV_ID>}'

#. Apply the customizations (if any) accumulated in
   ``/fuel_mos_mu/env_id/patches`` to your updated environment:

   .. code-block:: console

    ansible-playbook playbooks/mos9_apply_patches.yml -e '{"env_id":<ENV_ID>,"restart":false}'

   **Warning**

        For MOS9.2 flag restart should be removed from command or changed on ``true``

#. (Should be skipped for MOS9.2) Restart all nodes of your environment to apply
   the Ubuntu kernel upgrade as well as updates for non-OpenStack services (such
   as RabbitMQ, MySQL, Ceph). The restart order is as follows:

   #. The controller nodes restart.
   #. If present, Ceph monitors stop.
   #. The remaining nodes restart.
   #. The system is waiting until all Ceph OSDs are ``up``, if present.
   #. If present, Ceph monitors start.

   **Warning**

        This step assumes a major downtime of the entire environment.

   Run the following command:

   .. code-block:: console

    ansible-playbook playbooks/restart_env.yml -e '{"env_id":<ENV_ID>}'

#. Verify that your environment is successfully updated to version 9.2:

   .. code-block:: console

    ansible-playbook playbooks/get_version.yml -e '{"env_id":<ENV_ID>}'

   **Example of the system response fragment:**

   .. code-block:: console

    TASK [Show current MU] ************
    ok: [node-1.test.domain.local] => {
        "msg": [
            "9.2"
        ]
    }

#. On *every* Mirantis OpenStack node, verify that the Ubuntu kernel is
   successfully upgraded to version 4.4:

   .. code-block:: console

    uname -r

See also: `Apply customizations to a new node in Mirantis OpenStack 9.2`_

.. _`update to 9.2`: ../update-product.rst
.. _`Update Master Node`: update-master-9-2.rst
.. _Apply customizations to a new node in Mirantis OpenStack 9.2: customize-new-node-9-2.rst
