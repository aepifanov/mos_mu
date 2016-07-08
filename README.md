
Prerequisites:
- epel: `yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm`
- centos: `yum -y reinstall centos-release`
- ansible: `yum -y install ansible`

Usage:
`ansible-playbook playbooks/apply_my.yml --limit="node-1.domain.tld"  -vvvv`

Or

It might be used partly, step by step (each next step included all previous steps):
- Check that all upgradable packages were installed from configured repositaries
  and which from them were customized.
  `ansible-playbook playbooks/verify.yml --limit="node-1.domain.tld"  -vvvv`

- Generate patch files for each customized package and dowload them to Fuel master as well
  and test if them will be applied to the new package version
  `ansible-playbook playbooks/get-customizations.yml --limit="node-1.domain.tld"  -vvvv`

- Upgrade all packages and apply the customization on it
  `ansible-playbook playbooks/upgrade.yml --limit="node-1.domain.tld"  -vvvv`

- Upgrade and restart OpenStack services
  `ansible-playbook playbooks/apply_mu.yml --limit="node-1.domain.tld"  -vvvv`

Configuration:
playbooks/vars/70.yml
