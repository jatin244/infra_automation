#!/bin/bash
echo "workspace : $WORKSPACE"
. $WORKSPACE/infra-scripts/shell/common.sh

CONFIG_FILE=$WORKSPACE/infra-config/config/$ARCHITECTURE/$PRODUCT/$ENVIRONMENT/postInfra/$ENVIRONMENT-postInfra.conf
file_exists $CONFIG_FILE
sed 's/^[ \t]*//;s/[ \t]*$//' $CONFIG_FILE | sed '/^$/d' > temp_file && mv temp_file $CONFIG_FILE
cat $CONFIG_FILE
. $CONFIG_FILE

switchAccount $OPS_ROLE_ARN
set_defaults
ansible_config_setup
switchAccountToDefault


chmod +x $WORKSPACE/ansible/ec2.py
$WORKSPACE/ansible/ec2.py --list
errorCheckWithMessage $? "Issue in validation of ansible dynamic inventory. Exiting ...."

echo "Any network level post infra config setup will be executed here"

