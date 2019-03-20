#!/bin/bash
# Install update all
sudo yum install epel-release -y
sudo yum update -y
# Installing Ansible
sudo yum install ansible -y
# Install dos2unix to fix script files
sudo yum install dos2unix -y
find /home/vagrant/provision/ -type f -print0 | xargs -0 sudo dos2unix --
echo "Finished Database section"
# Chainge Permitions for keys r-x------
sudo chmod -R 500 /home/vagrant/provision/ssh_keys
# Allow connecting without checking host
sudo cat <<EOF | sudo tee -a /etc/ansible/ansible.cfg
[defaults]
host_key_checking = false
inventory = /home/vagrant/hosts.txt

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
EOF
#sudo chmod 777 /home/vagrant/vars.sh
sudo ansible-playbook provision/ansible_playbooks/playbook.yml
