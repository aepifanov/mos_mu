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
- supports only MOS versions: 6.1, 7.0, 8.0 and 9.x.
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
actually adds standard CentOS and EPEL repositories, installs Ansible and then deletes
these repos for avoiding any issues with compatibility with Fuel services.
```
./install_ansible.sh
```

Documentation
=============

[Architecture](doc/architecture.md)

Before using this tool please take a look into vars files:
- [Vars files](playbooks/vars/)
- [Apply MU steps](playbooks/vars/steps/apply_mu.yml)

You can use these flags specify them as Ansible extra vars.

Usage
=====

- [Udage for MOS 6.1/7.0/8.0](doc/usage_old.md)
- [Usage for MOS 9.x](doc/usage_9x.md)
