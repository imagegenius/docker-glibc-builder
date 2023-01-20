pipeline {
  agent {
    label 'MASTER'
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '60'))
    parallelsAlwaysFailFast()
  }
  parameters {
     string(defaultValue: '', description: 'glibc version', name: 'GLIBC_VERSION')
     string(defaultValue: '', description: 'release tag', name: 'RELEASE_TAG')
  }
  // Configuration for the variables used for this specific repo
  environment {
    BUILDS_DISCORD=credentials('build_webhook_url')
    GITHUB_TOKEN=credentials('github_token')
  }
  stages {
    stage("Set Version Tag"){
      steps {
        script{
          env.GIT_RELEASE = env.GLIBC_VERSION + "-" + env.RELEASE_TAG
          env.COMMIT_SHA = sh(
            script: '''git rev-parse HEAD''',
            returnStdout: true).trim()
          env.GITHUB_DATE = sh(
            script: '''date '+%Y-%m-%dT%H:%M:%S%:z' ''',
            returnStdout: true).trim()
        }
      }
    }
    stage ('Update/Verify GitHub Release') {
      steps {
        sh '''#!/bin/bash
              if [ -z "$GLIBC_VERSION" ]; then
                echo "Error: GLIBC_VERSION variable is not set."
                exit 1
              fi
           '''
        echo "Pushing New tag for current commit ${GIT_RELEASE}"
        sh '''curl -H "Authorization: token ${GITHUB_TOKEN}" -X POST https://api.github.com/repos/imagegenius/docker-glibc-builder/git/tags \
        -d '{"tag":"'${GIT_RELEASE}'",\
             "object": "'${COMMIT_SHA}'",\
             "message": "Tagging Release '${COMMIT_SHA}' to main",\
             "type": "commit",\
             "tagger": {"name": "ImageGenius Jenkins","email": "ci@imagegenius.io","date": "'${GITHUB_DATE}'"}}' '''
        echo "Pushing New release for Tag"
        sh '''#! /bin/bash
              echo "Updating to ${GIT_RELEASE}" > releasebody.json
              echo '{"tag_name":"'${GIT_RELEASE}'",\
                     "target_commitish": "main",\
                     "name": "'${GIT_RELEASE}'",\
                     "body": "**ImageGenius Changes:**\\n\\n'${IG_RELEASE_NOTES}'\\n\\n**Remote Changes:**\\n\\n' > start
              printf '","draft": false,"prerelease": false}' >> releasebody.json
              paste -d'\\0' start releasebody.json > releasebody.json.done
              curl -H "Authorization: token ${GITHUB_TOKEN}" -X POST https://api.github.com/repos/imagegenius/docker-glibc-builder/releases -d @releasebody.json.done'''
      }
    }
    stage('Build-Multi') {
      matrix {
        axes {
          axis {
            name 'MATRIXARCH'
            values 'X86-64-MULTI', 'ARM64'
          }
        }
        stages {
          stage ('Compile glibc') {
            agent {
              label "${MATRIXARCH}"
            }
            steps {
              echo "Running on node: ${NODE_NAME}"
              echo 'Build Image'
              sh "docker build --tag iglocal/glibc-builder:latest ."
              echo 'Build glibc'
              sh '''#!/bin/bash
                    docker run \
                      --rm --env GLIBC_VERSION --env STDOUT=1 \
                      iglocal/glibc-builder:latest > glibc-bin-$GLIBC_VERSION-$(arch).tar.gz
                 '''
              echo 'Cleanup and upload glibc-bin-$GLIBC_VERSION-$(arch).tar.gz to Github release'
              sh '''#!/bin/bash
                    docker rmi \
                      iglocal/glibc-builder:latest
                    
                    sha512sum glibc-bin-$GLIBC_VERSION-$(arch).tar.gz > glibc-bin-$GLIBC_VERSION-$(arch).tar.gz.sha512sum
                    RELEASE_ID=$(curl -s "https://api.github.com/repos/imagegenius/docker-glibc-builder/releases/tags/$GIT_RELEASE" | jq '.id')

                    for i in "tar.gz" "tar.gz.sha512sum"; do
                      UPLOAD_FILE=glibc-bin-$GLIBC_VERSION-$(arch).$i
                      curl -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/gzip" --data-binary "@$UPLOAD_FILE" "https://uploads.github.com/repos/imagegenius/docker-glibc-builder/releases/$RELEASE_ID/assets?name=$UPLOAD_FILE"
                    done
                 '''
            }
          }
        }
      }
    }
  }
  post {
    always {
      script{
        if (currentBuild.currentResult == "SUCCESS"){
          sh ''' curl -X POST -H "Content-Type: application/json" --data '{"avatar_url": "https://wiki.jenkins.io/JENKINS/attachments/2916393/57409617.png","embeds": [{"color": 1681177,\
                 "description": "**docker-glibc-builder Build '${BUILD_NUMBER}' Results**\\n**Status:**  Success\\n**Job:** '${RUN_DISPLAY_URL}'\\n"}],\
                 "username": "Jenkins"}' ${BUILDS_DISCORD} '''
        }
        else {
          sh ''' curl -X POST -H "Content-Type: application/json" --data '{"avatar_url": "https://wiki.jenkins.io/JENKINS/attachments/2916393/57409617.png","embeds": [{"color": 16711680,\
                 "description": "**docker-glibc-builder Build '${BUILD_NUMBER}' Results**\\n**Status:**  failure\\n**Job:** '${RUN_DISPLAY_URL}'\\n"}],\
                 "username": "Jenkins"}' ${BUILDS_DISCORD} '''
        }
      }
    }
    cleanup {
      cleanWs()
    }
  }
}
