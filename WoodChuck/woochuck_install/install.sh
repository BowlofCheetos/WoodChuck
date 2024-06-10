#!/bin/bash

# Update libraries
sudo yum update -y

# Install python
sudo dnf install python3 -y

# Install syslog
sudo dnf install rsyslog

# Install dialog
sudo dnf install dialog

# Install EPEL package
sudo dnf install epel-release -y

# Install Ansible and verify version
sudo dnf install ansible -y
ansible --version

# Install python pip3.11
sudo dnf install python3.11-pip

# Upgrade pip install
pip3.11 install --upgrade pip --user

# Install all requirements
pip install -r requirements.txt

# Modify SSH config
cd $HOME/.ssh/ && touch config && chmod 644 config

# Update OpenSSH config
echo -e "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null" >> config

# Make Ansible directory
sudo mkdir /etc/ansible

# Make Ansible config
echo -e "[defaults]\n  host_key_checking = False" | sudo tee -a /etc/ansible/ansible.cfg > /dev/null