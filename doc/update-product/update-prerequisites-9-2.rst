.. _update-prerequisites-9-2:

**Caution**

    Carefully read the whole `update to 9.2`_ section
    to understand the update scenario.

    We strongly recommend contacting Mirantis Support if you plan
    to update your Mirantis OpenStack environment.

=============
Prerequisites
=============

Before you update Mirantis OpenStack from version 9.0 or 9.1 to 9.2,
verify that you have completed the following tasks:

#. Read the Limitations_ section.

#. Test the update instructions in a lab environment before applying
   the updates to production.
#. Plan a maintenance window before applying the updates to production, as
   some update steps result in a downtime for existing workloads.
#. Verify that you have Internet access on the Fuel Master node to
   download the updated repository.
#. Verify that you have about 2.5 GB of free space in the ``/var/www/nailgun``
   folder if you want to store the updates repository locally and obtain it
   with the ``fuel-mirror`` tool.
#. Log in to the Fuel Master node CLI as root.
#. Add the ``mos92-updates`` repository:

   .. code-block:: console

    yum install -y http://mirror.fuel-infra.org/mos-repos/centos/mos9.0-centos7/9.2-updates/x86_64/Packages/mos-release-9.2-1.el7.x86_64.rpm

#. Clean the YUM cache:

   .. code-block:: console

    yum clean all

#. Install the ``mos-playbooks`` package:

   .. code-block:: console

    yum install -y mos-playbooks

After completing these tasks, proceed to `Update Fuel Master node`_.

.. _`update to 9.2`: ../update-product.rst
.. _Limitations: update-limitations-9-2.rst
.. _`Fuel User Guide`: http://docs.openstack.org/developer/fuel-docs/mitaka/userdocs/fuel-user-guide/maintain-environment/backup-fuel.html
.. _`Update Fuel Master node`: update-master-9-2.rst

