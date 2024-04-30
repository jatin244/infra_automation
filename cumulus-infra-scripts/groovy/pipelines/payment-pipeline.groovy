pipeline {
    agent {
        kubernetes {
            inheritFrom env.LABEL_POD_TEMPLATE
        }
    }
    options {
        ansiColor('xterm')
    }
        environment {
        // Declare global variable
        statusText = '<strong>Pipeline Progress Status:</strong><br />'
    }
    stages {
        stage('Execute Infrastructure Stages as per input') {
            steps {
                script {
                    def capitalizedOperation = env.OPERATION.toUpperCase()
                    currentBuild.description = "${env.ENVIRONMENT} - ${env.ENVIRONMENT} - ${env.OPERATION} - ${env.ARCHITECTURE}(arch)"
                    if (env.OPERATION != 'apply' && env.OPERATION != 'destroy') {
                        error "\u001B[31mERROR: Invalid value for OPERATION: ${capitalizedOperation}. It must be either 'apply' or 'destroy'.\u001B[0m"
                    } else {
                        echo "\u001B[32mOperation input is valid. Proceeding with requested infrastructure action. - ${capitalizedOperation}\u001B[0m"
                    }
                     if (env.OPERATION == 'apply') {
                        statusText = statusText.concat("<strong>Execute networking stage:</strong>")
                        executeInfraStage('networking')
                        statusText = statusText.concat(" - <span style='color: #00d06d;'>OK</span><br />")
                        statusText = statusText.concat("<strong>Execute compute stage:</strong>")
                        executeInfraStage('compute')
                        statusText = statusText.concat(" - <span style='color: #00d06d;'>OK</span><br />")
                        statusText = statusText.concat("<strong>Execute helm stage:</strong>")
                        executeInfraStage('helm')
                        statusText = statusText.concat(" - <span style='color: #00d06d;'>OK</span><br />")
                    } else if (env.OPERATION == 'destroy') {
                        statusText = statusText.concat("<strong>Execute helm stage:</strong>")
                        executeInfraStage('helm')
                        statusText = statusText.concat(" - <span style='color: #00d06d;'>OK</span><br />")
                        statusText = statusText.concat("<strong>Execute compute stage:</strong>")
                        executeInfraStage('compute')
                        statusText = statusText.concat(" - <span style='color: #00d06d;'>OK</span><br />")
                        statusText = statusText.concat("<strong>Execute networking stage:</strong>")
                        executeInfraStage('networking')
                        statusText = statusText.concat(" - <span style='color: #00d06d;'>OK</span><br />")
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                container('jnlp') {
                    stage('Email') {
                    def emailRecipients = env.EMAIL_RECIPIENTS
                    def emailRecipientsOnCall = env.EMAIL_RECIPIENTS_ONCALL
                    def emailRecipientsGlobal = env.EMAIL_RECIPIENTS_GLOBAL
                    def pipelineHelper = load "${env.WORKSPACE}/infra-scripts/groovy/helper/PipelineHelper.groovy"
                    pipelineHelper.setBuiltByAndWorkspace()
                    emailRecipients = "$emailRecipients," + ""
                    def status = currentBuild.result
                    if ( emailRecipients != null && status != null && status != "ABORTED" ) {
                        if ( status == "FAILURE" ) {
                            emailRecipients = "$emailRecipients," + "$emailRecipientsOnCall," + "$emailRecipientsGlobal"
                        }
                    echo "*** FINAL EMAIL_RECIPIENTS: $emailRecipients"
                    pipelineHelper.notifyEmail(status, [emailRecipients], workspace, builtBy, env.INFRA_SCRIPTS_BRANCH, env.INFRA_CONFIG_BRANCH, env.ARCHITECTURE, env.ENVIRONMENT, env.OPERATION, statusText)
                    }

                    }
                    echo "Pipeline execution completed"
                }
            }
        }
        
        success {
            script {
                currentBuild.result = 'SUCCESS';
                }
            }
        
        failure {
            script {
                currentBuild.result = 'FAILURE';
                statusText = statusText.concat(" - <span style='color: #FF0082;'>FAILED</span><br />")
                }
            }
        
        unstable('Build marked as unstable') {
            script {
                currentBuild.result = 'UNSTABLE';
                statusText = statusText.concat(" - <span style='color: #FF0082;'>UNSTABLE</span><br />")
                }
            }
        
        aborted {
            script {
                currentBuild.result = 'ABORTED';
                }
            }
    }
}

def executeInfraStage(String stageName) {
    def pipelineHelper = load "${env.WORKSPACE}/infra-scripts/groovy/helper/PipelineHelper.groovy"
    def environmentParams = [
        [$class: 'StringParameterValue', name: 'ENVIRONMENT', value: env.ENVIRONMENT],
        [$class: 'StringParameterValue', name: 'INFRA_SCRIPTS_BRANCH', value: env.INFRA_SCRIPTS_BRANCH],
        [$class: 'StringParameterValue', name: 'INFRA_CONFIG_BRANCH', value: env.INFRA_CONFIG_BRANCH],
        [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: env.AUTO_APPROVE],
        [$class: 'StringParameterValue', name: 'OPERATION', value: env.OPERATION],
        [$class: 'StringParameterValue', name: 'PRODUCT', value: env.PRODUCT],
        [$class: 'StringParameterValue', name: 'POST_INFRA_CONFIG', value: env.POST_INFRA_CONFIG],
        [$class: 'StringParameterValue', name: 'ARCHITECTURE', value: env.ARCHITECTURE],
        [$class: 'StringParameterValue', name: 'ENABLE_TF_LOGGING', value: env.ENABLE_TF_LOGGING]
    ]

    def autoApproveParamsMap = [
        'networking': [
            [$class: 'StringParameterValue', name: 'STAGE', value: 'networking'],
            [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'true']
        ],
        'compute': [
            [$class: 'StringParameterValue', name: 'STAGE', value: 'compute'],
            [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'true']
        ],
        'helm': [
            [$class: 'StringParameterValue', name: 'STAGE', value: 'helm'],
            [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'true']
        ]
    ]
    def noAutoApproveParamsMap = [
        'networking': [
            [$class: 'StringParameterValue', name: 'STAGE', value: 'networking'],
            [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'false']
        ],
        'compute': [
            [$class: 'StringParameterValue', name: 'STAGE', value: 'compute'],
            [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'false']
        ],
        'helm': [
            [$class: 'StringParameterValue', name: 'STAGE', value: 'helm'],
            [$class: 'StringParameterValue', name: 'AUTO_APPROVE', value: 'false']
        ]
    ]

    try {
        // Triggering stage without auto approve
        if (AUTO_APPROVE != 'true') {
            echo "\u001B[33mRunning $stageName stage with plan for ${env.OPERATION} operation\u001B[0m"
            def stageNameWithOperation = "${stageName}-${params.OPERATION}"
            pipelineHelper.triggerDownstreamStageJob('Infra-Terraform-Operator', environmentParams, noAutoApproveParamsMap[stageName], "${stageName}-${params.OPERATION}-plan")
            // Review and confirm
            if (!pipelineHelper.reviewAndConfirm(stageName)) {
                currentBuild.result = 'ABORTED'
                return
            }
        }

        // Triggering stage with auto approve
        echo "\u001B[33mRunning $stageName stage execution for ${env.OPERATION} operation\u001B[0m"
        pipelineHelper.triggerDownstreamStageJob('Infra-Terraform-Operator', environmentParams, autoApproveParamsMap[stageName], "${stageName}-${params.OPERATION}")
    } catch (Exception e) {
        echo "\u001B[31mAn error occurred:\u001B[0m ${e.message}"
        error "Aborted pipeline due to error in $stageName stage: ${e.message}"
    } finally {
        // Clean up actions, if any
    }
}
