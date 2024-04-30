#!/bin/bash

## Set hostname
export TAG_HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/Name)
sudo hostnamectl set-hostname "$TAG_HOSTNAME"

export PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sudo echo "$PRIVATE_IP  $TAG_HOSTNAME" >> /etc/hosts
