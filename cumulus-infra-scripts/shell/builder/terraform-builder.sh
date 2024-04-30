#!/bin/bash
DESCRIPTION="${ENVIRONMENT} - ${STAGE} - ${OPERATION} - ${ARCHITECTURE}(arch)" 
echo -e "[DESC] ${DESCRIPTION}"

echo "workspace : $WORKSPACE"
if [[ -f "$WORKSPACE/infra-scripts/shell/common.sh" ]]; then
    . $WORKSPACE/infra-scripts/shell/common.sh
else
    echo "ERROR : Unable to locate $WORKSPACE/infra-scripts/shell/common.sh. exiting ..."
    sleep 2
    exit 1
fi

echo -e "\e[1m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\e[0m"
echo -e "\e[34mExecute Terraform as follows:\e[0m"
echo -e "\e[34mEnvironment Name\e[0m  :  ${ENVIRONMENT}"
echo -e "\e[34mEnvironment Stage\e[0m :  ${STAGE}"
echo -e "\e[34mOperation\e[0m :  ${OPERATION}"
echo -e "\e[1m++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\e[0m"

ENVIRONMENT_TFVARS_PATH=$WORKSPACE/infra-config/config/${ARCHITECTURE}/${PRODUCT}/${ENVIRONMENT}/common/${ENVIRONMENT}.tfvars
STAGE_TFVARS_PATH=$WORKSPACE/infra-config/config/${ARCHITECTURE}/${PRODUCT}/${ENVIRONMENT}/${STAGE}/${ENVIRONMENT}-${STAGE}.tfvars

file_exists $ENVIRONMENT_TFVARS_PATH
file_exists $STAGE_TFVARS_PATH

terraform --version
errorCheckWithMessage $? "Error : Terraform installation not found on /usr/local/bin/terraform"
    
aws --version
errorCheckWithMessage $? "Error : Terraform installation not found on /usr/local/bin/terraform"


##### Init TF
    terraformInit $WORKSPACE/infra-scripts/terraform/infra/${ARCHITECTURE}/${STAGE}
    errorCheckWithMessage $? "Error during TF init via common, exiting ..."

# Create/Destroy/Plan Cluster
terraform get
echo -e "TFVARS PATH: \n
1. ${ENVIRONMENT_TFVARS_PATH} \n
2. ${STAGE_TFVARS_PATH} \n"
echo "PWD: "$(pwd)

if [[ $AUTO_APPROVE == 'true' ]]; then
    APPROVE=-auto-approve
elif [[ $AUTO_APPROVE == 'false' ]]; then
    APPROVE=""
else
    showMessage "ERROR : Invalid value for AUTO_APPROVE. Only true/false are valid. Exiting  ..."
    sleep 2
    exit 1
fi
   
retry=$RETRIES
tries=0
exit=0

if [[ ${OPERATION} == "apply" ]]; then

    # If auto_approve is disabled - print terraform plan
    if [[ $AUTO_APPROVE == 'false' ]]; then
        showMessage "Creating Terraform Plan for ${STAGE}..."
        showMessage "Terraform plan details with operation $OPERATION"
        terraform plan -input=false -var-file=${ENVIRONMENT_TFVARS_PATH} -var-file=${STAGE_TFVARS_PATH}
        errorCheckWithMessage $? "Error while creating terraform plan, exiting ..."
        showMessage "Terraform plan end ..."
        DESCRIPTION="${ENVIRONMENT} - ${STAGE} -  ${OPERATION}(plan) - ${ARCHITECTURE}(arch)" 
        echo -e "[DESC] ${DESCRIPTION}"
        exit 0
    fi

    # If RETRIES in config is set to 0 run single apply and exit on error
    if [[ $retry -eq 0 ]]; then
		showMessage "Creating Infra for ${STAGE}..."
		terraform ${OPERATION} $APPROVE -input=false -var-file=${ENVIRONMENT_TFVARS_PATH} -var-file=${STAGE_TFVARS_PATH}
		errorCheckWithMessage $? "Error while creating infra, exiting ..."
	fi

    # If RETRIES in config is more than 0 do this
    while [[ $retry -ne 0 ]]; do

        showMessage "Creating Infra..."
        showMessage "Stage : ${STAGE}"
        showMessage "Creating Infra with retries more than 0"
        showMessage "ENVIRONMENT_TFVARS_PATH value ${ENVIRONMENT_TFVARS_PATH}"
        showMessage "STAGE_TFVARS_PATH value ${STAGE_TFVARS_PATH}"
        showMessage "OPERATION value ${OPERATION}"
        showMessage "APPROVE value $APPROVE"

        terraform ${OPERATION} $APPROVE -input=false -var-file=${ENVIRONMENT_TFVARS_PATH} -var-file=${STAGE_TFVARS_PATH}

        # Exit retries loop if terraform command finishes without error
        if [[ $? -eq 0 ]]; then
            break
        else
            terraform ${OPERATION} $APPROVE -input=false -var-file=${ENVIRONMENT_TFVARS_PATH} -var-file=${STAGE_TFVARS_PATH}
        fi

        # End retries loop if we already tried enough times
        if [[ $tries -eq $RETRIES ]]; then
			echo "Error occured again, exiting..."
			exit 1
		fi
        ((tries=tries+1))

        echo "Error creating infra with terraform, destroying..."
        sleep 10
        terraform destroy $APPROVE -input=false  -var-file=${ENVIRONMENT_TFVARS_PATH} -var-file=${STAGE_TFVARS_PATH}
        if [[ $? -eq 0 ]]; then
            break
            echo "Error destroying infra, exiting with error..."
            sleep 2
            exit 1
        fi
    done
    showMessage "INFO : TerraformRetryCount - ${tries}"
else

    # If auto_approve is disabled - print terraform plan and exit
    if [[ $AUTO_APPROVE == 'false' ]]; then
        showMessage "Creating Terraform destroy Plan for ${STAGE}..."
        showMessage "Terraform plan details with operation $OPERATION"
        terraform plan -destroy -input=false -var-file=${ENVIRONMENT_TFVARS_PATH} -var-file=${STAGE_TFVARS_PATH}
        errorCheckWithMessage $? "Error while creating terraform destroy plan, exiting ..."
        showMessage "Terraform plan end ..."
        DESCRIPTION="${ENVIRONMENT} - ${STAGE} - ${OPERATION}(plan) - ${ARCHITECTURE}(arch)" 
        echo -e "[DESC] ${DESCRIPTION}"
        exit 0
    fi

    showMessage "Destroying Infra..."
    terraform ${OPERATION} $APPROVE -input=false -var-file=${ENVIRONMENT_TFVARS_PATH} -var-file=${STAGE_TFVARS_PATH}

    if [[ $? -ne 0 ]]; then
        echo "Error destroying Infra, trying again..."
        sleep 5
        terraform ${OPERATION} $APPROVE -input=false -var-file=${ENVIRONMENT_TFVARS_PATH} -var-file=${STAGE_TFVARS_PATH}

        if [[ $? -eq 0 ]]; then
            break
            echo "Error destroying infra, exiting with error..."
            sleep 2
            exit 1
        fi
    fi

    echo "Deleting Cluster State File : State-Files/${ARCHITECTURE}/${PRODUCT}/${ENVIRONMENT}/${ENVIRONMENT}_${STAGE}.tfstate"
    aws s3 rm s3://${TF_STATE_S3_BUCKET_NAME}/State-Files/${ARCHITECTURE}/${PRODUCT}/${ENVIRONMENT}/${ENVIRONMENT}_${STAGE}.tfstate

    showMessage "INFO : TerraformRetryCount - ${tries}"
    if [[ $exit -eq 1 ]]; then
		exit 1
	fi
fi

if [[ ${OPERATION} == "apply" ]] && [[ ${POST_INFRA_CONFIG} == "true" ]]; then
        #include post infra shell
        echo -e "\e[1;30mValidating existence of post-infra provisioning shell script\e[0m"
        POST_INFRA_SHELL="$WORKSPACE/infra-scripts/shell/postInfra/${ARCHITECTURE}-${STAGE}.sh"
        file_exists $POST_INFRA_SHELL
        ansible_config_initialize
        post_infra_config_initiate
        sh $POST_INFRA_SHELL
elif [[ ${OPERATION} == "destroy" ]]; then
        echo -e "\e[1;30mPost infra config not valid for destroy operation !!\e[0m"
else 
        echo -e "\e[1;30mSkipping post infra configuration shell based on input !!\e[0m"
fi
