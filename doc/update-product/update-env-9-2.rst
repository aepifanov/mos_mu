.. _update-env-9-2:

=================================================
Update an existing Mirantis OpenStack environment
=================================================

.. caution:: Carefully read the whole :ref:`update-from-9-to-9-2` section
             to understand the update scenario.

             We strongly recommend contacting Mirantis Support if you plan
             to update your Mirantis OpenStack environment.

.. warning:: Please gracefully SHUT OFF all VMs on the environtment before
             the starting update.

If you have a running Mirantis OpenStack 9.0 or 9.1 environment, you can
safely update it to version 9.2.

During the update procedure, you create and assess the reports of your
environment customizations, if any. This helps you make a decision on
whether it is worth proceeding with the update since some customizations
can be lost during the update process. Be aware that the detection of
customizations in plugins is not supported.


**To update an existing Mirantis OpenStack environment to 9.2:**

#. Verify that you have updated the Fuel Master node as described in
   :ref:`update-master-9-2`.
#. Log in to the Fuel Master node CLI as root.
#. Change the directory to ``mos_playbooks/mos_mu/``.


#. Collect the Python OpenStack code customizations:

   .. note:: If your environment does not contain customizations, skip to
             step 9.

   .. code-block:: console

    ansible-playbook playbooks/gather_customizations.yml -e '{"env_id":<ENV_ID>}'

   .. caution:: If a Python OpenStack package was customized by adding a new
                file, such file will not be detected.

   You may use flags to manage this procedure. For example:

   * ``"health_check":false`` to skip the health checks task
   * ``"apt_update":true`` to repeat the generation of APT files
   * ``"gather_customizations":true`` to repeat gathering of customizations
   * ``"md5_check":true`` to repeat MD5 hash verification

   **Example:**

   .. code-block:: console

    ansible-playbook playbooks/gather_customizations.yml -e \
    '{"env_id":<ENV_ID>,"gather_customizations":true}'

   Sometimes, playbooks may fail, for example, when a customized package
   was installed not from the ``mos`` repository. Modifying specific flags
   may resolve the issue. But use the flags with caution.

   .. note:: If you have some other patches that should be applied to
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

#. Perform a preparation playbook for the environment. The playbook adds
   the update repository to each node of the environment, configures the
   ``/etc/apt/preferences.d/`` folder, updates and restarts MCollective,
   Corosync, Pacemaker and stop all VMs.

   .. code-block:: console

    ansible-playbook playbooks/mos9_prepare_env.yml -e '{"env_id":<ENV_ID>}'

#. (Optional) Run the environment configuration check using Noop run to simulate
   the changes and verify that the update does not override the important
   customizations of your environment.

   .. note:: If your environment does not contain customizations, skip to
             step 9.

   .. code-block:: console

    fuel2 env redeploy --noop <ENV_ID>

   It may take a while for the task to complete. When the task succeeds, its
   status changes from ``running`` to ``ready``.

   To verify the task status, run :command:`fuel2 task show <TASK_ID>`.
   The task ID is specified in the output of the configuration check command.

#. (Optional) Verify the summary of the configuration check task:

   .. code-block:: console

    fuel2 report <TASK_ID>

   The task ID is specified in the output of the :command:`fuel2 task list`
   command. The name of the task is ``dry_run_deployment``.

   The detailed Noop run reports are stored on each OpenStack node in the
   ``/var/lib/puppet/reports/node-FQDN/timestamp.yaml`` directory.

   .. warning:: Some configuration and architecture customizations of the
                environment can be lost during the update process.
                Therefore, use the customizations detection reports
                made by Noop run to make a decision on whether it is worth
                proceeding with the update.

#. Update the environment:

   .. code-block:: console

    fuel2 update --env <ENV_ID> install --repos mos9.2-updates

   To verify the update progress:

   * In the Fuel web UI, use the :guilabel:`Dashboard` tab.
   * In the Fuel CLI, run :command:`fuel2 task show <TASK_ID>`.

     The task ID is specified in the output of the
     :command:`fuel2 update install` command.

#. Upgrade the Ubuntu kernel to version 4.4:

   .. code-block:: console

    ansible-playbook playbooks/mos9_env_upgrade_kernel_4.4.yml -e '{"env_id":<ENV_ID>}'

   .. note:: To apply the upgrade of the Ubuntu kernel, an environment
             restart is required. See step 13.

#. Apply the customizations (if any) accumulated in
   ``/fuel_mos_mu/env_id/patches`` to your updated environment:

   .. code-block:: console

    ansible-playbook playbooks/mos9_apply_patches.yml -e '{"env_id":<ENV_ID>,"restart":false}'

#. Restart all nodes of your environment to apply the Ubuntu kernel upgrade
   as well as updates for non-OpenStack services (such as RabbitMQ, MySQL,
   Ceph). The restart order is as follows:

   #. The controller nodes restart.
   #. If present, Ceph monitors stop.
   #. The remaining nodes restart.
   #. The system is waiting until all Ceph OSDs are ``up``, if present.
   #. If present, Ceph monitors start.

   .. warning:: This step assumes a major downtime of the entire environment.

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

.. seealso:: :ref:`customize_new_node_9_2`
