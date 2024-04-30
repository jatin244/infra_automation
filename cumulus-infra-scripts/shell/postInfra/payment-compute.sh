#!/bin/bash
echo "workspace : $WORKSPACE"
. $WORKSPACE/infra-scripts/shell/common.sh

CONFIG_FILE=$WORKSPACE/infra-config/config/$ARCHITECTURE/$PRODUCT/$ENVIRONMENT/postInfra/$ENVIRONMENT-postInfra.conf
file_exists $CONFIG_FILE
sed 's/^[ \t]*//;s/[ \t]*$//' $CONFIG_FILE | sed '/^$/d' > temp_file && mv temp_file $CONFIG_FILE
cat $CONFIG_FILE
. $CONFIG_FILE

. $WORKSPACE/infra-scripts/shell/postInfra/base_postInfra.sh

##########################
##### Ansible Configuration
##########################
switchAccount $OPS_ROLE_ARN
set_defaults
ansible_config_setup
switchAccountToDefault
chmod +x $WORKSPACE/ansible/ec2.py
$WORKSPACE/ansible/ec2.py --list > /dev/null
errorCheckWithMessage $? "Error : Issue in validation of ansible dynamic inventory. Exiting ...."

export EC2_INI_PATH=${WORKSPACE}/ansible/ec2.ini
export ANSIBLE_CONFIG=${WORKSPACE}/ansible/ansible.cfg
export ANSIBLE_FORCE_COLOR=true

echo "refreshing EC2 cache..."
$WORKSPACE/ansible/ec2.py --refresh-cache > /dev/null

##########################
##### etcd cluster EC2
##########################
DEPLOY_TAG=$ENVIRONMENT-etcd-cluster 
check_var "DEPLOY_TAG"
HOST_DEPLOY_TAG="tag_Deploy_$(echo "$DEPLOY_TAG" | sed 's/-/_/g')"
echo "DEPLOY_TAG: "$HOST_DEPLOY_TAG

rebootHost

MOUNT_CONFIG="$WORKSPACE/infra-config/config/$ARCHITECTURE/$PRODUCT/$ENVIRONMENT/$STAGE/mounts/mount-config.json"
file_exists $MOUNT_CONFIG
tmp=$(cat $MOUNT_CONFIG)
echo -e "Mounting configurations: \n" ${tmp}

showMessage "Mounting disks for etcd Instances... "
playBook "{'host_tag':'$HOST_DEPLOY_TAG','mount':'$tmp','EBS':'etcdEBS','override':'$ALLOW_POST_EC2_SETUP_INSTALL'}" mounting.yml

showMessage "Configuring etcd database cluster"
playBook "{'host_tag':'$HOST_DEPLOY_TAG'}" etcd-cluster/configure-etcd-cluster.yaml

##########################
##### es cluster EC2
##########################
DEPLOY_TAG=$ENVIRONMENT-es-cluster 
check_var "DEPLOY_TAG"
HOST_DEPLOY_TAG="tag_Deploy_$(echo "$DEPLOY_TAG" | sed 's/-/_/g')"
echo "DEPLOY_TAG: "$HOST_DEPLOY_TAG

rebootHost

MOUNT_CONFIG="$WORKSPACE/infra-config/config/$ARCHITECTURE/$PRODUCT/$ENVIRONMENT/$STAGE/mounts/mount-config.json"
file_exists $MOUNT_CONFIG
tmp=$(cat $MOUNT_CONFIG)
echo -e "Mounting configurations: \n" ${tmp}

showMessage "Mounting disks for es Instances... "
playBook "{'host_tag':'$HOST_DEPLOY_TAG','mount':'$tmp','EBS':'esEBS','override':'$ALLOW_POST_EC2_SETUP_INSTALL'}" mounting.yml

##########################
##### EKS cluster aws-auth
##########################
showMessage "Adding EKS access controls for Roles/Users in aws-auth configmap... "
switchAccount $PRODUCT_ROLE_ARN
chmod +x $WORKSPACE/infra-scripts/shell/postInfra/eksctl-manage-aws-auth.sh
sh $WORKSPACE/infra-scripts/shell/postInfra/eksctl-manage-aws-auth.sh
switchAccountToDefault