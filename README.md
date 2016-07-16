
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


Configuration file:
-------------------

Conf file contains very important step flags

`playbooks/vars/steps/steps_conf.yml`

Usage:
------

For avoiding issues (like loose customizations and failed upgrade/appliyng patches)
some steps are disabled in conf file and

By default, it will not work without additonal variables or conf modifiyng.

`ansible-playbook playbooks/apply_mu.yml --limit="cluster_1" -e '{"steps":"steps_conf"}`

Or

The tool can be used partially, step by step (each step will invoke all steps above it, except the last one):

1. Check that all upgradable packages were installed from configured repositaries and which from them were customized.

`ansible-playbook playbooks/verify_md5.yml --limit="cluster_1 -e '{"steps":"steps_conf"}"`

2. Generate patch files for each customized package, download these patches to Fuel master

`ansible-playbook playbooks/gather-customizations.yml --limit="cluster_1 -e '{"steps":"steps_conf"}"`

3. Verify that all pathces can be applied to the new packages without issues

`ansible-playbook playbooks/verify_patches.yml --limit="cluster_1 -e '{"steps":"steps_conf"}"`

4. Upgrade all packages

`ansible-playbook playbooks/upgrade.yml --limit="cluster_1 -e '{"steps":"steps_conf"}"`

5. Apply the patches on upgraded cluster

`ansible-playbook playbooks/apply_patches.yml --limit="cluster_1 -e '{"steps":"steps_conf"}"`

6. Restart OpenStack services (only restarting)

`ansible-playbook playbooks/restart_services.yml --limit="cluster_1 -e '{"steps":"steps_conf"}"`


