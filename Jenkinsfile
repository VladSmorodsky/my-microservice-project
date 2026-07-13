pipeline {
    agent {
        kubernetes {
            label 'kaniko'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.19.0-debug
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
  - name: git
    image: alpine/git:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-config
    secret:
      secretName: aws-ecr-credentials
"""
        }
    }

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '590183992909'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_NAME = 'my-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        HELM_REPO_URL = 'github.com/VladSmorodsky/my-microservice-project'
        HELM_REPO_BRANCH = 'main'
        VALUES_FILE_PATH = 'helm/django-app/values.yaml'
    }

    stages {
        stage('Checkout Source') {
            steps {
                echo "=========================================="
                echo "Stage: Checkout Source Code"
                echo "=========================================="
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                container('kaniko') {
                    script {
                        echo "Building image: ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                        sh """
                            /kaniko/executor \
                              --context=${WORKSPACE}/django \
                              --dockerfile=${WORKSPACE}/django/Dockerfile \
                              --destination=${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
                              --destination=${ECR_REGISTRY}/${IMAGE_NAME}:latest \
                              --cache=true \
                              --verbosity=info
                        """
                        echo "✅ Image built successfully!"
                    }
                }
            }
        }

        stage('Update Helm Values') {
            steps {
                container('git') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'github-credentials',
                            usernameVariable: 'GIT_USER',
                            passwordVariable: 'GIT_TOKEN'
                        )
                    ]) {
                        script {
                            sh """
                                apk add --no-cache sed

                                git config --global user.email "jenkins@ci.local"
                                git config --global user.name "Jenkins CI"

                                git clone https://\${GIT_USER}:\${GIT_TOKEN}@${HELM_REPO_URL} helm-charts
                                cd helm-charts
                                git checkout ${HELM_REPO_BRANCH}

                                sed -i "s|tag:.*|tag: ${IMAGE_TAG}|g" ${VALUES_FILE_PATH}

                                git diff ${VALUES_FILE_PATH}

                                if ! git diff --quiet ${VALUES_FILE_PATH}; then
                                    git add ${VALUES_FILE_PATH}
                                    git commit -m "ci: update ${IMAGE_NAME} image tag to ${IMAGE_TAG}"
                                    git push origin ${HELM_REPO_BRANCH}
                                    echo "✅ Successfully updated and pushed to ${HELM_REPO_BRANCH}"
                                fi
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo """
╔════════════════════════════════════════╗
║   PIPELINE COMPLETED SUCCESSFULLY! ✅   ║
╠════════════════════════════════════════╣
║ Image: ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
║ Build: #${BUILD_NUMBER}
╚════════════════════════════════════════╝
            """
        }
        failure {
            echo "Pipeline FAILED! Check logs for details."
        }
    }
}
