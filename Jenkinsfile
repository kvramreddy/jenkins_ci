pipeline {
  agent none

  options {
    ansiColor('xterm')
    timestamps()
    timeout(time: 2, unit: 'HOURS')

  }
  environment {
        GIT_LFS_SKIP_SMUDGE = '1'
        HOME = '/home/h4re1'
  }

  parameters {
      string(description: 'Git tag on which to base build', name: 'h4ciTag', defaultValue: '2.1.1.6.devel')
      string(description: 'Publish to Artifactory repo', name: 'h4ciPublisherRepo', defaultValue: 'sandbox-local')
  }

  stages {
    stage('STEP1'){
      agent { label 'el-7' }
      steps {
        sh '''
          ./upload_to_artifactory.sh "${h4ciTag}" "${h4ciPublisherRepo}"
        '''
      }

    }
  }
  post {
    success {

      emailext (
        subject: "SUCCESSFUL: Release build ${h4ciTag}",
        body: """<p>SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
        <br> </br>
        <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>""",
        to: 'vkorpolu@tetrationanalytics.com'
      )
    }
  }
}
