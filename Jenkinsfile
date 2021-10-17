/* import shared library */
@Library('slackNotifier')_

pipeline{

    environment{
        IMAGE_NAME = "sadofrazer/static-webapp"
        IMAGE_TAG = "latest"
        CONTAINER_NAME = "static-webapp"
        PRODUCTION_HOST = "35.175.174.149"
    }

    agent none

    stages{

        stage ('Build Image') {
            agent any
            steps{
                script{
                    sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} . '
                }
            }
        }

        stage ('Try to clean Container') {
            agent any
            steps{
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script{
                        sh'''
                           docker stop ${CONTAINER_NAME}
                           docker rm ${CONTAINER_NAME}
                        '''
                    }
                }
            }
        }

        stage('Try to delete container on prod env if exist') {
            agent any
            when{
                expression{ GIT_BRANCH == 'origin/master'}
            }
            steps{
                withCredentials([sshUserPrivateKey(credentialsId: "ssh-ec2-cloud", keyFileVariable: 'keyfile', usernameVariable: 'NUSER')]) {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        script{ 
                            sh'''
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${PRODUCTION_HOST} -C \'docker rm -f static-webapp-prod \'
                            '''
                        }
                    }
                }
            }
        }
   
        stage ('Run container based on builded image') {
            agent any
            steps{
                script{
                    sh'''
                       docker run -d --name ${CONTAINER_NAME} -p 80:80 ${IMAGE_NAME}:${IMAGE_TAG}
                       sleep 5
                       
                    '''
                }
            }
        }

        stage ('Test image') {
            agent any
            steps{
                script{
                    sh'''
                       curl http://172.17.0.1 | grep -q "Dimension"
                    '''
                }
            }
        }

        stage ('Clean Container') {
            agent any
            steps{
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script{
                        sh'''
                           docker stop ${CONTAINER_NAME}
                           docker rm ${CONTAINER_NAME}
                        '''
                    }
                }
            }
        }

        stage('Push Image on Dockerhub') {
            agent any
            when{
                expression{ GIT_BRANCH == 'origin/master'}
            }
            steps{
                withCredentials([usernamePassword(credentialsId: 'docker_login', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        script{
                            dockerhubPush ${IMAGE_NAME} ${IMAGE_TAG} ${USERNAME}${PASSWORD}
                        }
                    }
                }
            }
        }

        stage('Deploy app on EC2-cloud Production') {
            agent any
            when{
                expression{ GIT_BRANCH == 'origin/master'}
            }
            steps{
                withCredentials([sshUserPrivateKey(credentialsId: "ssh-ec2-cloud", keyFileVariable: 'keyfile', usernameVariable: 'NUSER')]) {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        script{ 
                            sh'''
                                ssh -o StrictHostKeyChecking=no -i ${keyfile} ${NUSER}@${PRODUCTION_HOST} -C \'docker run -d --name static-webapp-prod -p 80:80 sadofrazer/static-webapp\'
                            '''
                        }
                    }
                }
            }
        }

    }

    post{
        always {
            script {
                slackNotifier currentBuild.result
            }  
        }  
    }
}