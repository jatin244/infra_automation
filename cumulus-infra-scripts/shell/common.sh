#!/bin/bash

terraformInit() {
    echo "OPERATION: "${OPERATION}
    echo "S3_BUCKET_NAME: "${TF_STATE_S3_BUCKET_NAME}
    echo "S3_BUCKET_REGION: "${TF_STATE_S3_BUCKET_REGION}
    
    TFScriptDir="$1"
    echo "TF directory : $TFScriptDir"
    cd $TFScriptDir

    DIRECTORY="${WORKSPACE}"
    if [[ $ENABLE_TF_LOGGING == 'false' ]]; then
        export TF_LOG=
        echo ""
    else
        export TF_LOG=TRACE
        export TF_LOG_PATH=$DIRECTORY/terraform-build-${BUILD_NUMBER}.log
        echo "Terraform log file"
        echo $DIRECTORY/terraform-build-${BUILD_NUMBER}.log
    fi
    
    rm -rf .terraform

    echo "Initing Terraform..."
    echo "Current Directory:/$(pwd)"
    terraform init -reconfigure -input=false -backend-config="encrypt=true" -backend-config="max_retries=100" -backend-config="bucket=${TF_STATE_S3_BUCKET_NAME}" -backend-config="region=${TF_STATE_S3_BUCKET_REGION}" -backend-config="key=State-Files/${ARCHITECTURE}/${PRODUCT}/${ENVIRONMENT}/${ENVIRONMENT}_${STAGE}.tfstate"
}

file_exists() {
    if [ -f "$1" ]; then
        showMessage "INFO: File $1 exists. Proceeding ...."
    else
        showMessage "ERROR : File $1 doesn't exist. Exiting with error  ...."
        exit 1
    fi
}

check_var() {
    local var_name="$1"
    local var_value
    eval var_value="\$$var_name"
    if [ -z "$var_value" ]; then
        showMessage "ERROR: Variable $var_name is empty.. Exiting ...."
        exit 1
    else
        showMessage "Variable $var_name has a valid value."
    fi
}

ansible_config_initialize() {
mkdir -p $WORKSPACE/ansible
file_exists $WORKSPACE/infra-scripts/ansible/config/ansible.cfg
cp $WORKSPACE/infra-scripts/ansible/config/ansible.cfg $WORKSPACE/ansible/
file_exists $WORKSPACE/infra-scripts/ansible/config/ec2.ini
cp $WORKSPACE/infra-scripts/ansible/config/ec2.ini $WORKSPACE/ansible/
file_exists $WORKSPACE/infra-scripts/ansible/config/ec2.py
cp $WORKSPACE/infra-scripts/ansible/config/ec2.py $WORKSPACE/ansible/
}

ansible_config_setup() {
file_exists $WORKSPACE/ansible/ec2.ini
echo "Updating IAM role and AWS region for ansible config"
check_var "PRODUCT_ROLE_ARN"
check_var "PRODUCT_AWS_REGION"
check_var "WORKSPACE"
awk -v pattern="#IAM_ROLE_ARN#" -v replacement="$PRODUCT_ROLE_ARN" '{gsub(pattern, replacement)} 1' "$WORKSPACE/ansible/ec2.ini" > "$WORKSPACE/ansible/ec2.ini.tmp" && mv "$WORKSPACE/ansible/ec2.ini.tmp" "$WORKSPACE/ansible/ec2.ini"
awk -v pattern="#AWS_REGION#" -v replacement="$PRODUCT_AWS_REGION" '{gsub(pattern, replacement)} 1' "$WORKSPACE/ansible/ec2.ini" > "$WORKSPACE/ansible/ec2.ini.tmp" && mv "$WORKSPACE/ansible/ec2.ini.tmp" "$WORKSPACE/ansible/ec2.ini"
awk -v pattern="#WORKSPACE#" -v replacement="$WORKSPACE" '{gsub(pattern, replacement)} 1' "$WORKSPACE/ansible/ansible.cfg" > "$WORKSPACE/ansible/ansible.cfg.tmp" && mv "$WORKSPACE/ansible/ansible.cfg.tmp" "$WORKSPACE/ansible/ansible.cfg"

showMessage "INFO : Fetching Required pem key files from parameter store:"
mkdir -p $WORKSPACE/ansible/keys
aws ssm get-parameter --name /Deployer/ansible/keys/${PRIMARY_SSH_KEY} --region $OPS_AWS_REGION --with-decryption --query "Parameter.Value" --output text > $WORKSPACE/ansible/keys/${PRIMARY_SSH_KEY}
errorCheckWithMessage $? "ERROR: Issue in fecthing PRIMARY_SSH_KEY from Parameter store"
aws ssm get-parameter --name /Deployer/ansible/keys/${ANSIBLE_SSH_KEY} --region $OPS_AWS_REGION --with-decryption --query "Parameter.Value" --output text > $WORKSPACE/ansible/keys/${ANSIBLE_SSH_KEY}
errorCheckWithMessage $? "ERROR: Issue in fecthing ANSIBLE_SSH_KEY from Parameter store"
chmod 400 $WORKSPACE/ansible/keys/${PRIMARY_SSH_KEY}
chmod 400 $WORKSPACE/ansible/keys/${ANSIBLE_SSH_KEY}
}

post_infra_config_initiate() {
echo -e "\e[34m**********************************************************************************************\e[0m"
echo -e "\e[34mExecuting post infra provisioning configuration steps as follows:\e[0m"
echo -e "\e[95mARCHITECTURE\e[0m      :       $ARCHITECTURE"
echo -e "\e[95mSTAGE\e[0m             :       $STAGE"
echo -e  "\e[95mENVIRONMENT\e[0m      :       $ENVIRONMENT"
echo -e "\e[95mSCRIPT\e[0m            :       $POST_INFRA_SHELL"
echo -e "\e[34m**********************************************************************************************\e[0m"
}

errorCheckWithMessage() {
    exitCode=$1
    errMsg=$2
    
    if [ -n "${errMsg}" ] && [ "${exitCode}" -ne 0 ]; then
        showMessage "ERROR: ${errMsg}"
        exit "${exitCode}"
    fi
}


clone_with_retry() {
    local repo_url="$1"
    local branch="$2"
    local folder="$3"
    local retries=2
    local retry_delay=5

    while [ $retries -gt 0 ]; do
        showMessage "INFO: Attempting to clone $repo_url, branch $branch into $folder ..."
        if git clone -b "$branch" "$repo_url" "$folder"; then
            showMessage "INFO: Clone successful!"
            return 0
        else
            echo "WARN : Clone failed. Retrying..."
            rm -rf "$folder"
            ((retries--))
            sleep $retry_delay
        fi
    done

    showMessage "ERROR : Failed to clone after multiple retries."
    exit 1
}

showMessage() {
    msg=$1
    echo "**********************************************************************************************"
	echo $msg
	echo "**********************************************************************************************"
}

switchAccount() {
    showMessage "Switching account"
    echo "Current account:"
    aws sts get-caller-identity
    roleArn=$1
    randomString=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')
    tmp=$(aws sts assume-role --role-arn "$roleArn" --role-session-name "$randomString")
    AWS_ACCESS_KEY_ID=$(echo "$tmp" | grep AccessKeyId | awk '{print $2}' | sed 's/,$//g' | sed 's/"//g')
    AWS_SECRET_ACCESS_KEY=$(echo "$tmp" | grep SecretAccessKey | awk '{print $2}' | sed 's/,$//g' | sed 's/"//g')
    AWS_SESSION_TOKEN=$(echo "$tmp" | grep SessionToken | awk '{print $2}' | sed 's/,$//g' | sed 's/"//g')
    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
    export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
    echo "Current account:"
    aws sts get-caller-identity
}

switchAccountToDefault() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    echo "Default account:"
    aws sts get-caller-identity
}

set_defaults() {
## defaults
check_var "PRIMARY_SSH_KEY"
PRIMARY_KEY_FILE=${PRIMARY_SSH_KEY}
check_var "PRIMARY_SSH_USER"
PRIMARY_USER=${PRIMARY_SSH_USER}
check_var "ANSIBLE_SSH_USER"
ANSIBLE_USER=${ANSIBLE_SSH_USER}
check_var "ANSIBLE_SSH_KEY"
ANSIBLE_KEY_FILE=${ANSIBLE_SSH_KEY}

echo "ENVIRONMENT NAME:         "$ENVIRONMENT
echo "KEY:                      "$ANSIBLE_KEY_FILE
}

