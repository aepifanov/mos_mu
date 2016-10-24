#!/bin/bash

# Add CentOS and EPEL repos
yum -y reinstall centos-release
yum -y install epel-release

# Install Ansible
yum -y install ansible
# Install tree util
yum -y install tree
# Install jq util
yum -y install jq

# Delete CentOS and EPEL repos to avoid issues with Fuel services
yum -y remove epel-release
rm /etc/yum.repos.d/CentOS-*.repo
