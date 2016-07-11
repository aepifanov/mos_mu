Prerequisites:
--------------

- epel: `yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm`
- centos: `yum -y reinstall centos-release`
- ansible: `yum -y install ansible`

Usage:
------

`ansible-playbook playbooks/apply_mu.yml --limit="cluster_1"`

Or

The tool can be used partially, step by step (each step will invoke all steps above it, except the last one):

1. Check that all upgradable packages were installed from configured repositaries and which from them were customized.

`ansible-playbook playbooks/verify.yml --limit="cluster_1"`

2. Generate patch files for each customized package, download these patches to Fuel master and test if they can be applied to the new package version

`ansible-playbook playbooks/get-customizations.yml --limit="cluster_1"`

3. Upgrade all packages and re-apply the customization on any customized packages

`ansible-playbook playbooks/upgrade.yml --limit="cluster_1"`

4. Restart OpenStack services (only restarting)

`ansible-playbook playbooks/restart_services.yml --limit="cluster_1"`


Configuration file:
-------------------

`playbooks/vars/70.yml`
