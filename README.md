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

- supports only MOS versions: 6.1, 7.0 and 8.0.
- supports only Ubuntu
- all nodes should have access to the configured repos (mirror.fuel-infra.org by default)
- doesn't start puppet which means that doesn't apply fixes which are in puppet manifests
- needs manual restart for non OpenStack services (RabbitMQ, MySQL, Libvirt, CEPH and etc)
- focused on only standard MOS deployment. If you have custom deployment schema please review playbooks
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

And check that all customizations are applied on new versions
```
ansible-playbook playbooks/verify_patches.yml -e '{"env_id":<env_id>}'
```

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

For the applying updates for some services like CEPH, Libvirt and etc we would
recommend to restart nodes one by one manually and at the same time monitor
thier status.

Please also read the upgrade section in documentation for these services.

Rollback
--------

Rollback (actually pseudo rollback) playbook can return your cluster on any
specified release and apply gathered customizations:
```
ansible-playbook playbooks/rollback.yml -e '{"env_id":<env_id>,"rollback":"<release_name>"}'
```
