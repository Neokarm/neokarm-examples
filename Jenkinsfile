pipeline {
    agent {
        node {
            label 'jenkinsSlave'
        }
    }
    options {
        timeout(time: 120, unit: 'MINUTES')
        ansiColor('xterm')
        timestamps()
    }
    stage('sonarqube') {
        when {
            anyOf {
                branch 'master'
                branch 'test'
                expression { GIT_BRANCH ==~ /^PR-.+/ }
            }
        }
        options {
            timeout(time: 10, unit: 'MINUTES')
        }
        steps {
            sh "skipper --build-container-tag ${env.GIT_COMMIT} make sonar"
        }
    }
}
