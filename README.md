
Prerequisites:
- epel: `yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm`
- centos: `yum -y reinstall centos-release`
- ansible: `yum -y install ansible`

Usage: `ansible-playbook playbooks/pkgs_verify_md5_result.yml --limit="node-1.domain.tld"  -vvvv`
