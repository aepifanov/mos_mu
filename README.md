
Work in progress !!!

Don't use it on production environment until it will be released !!!

If you have any questions please don't hesitate to ask me:

aepifanov@mirantis.com

Any comments/suggestions are welcome :)

Prerequisites:
--------------

- epel: `yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm`
- centos: `yum -y reinstall centos-release`
- ansible: `yum -y install ansible`

Install:
--------

Clone Git repositary from GitHub on Fuel Master node:

`git clone https://github.com/aepifanov/mos_mu.git`

Configuration file:
-------------------

Conf file contains very important step flags

`playbooks/vars/steps/apply_mu.yml`

Usage:
------

For the first step we would recommend to gather current customizations:

`ansible-playbook playbooks/gather_customizations.yml --limit="cluster_1"`

Then check that all customizations are applied on new versions

`ansible-playbook playbooks/verify_patches.yml --limit="cluster_1"`

You also gather common customizations to 'patches' folder and disable 'use_curret_customization'

After that you can apply MU on environment

`ansible-playbook playbooks/apply_mu.yml --limit="cluster_1"`

this play book contained all previous steps as well, so it might be used from the begining.

Rollback:
---------

Also rollback playbook was implement, which can return your cluster on any specified
release and apply customizations:

`ansible-playbook playbooks/rollback.yml --limit="cluster_1" -e '{"rollback":"mu-1"}'`
