
install:
- epel
  yum install epel-release-6-8.noarch.rpm
- centos
  yum -y reinstall centos-release
- ansible
  yum install ansible

example:
ansible-playbook playbooks/pkgs_verify_md5_result.yml --limit="node-1.domain.tld"  -vvvv
