#!/bin/bash
echo "workspace : $WORKSPACE"
. $WORKSPACE/infra-scripts/shell/common.sh

CONFIG_FILE=$WORKSPACE/infra-config/config/$ARCHITECTURE/$PRODUCT/$ENVIRONMENT/$ENVIRONMENT-postInfra.conf
file_exists $CONFIG_FILE
sed 's/^[ \t]*//;s/[ \t]*$//' $CONFIG_FILE | sed '/^$/d' > temp_file && mv temp_file $CONFIG_FILE
cat $CONFIG_FILE
. $CONFIG_FILE

# Function to process each valid line
process_arn() {
    local arn="${1}"
    local groups="${2}"
    
    # Add entry to aws-auth ConfigMap using eksctl
    if [[ ${OPERATION} == "apply" ]]; then
        showMessage "Check if any entry already exists in aws-auth configmap"
        eksctl get iamidentitymapping --cluster="${CLUSTER_NAME}" --region "${PRODUCT_AWS_REGION}" --arn="$arn"
        if [ $? -eq 0 ]; then
            showMessage "Entry for $arn already exists. Duplicate arn entries are not allowed as per script. skipping !!!"
            exit 1
        fi
        showMessage "Add entry to aws-auth ConfigMap using eksctl"
        eksctl create iamidentitymapping --cluster="${CLUSTER_NAME}" --region "${PRODUCT_AWS_REGION}" --arn="$arn" --group="$groups"  --no-duplicate-arns
        return $?
    elif [[ ${OPERATION} == "destroy" ]]; then
        showMessage "Delete entry from aws-auth ConfigMap using eksctl"
        eksctl delete iamidentitymapping --cluster="${CLUSTER_NAME}" --region "${PRODUCT_AWS_REGION}" --arn="$arn" --all
        return $?
    else
        errorCheckWithMessage 1 "Incorrect input for Operation. Allowed values - apply/destroy. Exiting..."
        return $?
    fi
        
}

# Main script
switchAccount $PRODUCT_ROLE_ARN
if [ -z "$CLUSTER_NAME" ]; then
    CLUSTER_NAME="${ENVIRONMENT}-eks-cluster"
fi
showMessage "EKS Cluster - ${CLUSTER_NAME}"
process_arn $ARN $GROUPS
errorCheckWithMessage $? "Issue in processing the required action"...
switchAccountToDefault

