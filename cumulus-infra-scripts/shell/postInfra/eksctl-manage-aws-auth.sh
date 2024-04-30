#!/bin/bash
echo "workspace : $WORKSPACE"
. $WORKSPACE/infra-scripts/shell/common.sh

CONFIG_FILE=$WORKSPACE/infra-config/config/$ARCHITECTURE/$PRODUCT/$ENVIRONMENT/postInfra/$ENVIRONMENT-postInfra.conf
file_exists $CONFIG_FILE
sed 's/^[ \t]*//;s/[ \t]*$//' $CONFIG_FILE | sed '/^$/d' > temp_file && mv temp_file $CONFIG_FILE
cat $CONFIG_FILE
. $CONFIG_FILE

AUTH_CONFIG_FILE=$WORKSPACE/infra-config/config/$ARCHITECTURE/$PRODUCT/$ENVIRONMENT/postInfra/$ENVIRONMENT-aws-auth.conf
file_exists $AUTH_CONFIG_FILE
sed -e 's/^[ \t]*//;s/[ \t]*$//' -e '/^$/d' -e '/^#/d' "$AUTH_CONFIG_FILE" > temp_file && mv temp_file "$AUTH_CONFIG_FILE"
cat $AUTH_CONFIG_FILE

# Function to process each valid line
process_line() {
    local line="$1"
    echo "$line" | tr ' ' '\n' | while read -r arn && read -r groups; do
        showMessage "Check if any entry already exists in aws-auth configmap"
        eksctl get iamidentitymapping --cluster="${CLUSTER_NAME}" --region "${PRODUCT_AWS_REGION}" --arn="$arn"
        if [ $? -eq 0 ]; then
            showMessage "Entry for $arn already exists. skipping !!!"
            continue
        fi
        showMessage "Add entry to aws-auth ConfigMap using eksctl"
        eksctl create iamidentitymapping --cluster="${CLUSTER_NAME}" --region "${PRODUCT_AWS_REGION}" --arn="$arn" --group="$groups" --no-duplicate-arns
        return $?
    done
}

# Main script
input_file="$AUTH_CONFIG_FILE"
CLUSTER_NAME="${ENVIRONMENT}-eks-cluster"
line_number=0
awk 'NF!=2 {print "Line " NR " does not contain 2 fields: " $0}' $input_file
awk 'NF==2' $input_file | while read line
do
    line_number=$((line_number + 1))
    echo -e "\033[0;34mProcessing line $line_number: $line\033[0m"
    process_line "$line"
    errorCheckWithMessage $? "Issue with updating aws-auth configmap setup. Exiting..."
done

