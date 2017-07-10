Apply MU
========

This is a tool for applying Maintenance Updates on deployed MOS environments.

If you have any questions please don't hesitate to ask me: aepifanov@mirantis.com

Any comments/suggestions are welcome :)

Features
--------

- gather current customizations and backup it
- apply MUs
- apply gathered customizations
- apply new customizations and patches
- restart OpenStack services


Conditions and Limitations
--------------------------

- should be run on Fuel Master under root
- supports only MOS versions: 6.x, 7.0, 8.0 and 9.x.
- supports only Ubuntu
- doesn't start puppet which means that doesn't apply fixes which are in puppet manifests
- needs manual restart for non OpenStack services (RabbitMQ, MySQL, CEPH and etc)
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
- [Steps](playbooks/vars/steps.yml)

You can use these flags specify them as Ansible extra vars.

Usage
=====

- [Usage for MOS 6.x/7.0/8.0](doc/usage_old.md)
- [Usage for MOS 9.x](doc/update-product.rst)
