import groovy.transform.Field
import groovy.text.StreamingTemplateEngine
@Field def pipelineStatus = ['unstable': 0, 'failure': 0, 'aborted': 0]

/**
 * This method is used to initialize user prompt to review and provide approval to proceed
 */

def reviewAndConfirm(String stageName) {
    echo "\u001B[1;35mReview the plan for ${stageName} stage and provide input\u001B[0m"
    
    // Assuming the downstream job with noAutoApproveParamsMap has completed successfully
    // Introducing a user prompt after the job completes
    def userInput = input message: "Review the plan for ${stageName} stage and confirm if you want to proceed?", ok: 'Proceed', parameters: [booleanParam(defaultValue: false, description: 'Click "Proceed" to continue, or "Abort" to stop', name: 'CONFIRM')]
    
    if (userInput == true) {
        echo "\u001B[32mUser confirmed to proceed.\u001B[0m"
        return true
    } else {
        echo "\u001B[31mUser aborted the operation.\u001B[0m"
        return false
    }
}

/**
 * This method is used to a jobs with one common parameter array and one specific
 */
 def triggerDownstreamJob(String jobName, List commonParamsArray, List additionalParamsArray) {
    // Prepare parameters
    def parametersList = []

    // Add common parameters
    parametersList.addAll(commonParamsArray)

    // Add additional parameters, if provided
    if (additionalParamsArray) {
        parametersList.addAll(additionalParamsArray)
    }

    // Call the downstream job with the merged parameters and environment variables
        build job: jobName, parameters: parametersList
}


/**
 * This method is used to a job with one common parameter array and one specific as a stage
 */
def triggerDownstreamStageJob(String jobName, List commonParamsArray, List additionalParamsArray,String jobDisplayName) {
    // Prepare parameters
    def parametersList = []

    //parameters
    parametersList.addAll(commonParamsArray)

    // Add additional parameters, if provided
    if (additionalParamsArray) {
        parametersList.addAll(additionalParamsArray)
    }

    stage(jobDisplayName) {
        try {
            build job: jobName, parameters: parametersList
        } catch (Exception e) {
            // If the job fails, throw an exception
            error "Job ${jobName} failed for ${jobDisplayName}"
        }
    }
}


/**
 * This method is used to run  parallel jobs with one common parameter array and one specific
 */
def triggerMultipleDownstreamJobs(List<Map> jobParamsList, List commonParamsArray) {
    def jobs = [:]
    
    jobParamsList.each { paramsMap ->
        def jobName = paramsMap.jobName
        def jobDisplayName = paramsMap.jobDisplayName
        def additionalParamsArray = paramsMap.additionalParamsArray ?: []

        def parametersList = []
        parametersList.addAll(commonParamsArray)
        parametersList.addAll(additionalParamsArray)

        jobs[jobDisplayName] = {
            build job: jobName, parameters: parametersList
        }
    }

    parallel jobs
}

/**
 * This method is used to run multiple parallel jobs in a stage with common parameters
 */
def triggerParallelStageJobs(jobs, stageDesc, parms, skipFailure) {
    def branches = [:]
    jobs.each {
        branches[it] = {
            buildJob(it, 1, parms, pipelineStatus, skipFailure)
        }
    }
    stage (stageDesc) {
        parallel branches
    }
}

/**
 * This method sets variables builtBy and 
 */
def setBuiltByAndWorkspace() {
    try {
        def cause = currentBuild.rawBuild.getCause(hudson.model.Cause$UserIdCause)
        builtBy = cause ? cause.getUserName() : "Scheduler"
        workspace = "${env.WORKSPACE}"
        echo "builtBy: ${builtBy}"
        echo "Workspace: ${workspace}"
    } catch (Exception e) {
        workspace = ""
        builtBy = ""
        echo "Exception while setting builtBy and Workspace: ${e.message}"
        throw e
    }
}

/**
 * This method returns a string with the template filled with groovy variables
 */
def emailTemplate(params) {
    // Get current working directory
    def templateFilePath = "${env.WORKSPACE}/infra-scripts/groovy/templates/${env.ARCHITECTURE}-email.html.groovy"
    def fileContents = readFile(templateFilePath).trim()
    def engine = new StreamingTemplateEngine()
    return engine.createTemplate(fileContents).make(params).toString()
}

/**
 * This method send an email generated with data from Jenkins
 * @param buildStatus String with job result
 * @param emailRecipients Array with emails: emailRecipients = []
 */

def notifyEmail(buildStatus, emailRecipients, workspace, builtBy, scripts_branch, config_branch, architecture, environment, operation, statusText) {

    try {

        // def userConfigFile = workspace + '/Configs/' + stack_name + '/Stack/Infra-user-input.conf'
        // String fileContents = new File(userConfigFile).getText('UTF-8')
        // def newFile = new File("Infra-user-input.conf")
        // newFile.write(fileContents)
        def icon = "✅"
        def statusSuccess = true
        def hasArtifacts = true

        if(buildStatus != "SUCCESS") {
            icon = "❌"
            statusSuccess = false
            hasArtifacts = false
        }

        def body = emailTemplate([
            "jenkinsText"      :   "Build Facts:",
            "jenkinsJobName"   :   env.JOB_NAME,
            "jenkinsStatus"    :   statusText,
            "jenkinsUrl"       :   env.BUILD_URL,
            "builtBy"          :   builtBy,
            "branch"           :   scripts_branch,
            "configBranch"     :   config_branch,
            "architecture"     :   architecture,
            "operation"        :   operation,
            "environment"      :   environment,
            "statusSuccess"    :   statusSuccess,
            "wikiUrl"          :   "WikiLink"
        ]);

        emailext to: emailRecipients.join(","),
            subject: "${icon} [ ${env.JOB_NAME} ] [ ${environment} ] [ ${operation} ] [${env.BUILD_NUMBER}] - ${buildStatus} ",
            body: body,
            mimeType: 'text/html',
            attachLog: false,
            attachmentsPattern: '**/logos/*-logo.png'
    } catch (e){
        println "ERROR SENDING EMAIL ${e}"
    }
}

def doHealthChecks(info, jobStatus) {
    if ( info.size() == 1 ) {
        def hostPort = info[0]['host'] + ":" + info[0]['port']
        stage (info[0]['tag'] + " " + hostPort) {
            buildJob(info[0]['job'], 1, [[$class: 'StringParameterValue', name: 'HOSTPORT', value: hostPort]], jobStatus)
        }
    } else {
        def branches = [:]
        info.each {
            def hostPort = it['host'] + ":" + it['port']
            branches[it['tag'] + " " + hostPort] = {
                buildJob(it['job'], 1, [[$class: 'StringParameterValue', name: 'HOSTPORT', value: hostPort]], jobStatus)
            }
        }
        stage ("Health Checks") {
            parallel branches
        }
    }
}

def healthCheckInfo(tag, job, port, info) {
    sh "../../scripts/ips-via-AWS.sh '${tag}'"
    def workspace = pwd()
    echo workspace
    ips = readFile(workspace + '/ips.txt').split("\n")
    ips.each {
        println it
    }

    for (int i = 0; i < ips.size(); i++) {
        info << ['tag': tag, 'job': job, 'host': ips[i], 'port': port]
    }

    info.each {
        echo "${it}"
    }
}

// two funcions below are currently only called by buildout-all-jenkinsfile

def doHealthChecksFromData(data) {
    sh "pwd"
    sh "rm -f ips.txt"
    def info = []
    data.each {
       echo "${it['tag']} ${it['job']} ${it['port']}"
       healthCheckInfo(it['tag'], it['job'], it['port'], info)
    }
    doHealthChecks(info, pipelineStatus)
}

// todo: pass in consolidated data that has job + parms
// currently, same parms are passed to all jobs in the single caller
def doParallelStage(jobs, stageDesc, parms) {
    def branches = [:]
    jobs.each {
        branches[it] = {
            buildJob(it, 1, parms, pipelineStatus)
        }
    }
    stage (stageDesc) {
        parallel branches
    }
}

def doParallelStageScriptJobs(jobs, stageDesc, parms, cmd, env, label, jobStatus) {
    def branches = [:]

    jobs.each {
        branches[it] = {
            buildJob(it, 1, parms, pipelineStatus)
        }
    }

    branches[label] = {
        withEnv(env) {
            sh(returnStdout: false, script: cmd)
        }
    }
    try {
        stage (stageDesc) {
            parallel branches
        }
    } catch (Exception  e) {
        def eMsg = e.getMessage();
        echo "*** Exception:doParallelStageScriptJob: ${eMsg}"
        if ( eMsg == null ) {
            jobStatus.aborted = 1
            throw e
        }
        // *** hack until I can get at job status directly via result field on object?
        // or we do not attempt to aggregate and we simply fail the pipleine on exception?
        if ( eMsg.toLowerCase().contains("unstable")) {
            jobStatus.unstable = 1
            throw e
        } else if ( eMsg.toLowerCase().contains("failure")) {
            jobStatus.failure = 1
            throw e
        } else {
            //jobStatus.aborted = 1
            jobStatus.failure = 1
            throw e
        }
    }
}
def doParallelStageScriptJob(job, stageDesc, parms, cmd, env, label, jobStatus) {
    def branches = [:]

    branches[job] = {
        buildJob(job, 1, parms, pipelineStatus)
    }

    branches[label] = {
        withEnv(env) {
            sh(returnStdout: false, script: cmd)
        }
    }
    try {
        stage (stageDesc) {
            parallel branches
        }
    } catch (Exception  e) {
        def eMsg = e.getMessage();
        echo "*** Exception:doParallelStageScriptJob: ${eMsg}"
        if ( eMsg == null ) {
            jobStatus.aborted = 1
            throw e
        }
        // *** hack until I can get at job status directly via result field on object?
        // or we do not attempt to aggregate and we simply fail the pipleine on exception?
        if ( eMsg.toLowerCase().contains("unstable")) {
            jobStatus.unstable = 1
            throw e
        } else if ( eMsg.toLowerCase().contains("failure")) {
            jobStatus.failure = 1
            throw e
        } else {
            //jobStatus.aborted = 1
            jobStatus.failure = 1
            throw e
        }
    }
}


// new function that has both jobs+parms in data
def doParallelStageFromData(data, stageDesc) {
    def branches = [:]
    data.each {
        def job = it['job']
        def parms = it['parms']
        branches[job] = {
            buildJob(job, 1, parms, pipelineStatus)
        }
    }
    try {
        stage (stageDesc) {
            parallel branches
        }
    } catch (Exception  e) {
        def eMsg = e.getMessage();
        echo "*** Exception:doParallelStageScriptJob: ${eMsg}"
        if ( eMsg == null ) {
            jobStatus.aborted = 1
            throw e
        }
        // *** hack until I can get at job status directly via result field on object?
        // or we do not attempt to aggregate and we simply fail the pipleine on exception?
        if ( eMsg.toLowerCase().contains("unstable")) {
            jobStatus.unstable = 1
            throw e
        } else if ( eMsg.toLowerCase().contains("failure")) {
            jobStatus.failure = 1
            throw e
        } else {
            //jobStatus.aborted = 1
            jobStatus.failure = 1
            throw e
        }
    }
}


def doParallelShellStageFromData(approved=true, data, stageDesc, jobStatus) {
    def branches = [:]
    data.each {
        def cmd = it['cmd']
        def env = it['env']
        if ( approved == 'approved' ) {
            Collections.replaceAll(env, 'AUTO_APPROVE=false', 'AUTO_APPROVE=approved')
        }
        def label = it['label']
        branches[label] = {
            withEnv(env) {
                sh(returnStdout: false, script: cmd)
            }
        }
    }
    try {
        stage (stageDesc) {
            parallel branches
        }
    } catch (Exception  e) {
        def eMsg = e.getMessage();
        echo "*** Exception:doParallelShellStageFromData: ${eMsg}"
        if ( eMsg == null ) {
            jobStatus.aborted = 1
            throw e
        }
        // *** hack until I can get at job status directly via result field on object?
        // or we do not attempt to aggregate and we simply fail the pipleine on exception?
        if ( eMsg.toLowerCase().contains("unstable")) {
            jobStatus.unstable = 1
            throw e
        } else if ( eMsg.toLowerCase().contains("failure")) {
            jobStatus.failure = 1
            throw e
        } else {
            //jobStatus.aborted = 1
            jobStatus.failure = 1
            throw e
        }
    }
}

def doShellStageFromData(cmd, environ, stageDesc, jobStatus) {
    /*
    def newEnv = environ.collect()
    script {
        def currEnv = env.getEnvironment()
        currEnv.each {
            key, value -> println("${key} = ${value}");
            newEnv.add("${key}=${value}")
        }
        println(newEnv)
    }*/

    try {
        stage (stageDesc) {
            ansiColor('xterm'){
                withEnv(environ) {
                    sh(returnStdout: false, script: cmd)
                }
            }
            /* so we can display output serially
            Process p = cmd.execute(newEnv, null)
            def outS = new StringBuffer();
            def errS = new StringBuffer();
            p.waitForProcessOutput(outS, errS)
            println outS.toString();
            println errS.toString();*/
        }
    } catch (Exception  e) {
        def eMsg = e.getMessage();
        echo "*** Exception:doShellStageFromData: ${eMsg}"
        if ( eMsg == null ) {
            jobStatus.aborted = 1
            throw e
        }
        // *** hack until I can get at job status directly via result field on object?
        // or we do not attempt to aggregate and we simply fail the pipleine on exception?
        if ( eMsg.toLowerCase().contains("unstable")) {
            jobStatus.unstable = 1
            throw e
        } else if ( eMsg.toLowerCase().contains("failure")) {
            jobStatus.failure = 1
            throw e
        } else {
            //jobStatus.aborted = 1
            jobStatus.failure = 1
            throw e
        }
    }
}

def buildJob(job, rethrow, parms, jobStatus) {
    def prop = env.JOB_NAME + "_INIT_TRACKING"
    if ( env[prop] ) {
         echo "Environment property: " + prop + " set. Terminate pipeline for Init Tracking ONLY run, e.g., done when running new env migration job"
         throw new Exception("INIT_TRACKING RUN ONLY")
    }

    try {
        if ( parms == null) {
            build job
        } else {
            build job: job,
            parameters: parms
            }
        } catch (e) {
            def eMsg = e.getMessage();
            echo "*** Exception:buildJob: ${eMsg}"
            if ( eMsg == null ) {
                jobStatus.aborted = 1
                throw e
            }
            // *** hack until I can get at job status directly via result field on object?
            // or we do not attempt to aggregate and we simply fail the pipleine on exception?
            if ( eMsg.toLowerCase().contains("unstable")) {
                jobStatus.unstable = 1
                if ( rethrow == 1 ) {
                    throw e
                }
            } else if ( eMsg.toLowerCase().contains("failure")) {
                jobStatus.failure = 1
                if ( rethrow == 1 ) {
                    throw e
                }
            } else {
                jobStatus.aborted = 1
                throw e
            }
        }
}

return this
