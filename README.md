Apply MU
========

This is a tool for applying Maintenance Updates on deployed MOS environments.

**WORK IN PROGRESS !!!**

Don't use it on production environment until it will be released !!!

If you have any questions please don't hesitate to ask me: aepifanov@mirantis.com

Any comments/suggestions are welcome :)

Features
--------

- gather current customizations and backup it
- apply MUs
- apply gathered customizations
- apply new customizations and patches
- restart OpenStack services
- rollback on any release


Conditions and Limitations
--------------------------

- should be run on Fuel Master under root
- supports only MOS versions: 6.1, 7.0 and 8.0.
- supports only Ubuntu
- doesn't start puppet which means that doesn't apply fixes which are in puppet manifests
- needs manual restart for non OpenStack services (RabbitMQ, MySQL, Libvirt, CEPH and etc)
- patches should have absolute target path

Install
=======

Clone Git repository from GitHub on Fuel Master node:
```
git clone https://github.com/aepifanov/mos_mu.git
cd mos_mu
```

For Ansible installing you can use [install_ansible.sh](install_ansible.sh) script which
actually adds standard CentOS and EPEL reposistories, installs Ansible and then deletes
these repos for avoiding any issues with compatibility with Fuel services.
```
./install_ansible.sh
```

Documentation
=============

Outdated !!!
[Architecture](doc/architecture.md)

Before using this tool please take a look into vars files:
- [Vars files](playbooks/vars/)
- [Apply MU steps](playbooks/vars/steps/apply_mu.yml)

You can use these flags specify them as Ansible extra vars.

Usage
=====

Preparations
------------

First of all we would recommend to gather current customizations:
```
ansible-playbook playbooks/gather_customizations.yml -e '{"env_id":<env_id>}'
```

During performing all steps you can use the flags for step management.
[Apply MU steps](playbooks/vars/steps/apply_mu.yml)
For example you can skip health check step or repeat generation of APT files
or gathering customizations one more time.
```
ansible-playbook playbooks/gather_customizations.yml -e '{"env_id":<env_id>,"health_check":false,"gather_customizations":true}'
```
Sometimes playbooks can stop with failing and recommend to use
some flags for the solving the situation, for example, when patch
were applied not on all nodes.


Then check that all customizations are applied on new versions:
```
ansible-playbook playbooks/verify_patches.yml -e '{"env_id":<env_id>}'
```

After that please go to the nodes **/root/mos_mu/verification/** and make sure
that all patches are applied correctly.

It is also strongly recommended to identify and copy original patches to
**patches** folder on Fuel and disable **use_current_customization** flag and
manage patches to successfully execute previous **verify_patches.yml** step.

Apply
-----

Update Fuel node:
```
ansible-playbook playbooks/update_fuel.yml
```
And apply MU:
```
ansiblee-playbook playbooks/apply_mu.yml -e '{"env_id":<env_id>}'
```

This playbook contains gathering and verifying steps and you can start from
Fuel updateing step, but in this case it will apply the current customizations
and patches from **patches** folder from Fuel on each node and you will
get exactly the same customizations that were before.

Full restart
------------

For the applying updates for some services like CEPH, RabbitMQ and etc we would
recommend to restart them manually and at the same time monitor thier status.

Which services were updated you can find in output in section
**Show upgradable packages**

Please also read the upgrade section in documentation for these services.

Rollback
--------

Rollback (actually pseudo rollback) playbook can return your cluster on any
specified release and apply gathered customizations:
```
ansible-playbook playbooks/rollback.yml -e '{"env_id":<env_id>,"rollback":"<release_name>"}'
```

Local repos mirrors
-------------------

If nodes don't have access to http://mirror.fuel-infra.org/ you can create and sync
local mirrors:
```
ansible-playbook playbooks/create_mirrors.yml -e '{"env_id":<env_id>}'
```

Then for the using them you to add **fuel_url** external variable:
```
ansible-playbook playbooks/apply_mu.yml -e '{"env_id":<env_id>,"fuel_url":"http://<FUEL_IP>:8080"}'
```

