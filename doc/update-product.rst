.. _update-from-9-to-9-2:

==============================
Update to minor releases (9.x)
==============================

Mirantis OpenStack 9.2 is distributed as an update repository. With the help
of Mirantis Support, you can safely update your Mirantis OpenStack 9.0 or 9.1
to 9.2 using the procedure described in this section.

During the Mirantis OpenStack update, the OpenStack services are updated
as well as RabbitMQ and MySQL. An important part of the update procedure
is the Linux kernel upgrade to version 4.4. This procedure also contains
the update of Ceph from version 0.94.6 to 0.94.9. The update of other
environment components does not occur within the scope of Mirantis OpenStack
update.

.. warning:: Updating of a Mirantis OpenStack deployment results in a downtime
             of the entire environment. Therefore, before applying the
             updates to production, you must plan a maintenance window and
             back up your deployment as well as test the updates on your
             staging environment. We strongly recommend consulting
             Mirantis Support if you plan to update your
             Mirantis OpenStack environment.

This section includes the following topics:

.. toctree::
  :maxdepth: 2

  update-product/update-limitations-9-2.rst
  update-product/update-prerequisites-9-2.rst
  update-product/update-master-9-2.rst
  update-product/update-env-9-2.rst
  update-product/customize-new-node-9-2.rst
