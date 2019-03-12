#!/bin/bash
BALANCE_IP=$1
WEB2_IP=$2
WEB1_IP=$3
DB_IP=$4
BALANCE_NAME=$5
WEB2_NAME=$6
WEB1_NAME=$7
DB_NAME=$8
# Install update all
sudo yum install epel-release -y
sudo yum update -y
# Installing Ansible
sudo yum install ansible -y
# Install dos2unix to fix script files
sudo yum install dos2unix -y
dos2unix /home/vagrant/scenario_1.sh
dos2unix /home/vagrant/scenario_2.sh
dos2unix /home/vagrant/playbook.yml
dos2unix /home/vagrant/pb_all.yml
dos2unix /home/vagrant/pb_nginx.yml
dos2unix /home/vagrant/pb_haproxy.yml
# Configuring Ansible
sudo touch /home/vagrant/hosts.txt
cat <<EOF | sudo tee -a /home/vagrant/hosts.txt
[ALL]
localhost ansible_connection=local
$WEB1_NAME ansible_ssh_host=$WEB1_IP ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/$WEB1_IP.pem
$WEB2_NAME ansible_ssh_host=$WEB2_IP ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/$WEB2_IP.pem
$DB_NAME ansible_ssh_host=$DB_IP ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/$DB_IP.pem
[WEB]
$WEB1_NAME ansible_ssh_host=$WEB1_IP ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/$WEB1_IP.pem
$WEB2_NAME ansible_ssh_host=$WEB2_IP ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/$WEB2_IP.pem
[DB]
$DB_NAME ansible_ssh_host=$DB_IP ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/$DB_IP.pem
[LB]
localhost ansible_connection=local
EOF
# Chainge Permitions for keys r-x------
sudo chmod -R 500 /home/vagrant/.ssh/
# Allow connecting without checking host
sudo cat <<EOF | sudo tee -a /etc/ansible/ansible.cfg
[defaults]
host_key_checking = false
inventory = /home/vagrant/hosts.txt

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
EOF
sudo ansible-playbook playbook.yml
