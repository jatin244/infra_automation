pipeline {
    agent {
        kubernetes {
            inheritFrom 'agent-c7i-1c-2gb-infra'
        }
    }
    options {
        ansiColor('xterm')
    }
    
    stages {
        stage('Apply or Destroy Infrastructure') {
            steps {
                script {
                    def capitalizedOperation = env.OPERATION.toUpperCase()
                    if (env.OPERATION != 'apply' && env.OPERATION != 'destroy') {
                        error "\u001B[31mERROR: Invalid value for OPERATION: ${capitalizedOperation}. It must be either 'apply' or 'destroy'.\u001B[0m"
                    } else {
                        echo "\u001B[32mOperation input is valid. Proceeding with requested infrastructure action. - ${capitalizedOperation}\u001B[0m"
                    }
                     if (env.OPERATION == 'apply') {
                        executeInfraStages()
                    } else if (env.OPERATION == 'destroy') {
                        executeInfraStages()
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline execution completed"
        }
    }
}

def executeInfraStages() {
        def pipelineHelper = load "${env.WORKSPACE}/infra-scripts/groovy/helper/PipelineHelper.groovy"
        def statusText = ""
        echo "ENVIRONMENT - ${env.ENVIRONMENT} "
        echo "INFRA_SCRIPTS_BRANCH - ${env.INFRA_SCRIPTS_BRANCH} "
        echo "INFRA_CONFIG_BRANCH - ${env.INFRA_CONFIG_BRANCH} "
        echo "PRODUCT - ${env.PRODUCT} "
        echo "AUTO_APPROVE - ${env.AUTO_APPROVE} "
        echo "OPERATION - ${env.OPERATION} "

        // Define common parameters
        def environmentParams = [
            [$class: 'StringParameterValue', name: 'ENVIRONMENT', value: "${env.ENVIRONMENT}"],
            [$class: 'StringParameterValue', name: 'INFRA_SCRIPTS_BRANCH', value: "${env.INFRA_SCRIPTS_BRANCH}"],
            [$class: 'StringParameterValue', name: 'INFRA_CONFIG_BRANCH', value: "${env.INFRA_CONFIG_BRANCH}"],
            [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: "${env.AUTO_APPROVE}"],
            [$class: 'StringParameterValue', name: 'OPERATION', value: "${env.OPERATION}"],
            [$class: 'StringParameterValue', name: 'PRODUCT', value: "${env.PRODUCT}"],
            [$class: 'StringParameterValue', name: 'ARCHITECTURE', value: 'payment'],
            [$class: 'StringParameterValue', name: 'ENABLE_TF_LOGGING', value: 'true']
        ]

        // Additional parameters for each job (optional)
        def jobAutoApproveParamsMap = [
            [jobName: 'Infra-Terraform-Operator',
                jobDisplayName: 'Networking',
                additionalParamsArray: [
                [$class: 'StringParameterValue', name: 'STAGE', value: 'networking'],
                [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'true']
            ]],
            [jobName: 'Infra-Terraform-Operator',
                jobDisplayName: 'Compute',,
                additionalParamsArray: [
                [$class: 'StringParameterValue', name: 'STAGE', value: 'compute'],
                [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'true']
            ]],
            [jobName: 'Infra-Terraform-Operator',
                jobDisplayName: 'Helm',
                additionalParamsArray: [
                [$class: 'StringParameterValue', name: 'STAGE', value: 'helm'],
                [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'true']
            ]],
        ]
        def jobNoAutoApproveParamsMap = [
            [jobName: 'Infra-Terraform-Operator',
                jobDisplayName: 'Networking',
                additionalParamsArray: [
                [$class: 'StringParameterValue', name: 'STAGE', value: 'networking'],
                [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'true']
            ]],
            [jobName: 'Infra-Terraform-Operator',
                jobDisplayName: 'Compute',
                additionalParamsArray: [
                [$class: 'StringParameterValue', name: 'STAGE', value: 'compute'],
                [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'false']
            ]],
            [jobName: 'Infra-Terraform-Operator',
                jobDisplayName: 'Helm',
                additionalParamsArray: [
                [$class: 'StringParameterValue', name: 'STAGE', value: 'helm'],
                [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'false']
            ]],
        ]

        try {
            
                        // Triggering network stage without auto approve
                        if (AUTO_APPROVE != 'true') {
                            echo "Running parallel for plan"
                            pipelineHelper.triggerMultipleDownstreamJobs(jobNoAutoApproveParamsMap, environmentParams)

                            // Review and confirm
                            if (!pipelineHelper.reviewAndConfirm('plan')) {
                                currentBuild.result = 'ABORTED'
                                return
                            }
                        }

                        // Triggering network stage with auto approve
                        echo "Running networking stage with job for execution"
                        pipelineHelper.triggerMultipleDownstreamJobs(jobAutoApproveParamsMap, environmentParams)


        } catch (Exception e) {
            echo "An error occurred: ${e.message}"
        } finally {
            // Clean up actions, if any
        }
}
