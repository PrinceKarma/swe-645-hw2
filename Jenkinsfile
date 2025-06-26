pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "princekarma"
        IMAGE_NAME = "swe645-hw2-webapp"
        IMAGE_TAG = "latest"
        GITHUB_REPO = "PrinceKarma/swe-645-hw2"
        DEPLOYMENT_YAML = "k8/deployment.yaml"
        SERVICE_YAML = "k8/service.yaml"
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: "https://github.com/${GITHUB_REPO}.git"
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}")
                    dockerImage.tag("${env.BUILD_NUMBER}")
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'DockerCreds') {
                        dockerImage.push("${IMAGE_TAG}")
                        dockerImage.push("${env.BUILD_NUMBER}")
                    }
                }
            }
        }
        stage('Update Kubernetes Deployment') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'KubeCreds', variable: 'KUBECONFIG')]) {
                        sh """
                            sed -i 's|${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}|${DOCKERHUB_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER}|g' ${DEPLOYMENT_YAML}
                        """
                        sh "kubectl apply -f ${DEPLOYMENT_YAML}"
                        sh "kubectl apply -f ${SERVICE_YAML}"
                        sh "kubectl rollout status deployment/swe645-hw2-webapp"
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
            echo "Docker image ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER} deployed to Kubernetes"
        }
        failure {
            echo 'Pipeline failed. Please check the logs for errors.'
        }
        always {
            script {
                try {
                    sh "docker rmi ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} || true"
                    sh "docker rmi ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER} || true"
                } catch (Exception e) {
                    echo "Docker cleanup failed: ${e.getMessage()}"
                }
            }
        }
    }
}