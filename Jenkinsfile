pipeline {
  agent {
    label 'X86-64-MULTI'
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '60'))
    parallelsAlwaysFailFast()
  }
  // Configuration for the variables used for this specific repo
  environment {
    BUILDS_DISCORD=credentials('build_webhook_url')
    GITHUB_TOKEN=credentials('github_token')
    EXT_RELEASE = '2.35' // change glibc version here
    IG_USER = 'imagegenius'
    IG_REPO = 'docker-glibc-builder'
    DOCKERHUB_IMAGE = 'imagegenius/glibc-builder'
  }
  stages {
    stage("Set ENV Variables"){
      steps{
        script{
          env.IG_RELEASE = sh(
            script: '''curl -sL https://api.github.com/repos/${IG_USER}/${IG_REPO}/releases/latest | jq -r '.tag_name' || : ''',
            returnStdout: true).trim()
          env.GITHUB_DATE = sh(
            script: '''date '+%Y-%m-%dT%H:%M:%S%:z' ''',
            returnStdout: true).trim()
          env.COMMIT_SHA = sh(
            script: '''git rev-parse HEAD''',
            returnStdout: true).trim()
        }
        script{
          env.IG_RELEASE_NUMBER = sh(
            script: '''echo ${IG_RELEASE} |sed 's/^.*-ig//g' ''',
            returnStdout: true).trim()
        }
        script{
          env.IG_TAG_NUMBER = sh(
            script: '''#!/bin/bash
                       tagsha=$(git rev-list -n 1 ${IG_RELEASE} 2>/dev/null)
                       if [ "${tagsha}" == "${COMMIT_SHA}" ]; then
                         echo ${IG_RELEASE_NUMBER}
                       elif [ -z "${GIT_COMMIT}" ]; then
                         echo ${IG_RELEASE_NUMBER}
                       else
                         echo $((${IG_RELEASE_NUMBER} + 1))
                       fi''',
            returnStdout: true).trim() 
        }
        script{
          env.META_TAG = env.EXT_RELEASE + '-ig' + env.IG_TAG_NUMBER
          env.IMAGE = env.DOCKERHUB_IMAGE
        }
      }
    }
    stage ('Create GitHub Release') {
      steps {
        echo "Pushing New tag for current commit ${META_TAG}"
        sh '''curl -H "Authorization: token ${GITHUB_TOKEN}" -X POST https://api.github.com/repos/${IG_USER}/${IG_REPO}/git/tags \
        -d '{"tag":"'${META_TAG}'",\
             "object": "'${COMMIT_SHA}'",\
             "message": "Tagging Release '${EXT_RELEASE}'-ig'${IG_TAG_NUMBER}' to main",\
             "type": "commit",\
             "tagger": {"name": "ImageGenius Jenkins","email": "ci@imagegenius.io","date": "'${GITHUB_DATE}'"}}' '''
        echo "Pushing New release for Tag"
        sh '''#!/bin/bash
              echo "Updating to glibc `${EXT_RELEASE}`" > releasebody.json
              echo '{"tag_name":"'${META_TAG}'",\
                     "target_commitish": "main",\
                     "name": "'${META_TAG}'",\
                     "body": "**Changes:**\\n\\n' > start
              printf '","draft": false,"prerelease": false}' >> releasebody.json
              paste -d'\\0' start releasebody.json > releasebody.json.done
              curl -H "Authorization: token ${GITHUB_TOKEN}" -X POST https://api.github.com/repos/${IG_USER}/${IG_REPO}/releases -d @releasebody.json.done'''
      }
    }
    stage('Build-Multi') {
      parallel {
        stage('Build X86') {
          steps {
            echo 'Build Image'
            sh "docker build --tag ${IMAGE}:amd64-${META_TAG} ."
            echo 'Build glibc'
            sh '''#!/bin/bash
                  docker run \
                    --rm --env EXT_RELEASE --env STDOUT=1 \
                    ${IMAGE}:amd64-${META_TAG} > glibc-bin-${EXT_RELEASE}-x86_64.tar.gz
               '''
            echo 'Upload files to Github release'
            sh '''#!/bin/bash
                  sha512sum glibc-bin-${EXT_RELEASE}-x86_64.tar.gz > glibc-bin-${EXT_RELEASE}-x86_64.tar.gz.sha512sum
                  RELEASE_ID=$(curl -s "https://api.github.com/repos/${IG_USER}/${IG_REPO}/releases/tags/${META_TAG}" | jq '.id')
                  for file in "tar.gz" "tar.gz.sha512sum"; do
                    UPLOAD_FILE=glibc-bin-${EXT_RELEASE}-x86_64.${file}
                    curl -H "Authorization: token ${GITHUB_TOKEN}" -H "Content-Type: application/gzip" --data-binary "@${UPLOAD_FILE}" "https://uploads.github.com/repos/${IG_USER}/${IG_REPO}/releases/${RELEASE_ID}/assets?name=${UPLOAD_FILE}"
                  done
               '''
            echo 'Cleanup'
            sh '''#!/bin/bash
                  for file in "tar.gz" "tar.gz.sha512sum"; do
                    DELETEFILE=glibc-bin-${EXT_RELEASE}-x86_64.${file}
                    rm ${DELETEFILE}
                  done
                  docker rmi \
                    ${IMAGE}:amd64-${META_TAG} || :
               '''
          }
        }
        stage('Build ARM64') {
          agent {
            label 'ARM64'
          }
          steps {
            echo "Running on node: ${NODE_NAME}"
            echo 'Build Image'
            sh "docker build --tag ${IMAGE}:arm64v8-${META_TAG} ."
            echo 'Build glibc'
            sh '''#!/bin/bash
                  docker run \
                    --rm --env EXT_RELEASE --env STDOUT=1 \
                    ${IMAGE}:arm64v8-${META_TAG} > glibc-bin-${EXT_RELEASE}-aarch64.tar.gz
               '''
            echo 'Upload files to Github release'
            sh '''#!/bin/bash
                  sha512sum glibc-bin-${EXT_RELEASE}-aarch64.tar.gz > glibc-bin-${EXT_RELEASE}-aarch64.tar.gz.sha512sum
                  RELEASE_ID=$(curl -s "https://api.github.com/repos/${IG_USER}/${IG_REPO}/releases/tags/${META_TAG}" | jq '.id')
                  for file in "tar.gz" "tar.gz.sha512sum"; do
                    UPLOAD_FILE=glibc-bin-${EXT_RELEASE}-aarch64.${file}
                    curl -H "Authorization: token ${GITHUB_TOKEN}" -H "Content-Type: application/gzip" --data-binary "@${UPLOAD_FILE}" "https://uploads.github.com/repos/${IG_USER}/${IG_REPO}/releases/${RELEASE_ID}/assets?name=${UPLOAD_FILE}"
                  done
               '''
            echo 'Cleanup'
            sh '''#!/bin/bash
                  for file in "tar.gz" "tar.gz.sha512sum"; do
                    DELETEFILE=glibc-bin-${EXT_RELEASE}-aarch64.${file}
                    rm ${DELETEFILE}
                  done
                  docker rmi \
                    ${IMAGE}:arm64v8-${META_TAG} || :
               '''
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
                 "description": "**'${IG_REPO}'**\\n**Build**  '${BUILD_NUMBER}'\\n**Status:**  Success\\n**Job:** '${RUN_DISPLAY_URL}'\\n"}],\
                 "username": "Jenkins"}' ${BUILDS_DISCORD} '''
        }
        else {
          sh ''' curl -X POST -H "Content-Type: application/json" --data '{"avatar_url": "https://wiki.jenkins.io/JENKINS/attachments/2916393/57409617.png","embeds": [{"color": 16711680,\
                 "description": "**'${IG_REPO}'**\\n**Build**  '${BUILD_NUMBER}'\\n**Status:**  Failure\\n**Job:** '${RUN_DISPLAY_URL}'\\n"}],\
                 "username": "Jenkins"}' ${BUILDS_DISCORD} '''
        }
      }
    }
    cleanup {
      cleanWs()
    }
  }
}
