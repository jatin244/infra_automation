#!/bin/bash

echo "================================================"
echo "Interactive shell for etcd cluster conifguration"
echo "================================================"

echo "Provide user name for ssh access to targets:"
read SSH_USER

echo "Provide full name of pem file with extension in /etc/ansible.ssh/keys for target ssh access:"
read KEY_FILE

echo "Provide Deploy tag value of targets"
read DEPLOY_TAG

echo "Directory named under /etc/ansible for ec2.py"
read INVENTORY_HOME

DEPLOY_TAG_STRING="tag_Deploy_$(echo $DEPLOY_TAG | tr '-' '_')"

echo "Call Ansible script with command - ansible-playbook -i /etc/ansible/$INVENTORY_HOME/ec2.py -u $SSH_USER -b --private-key /etc/ansible/.ssh/keys/$KEY_FILE --extra-vars \"host_tag=$DEPLOY_TAG_STRING\" configure-etcd-cluster.yaml"
ansible-playbook -i /etc/ansible/$INVENTORY_HOME/ec2.py -u $SSH_USER -b --private-key /etc/ansible/.ssh/keys/$KEY_FILE --extra-vars "host_tag=$DEPLOY_TAG_STRING" configure-etcd-cluster.yaml
