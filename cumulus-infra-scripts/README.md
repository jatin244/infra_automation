# Terraform Deployment and Eks Login

This documentation provides a set of best practices to let you implement changes to your Infrastructure using Terraform. The Terraform apply command is a crucial step in the deployment process, and it is important to proceed carefully. You can ensure a smooth and dependable deployment process by adhering to these suggested practices.

## Prerequisites :-
- Install  git-remote-codecommit :https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install-linux.html
- Install terraform(Terraform version required  = 1.3.8): https://developer.hashicorp.com/terraform/downloads
- Install Helm: https://helm.sh/docs/intro/install/
- Install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
- Should have access to the bastion server if not, please grant access from the cloud team. 
- Should have connectivity to Forticlient VPN If not, please grant access from the cloud team.

## Bastion Server Connection:
To connect to the bastion server using SSH, use the following command. It establishes a secure shell connection to the server at the given IP address (172.25.83.199) and using the private key file ('private-key.pem') for authentication. The Username for the SSH connection is 'username'.

### Make sure to Replace:
- The private-key.pem file with your own private key file name.
- username with your appropriate username.
- 172.25.83.199 with your Instance public IP.
Run this command to connect to bastion.

```
ssh -i "private-key.pem"  username@172.25.83.199
```
## Clone Repository:

- To clone the repository, use the following URL:
```
git clone codecommit::us-east-1://cumulus-vtx-iaas
```
- This command is used to clone the Git repository. It will create a copy of the repository, which you may access and interact with this repository's files.
- git clone This Git command is used to clone or copy a remote repository to your Bastion server.
- The remote repository's URL is codecommit::us-east-1://cumulus-vtx-iaas  The repository in this instance is kept on an AWS CodeCommit server that is located in the US East (N. Virginia) region.  cumulus-vtx-iaas is the name of the particular repository that is being cloned.

## Terraform:

### Authentication to the cloud: 

There is no additional authentication required to run Terraform for respected AWS accounts. Bastion host has access to these Aws accounts based on i am profile attached to it. 
Authentication of Terraform is being done on the basis of a switch role created by respected AWS.
These are the roles that is created in a respected account and defined already in terraform tfvars as well as mentioned in provider configuration of Terraform code. So need to export aws profile and sso for this. 

```
ops_assume_role_arn = "arn:aws:iam::304575748023:role/VTX-CIBuilder-Ops-Engg"
intercom_role_arn   = "arn:aws:iam::762861681156:role/VTX-CIBuilder-Intercom-NonProd"
stack_role_arn      = "arn:aws:iam::738066270403:role/VTX-CIBuilder-Product-DevOps"
```

The table aligns with the provided documentation and includes the respective headings for each column: "Environment Name," "Related Variable File," "Backend Configuration File," and "Bucket Name."

| Environment Name|Related var file|Backend config file|Bucket Name |
| :------------ |:---------------:| -----:| -----:|
| david    | config/david.tfvars | terraform/david.tfstate | vtx-cibuilder-tf-dnsonprod |
| eric   | config/eric.tfvars      |  terraform/eric.tfstate | vtx-cibuilder-tf-dnsonprod |
| kevin | config/kevin.tfvars      |    terraform/kevin.tfstate |  vtx-cibuilder-tf-dnsonprod |
| paul      | config/paul.tfvars | terraform/paul.tfstate | vtx-cibuilder-tf-dnsonprod |
| vxdvshare      | config/vxdvshare.tfvars     |   terraform/vxdvshare.tfstate |  vtx-cibuilder-tf-dnsonprod |
| xvqa | config/xvqa.tfvars       |    terraform/xvqa.tfstate |  vtx-cibuilder-tf-dsqa |
| vxdv    | config/vxdv.tfvars | terraform/vxdv.tfstate | vtx-cibuilder-tf-dsnonprod |

## Terraform Steps:

Below are the instructions for deploying Networking, Compute and Helm infrastructure using Terraform.

## Networking Deployment :

First, Navigate to the deployment directory in the repository using this command:

```
cd /infra/us-east-1/networking
```

```networking``` is the deployment directory where all Networking configuration will be deployed using terraform.

### Initialize terraform for Networking configuration:-

Initialize Terraform with the necessary configurations for Networking using the following command:

```
sudo terraform init -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-networking.tfvars  -backend-config="key=terraform/${env}-networking.tfstate" -backend-config="bucket=vtx-cibuilder-tf-dsqa"
```

This command initializes Terraform for a specific environment for Networking configuration. The ‘var-file’ flag  specifies the variable file containing common variables in ```${env}.tfvars``` and networking-specific variables in ```${env}-networking.tfvars```. The ‘-backend-config’ flag is used to configure the backend for storing the Terraform state remotely in the specified bucket.  

#### Table Reference:

Replace ```${env}```.tfvars and ```bucket-name``` in the commands with the corresponding related variable file from the table.

### Plan (Networking):-

Generate a Terraform execution plan for the Networking configuration using the following command:

```
sudo terraform plan -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-networking.tfvars
```

This command creates a Terraform execution plan for the provided environment for Networking configuration. It analyzes the Terraform configuration, compares it to the current state, and generates a list of operations that will be performed when applying the configuration.

### Apply (Networking):-

Apply the Networking configuration using the following command:

``` 
sudo terraform apply -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-networking.tfvars 
```

This command will create or modify the Terraform Configuration for provisioning the Networking resources as defined in the specified environment-specific file. It executes the planned actions from the Terraform plan and provisions the networking infrastructure. 

NOTE :- Before executing the ```‘terraform apply’``` command, carefully review the execution plan generated by ```‘terraform plan'``` to ensure that no resources are unintentionally deleted or disrupted during the deployment process.

### Destroy (Networking):-

To destroy the Networking infrastructure, use the following command:

```
sudo terraform destroy -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-networking.tfvars
```

The terraform destroy command terminates resources managed by your Terraform . This command is the inverse of terraform apply in that it terminates all the networking resources specified in your Terraform state.

Note: Make sure before running the Terraform destroy command.



## Deployment for Compute:

First, Navigate to the deployment directory in the repository using this command:

```
cd /infra/us-east-1/compute
```

```compute``` is the deployment directory where all Compute configuration will be deployed using terraform.

### Initialize terraform for Compute configuration:-

Initialize Terraform with the necessary configurations for Compute configuration using the following command:

```
sudo terraform init -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-compute.tfvars  -backend-config="key=terraform/${env}-compute.tfstate" -backend-config="bucket=vtx-cibuilder-tf-dsqa"
```

This command initializes Terraform for a specific environment for Networking configuration. The ‘var-file’ flag  specifies the variable file containing common variables in ```${env}.tfvars``` and compute-specific variables in ```${env}-compute.tfvars```. The ‘-backend-config’ flag is used to configure the backend for storing the Terraform state remotely in the specified bucket. 

#### Table Reference:

Replace ```${env}```.tfvars and ```bucket-name``` in the commands with the corresponding related variable file from the table.

### Plan (Compute):-

Generate a Terraform execution plan for the Compute configuration using the following command:

```
sudo terraform plan -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-compute.tfvars
```

This command creates a Terraform execution plan for the provided environment for Compute configuration. It analyzes the Terraform configuration, compares it to the current state, and generates a list of operations that will be performed when applying the configuration. 

### Apply (Compute):-

Apply the Compute configuration using the following command:

```
sudo terraform apply -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-compute.tfvars
```

This command will create or modify the Terraform Configuration for provisioning the Compute resources as defined in the specified environment-specific file. It executes the planned actions from the Terraform plan and provisions the compute infrastructure. 

NOTE :- Before executing the ```‘terraform apply’``` command, carefully review the execution plan generated by ```‘terraform plan'``` to ensure that no resources are unintentionally deleted or disrupted during the deployment process.

### Destroy (Compute):-

To destroy the Compute infrastructure, use the following command:

```
sudo terraform apply -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-compute.tfvars
```

The terraform destroy command terminates resources managed by your Terraform . This command is the inverse of terraform apply in that it terminates all the compute resources specified in your Terraform state.

Note: Make sure before running the Terraform destroy command.



## Deployment for Helm:

First, Navigate to the deployment directory in the repository using this command:

```
cd /infra/us-east-1/helm
```

```helm``` is the deployment directory where all Helm configuration will be deployed using terraform.

### Initialize terraform for Helm configuration:-

Initialize Terraform for the specific environment for Helm configuration using the following command:

```
sudo terraform init -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-helm.tfvars  -backend-config="key=terraform/${env}-helm.tfstate" -backend-config="bucket=vtx-cibuilder-tf-dsqa"
```

This command initializes Terraform for a specific environment for Networking configuration. The ‘var-file’ flag  specifies the variable file containing common variables in ```${env}.tfvars``` and helm-specific variables in ```${env}-helm.tfvars```. The ‘-backend-config’ flag is used to configure the backend for storing the Terraform state remotely in the specified bucket. 

#### Table Reference:

Replace ```${env}```.tfvars and ```bucket-name```' in the commands with the corresponding related variable file from the table.

### Plan (Helm):-

Generate a Terraform execution plan for the Helm configuration using the following command:

```
sudo terraform plan -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-helm.tfvars
```

This command creates a Terraform execution plan for the provided environment for Helm configuration. It analyzes the Terraform configuration, compares it to the current state, and generates a list of operations that will be performed when applying the configuration.

### Apply (Helm):-

Apply the Helm configuration using the following command:

```
sudo terraform apply -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-helm.tfvars
```

This command will create or modify the Terraform Configuration for provisioning the Helm-specific resources as defined in the specified environment-specific file. It executes the planned actions from the Terraform plan and provisions the Helm infrastructure using Helm charts. 

NOTE :- Before executing the ```‘terraform apply’``` command, carefully review the execution plan generated by ```‘terraform plan'``` to ensure that no resources are unintentionally deleted or disrupted during the deployment process.

### Destroy (Helm):-

To destroy the Helm infrastructure, use the following command:

```
sudo terraform destroy -var-file ../config/${env}/${env}.tfvars -var-file ../config/${env}/${env}-helm.tfvars
```

The terraform destroy command terminates resources managed by your Terraform . This command is the inverse of terraform apply in that it terminates all the Helm resources specified in your Terraform state.

Note: Make sure before running the Terraform destroy command.
## Connecting to EKS-cluster:
### scenario 1 (Bastion to eks)
Follow these steps to connect the eks cluster to Bastion.

Step 1: Modify the following file by follow this path 
```
vim ~/.aws/credentials
```
Step 2: To connect to the EKS cluster, you first need to add the AWS profile. Add the AWS profile as follows and save the changes . 
```
[dev] #profile_name
role_arn = arn:aws:iam::account_id:role/VTX-CIBuilder-Product-dev #role_name replace it with role arn
credential_source = Ec2InstanceMetadata
region = eu-west-1
```
Step 3: To connect to the export AWS profile, use the following command.
```
export AWS_PROFILE= <profile_name>
```
Step 4: To connect to the eks-cluster , run the following command.
```
aws eks update-kubeconfig --name vxdv-eks-cluster --alias vxdv-eks-cluster --profile dev
```
After running this command, a new profile will be added to your  ~/.kube/config file and you will be able to access the eks cluster using the bastoin server. 

### scenario 2 (Local to eks)
Follow these steps to connect eks cluster to your local system. 


Step 1: Log into one login using required credentials.
```
https://finxera.onelogin.com/
```
Step 2: Click on the aws single sign on the logo , which will redirect to the aws signle sign for all aws accounts.

|env|AWS Account Name|
|:--|:---|
|dev|vtxpay-dev|
|qa|vtxpay-qa|

Step 3: Click on the relevant AWS  account, such as vtxpay-dev or vtxpay-qa. Two options will appear, one for the management console and the other for command line or programmatic access.
```
Management console  | command line or programmatic access
```
Step 4: Click on the command line or programmatic access option and copy these AWS environment variables.
```
export AWS_ACCESS_KEY_ID="ASI*********GG"
export AWS_SECRET_ACCESS_KEY="HjXFE*************7ERFy"
export AWS_SESSION_TOKEN="Vr0w********************+D5A=="
```
Step 5: Paste these environment variables into your terminal. After it, run this command to connect to the eks cluster.
```
aws eks --region us-east-1 update-kubeconfig --name <eks-cluster-name>
```
|env|AWS Account Name|
|:--|:---|
|dev|kevin-eks-cluster|
|dev|vxdv-eks-cluster|
|qa|vxqa-eks-cluster|

After running this command, a new profile will be added to your  ~/.kube/config file and you will be able to access the eks cluster using the local system.
