Apply MU
========

This is a tool for applying Maintenance Updates on deployed MOS environments.

If you have any questions please don't hesitate to ask me: aepifanov@mirantis.com

Any comments/suggestions are welcome :)

Features
--------

- Gather current customizations and backup them
- Apply MU
- Apply gathered customizations and new patches after applying MU


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

It's recommended to continue working under screen or tmux to avoid a break of procedure
due to lost ssh session and etc.

During the work plabooks print important information, like description of errors and usefull
information (list of upgradable packages, current MU and etc). So, please always after the
completion of playbooks scroll up the screen and carefully read the output. Also output is
logged in ansible.log file in the mos_mu directory and can be read there.


- [Usage for MOS 6.x/7.0/8.0](doc/usage_old.rst)
- [Usage for MOS 9.x](doc/update-product.rst)
