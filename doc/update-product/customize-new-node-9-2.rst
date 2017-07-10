.. _customize_new_node_9_2:

============================================================
Apply customizations to a new node in Mirantis OpenStack 9.2
============================================================

Once you update your Mirantis OpenStack environment to version 9.2, you may
need to further modify it, for example, by adding a new node. In this case,
you may want to apply the customizations of your existing environment (if any)
to this node. Be aware that when you add a new node to a Mirantis OpenStack
9.2 environment, it already contains the upgraded Ubuntu kernel version 4.4.

Before you proceed with applying customizations, redeploy your existing
Mirantis OpenStack 9.2 environment with a newly added node.

**To apply customizations to a new node:**

#. Log in to the Fuel Master node CLI.
#. Change the directory to ``mos_playbooks/mos_mu/``.
#. Apply the customizations of your existing environment to the new node

   .. code-block:: console

    ansible-playbook playbooks/mos9_apply_patches.yml -e '{"env_id":<ENV_ID>}' --limit <NODE_FQDN>

This task restarts the OpenStack services on the node to apply
customizations.


See also:  Limitations_

.. _Limitations: update-limitations-9-2.rst
