.. _update-master-9-2:

**Caution**

    Carefully read the whole `update to 9.2`_ section
    to understand the update scenario.

    We strongly recommend contacting Mirantis Support if you plan
    to update your Mirantis OpenStack environment.

===========================
Update the Fuel Master node
===========================

Before creating a new environment, update the Fuel Master node from
version 9.0 or 9.1 to 9.2 using the procedure below.

If you already have a Mirantis OpenStack 9.0 or 9.1 environment, before
updating the Fuel Master node, take a note that all the environment
customizations will be lost during the update to version 9.2. Therefore,
use the customizations detection reports created before an environment
update to make a decision on whether it is worth proceeding with the update.
For details, see `Update Environment`_.

**To update the Fuel Master node:**

#. Verify that you have completed the tasks described in
   Prerequisites_.

#. Log in to the Fuel Master node CLI as root.

#. Change the directory to ``mos_playbooks/mos_mu/``.

#. Perform a preparation playbook for the Fuel Master node. The playbook
   installs and prepares necessary tools for the update. Also, it restarts
   the ``astute`` and ``nailgun`` services.

   .. code-block:: console

    ansible-playbook playbooks/mos9_prepare_fuel.yml

#. Update the Fuel Master node packages, services, and configuration:

   .. code-block:: console

    ansible-playbook playbooks/update_fuel.yml -e '{"rebuild_bootstrap":false}'

   **Warning**

        During the update procedure, the Fuel Master node
        services will be restarted automatically.

#. (Should be skipped for MOS9.2) Upgrade the Ubuntu kernel to version 4.4 for the Fuel bootstrap:

   .. code-block:: console

    ansible-playbook playbooks/mos9_fuel_upgrade_kernel_4.4.yml

#. Verify that the Fuel Master node is successfully updated to version 9.2:

   * In the Fuel web UI, verify the version number in the bottom left corner
     of the page.
   * In the Fuel CLI, run ``fuel2 fuel-version``. The output of the
     command should be as follows:

     .. code-block:: console

      # fuel2 fuel-version
        openstack_version: mitaka-9.0
        release: '9.2'

After completing these steps, proceed to `Update Environment`_ if you have
a Mirantis OpenStack environment 9.0 or 9.1.


.. _`update to 9.2`: ../update-product.rst
.. _`Update Environment`: update-env-9-2.rst
.. _Prerequisites: update-prerequisites-9-2.rst
