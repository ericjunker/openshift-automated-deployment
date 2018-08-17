node {
    stage('Build Tasks') {
        openshiftBuild bldCfg: 'openshift-tasks', 
        env: [[name: 'MAVEN_MIRROR_URL', value: 'http://nexus.opentlc-shared.svc.cluster.local:8081/repository/maven-all-public']], namespace: 'tasks', showBuildLogs: 'true', verbose: 'false',waitTime: '', waitUnit: 'sec'
        openshiftVerifyBuild bldCfg: 'openshift-tasks', checkForTriggeredDeployments: 'false', namespace: 'tasks', verbose: 'false', waitTime: ''
    }
    stage('Tag Image') {
        openshiftTag alias: 'false', destStream: 'openshift-tasks', destTag: '${BUILD_NUMBER}', destinationAuthToken: '', destinationNamespace: 'tasks',
        namespace: 'tasks', srcStream: 'openshift-tasks', srcTag: 'latest', verbose: 'false'
    }
    stage('Deploy new image') {
        openshiftDeploy depCfg: 'openshift-tasks', namespace: 'tasks', verbose: 'false', waitTime: '', waitUnit: 'sec'
    openshiftVerifyDeployment depCfg: 'openshift-tasks', namespace: 'tasks', replicaCount: '1', verbose: 'false', verifyReplicaCount: 'true', waitTime: '', waitUnit: 'sec'
    openshiftVerifyService namespace: 'tasks', svcName: 'openshift-tasks', verbose: 'false'
    }
}