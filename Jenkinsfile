pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('DockerRegistryCreds')
        KUBECONFIG = credentials('KubeConfigCreds')
        DOCKER_IMAGE_NAME = "princekarma/swe645-hw2-webapp"
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout the source code from GitHub
                git 'https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY_NAME.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image
                    sh "docker build -t ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} ."
                    sh "docker tag ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER} ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    // Login to Docker Hub and push the image
                    sh "echo \$DOCKER_HUB_CREDENTIALS_PSW | docker login -u \$DOCKER_HUB_CREDENTIALS_USR --password-stdin"
                    sh "docker push ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker push ${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Apply the Kubernetes manifests
                    sh "kubectl apply -f deployment.yaml"
                    sh "kubectl apply -f service.yaml"
                    // Force a rolling update of the deployment
                    sh "kubectl set image deployment/swe645-hw2-webapp swe645-hw2-webapp-container=${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
                }
            }
        }
    }

    post {
        always {
            // Clean up the Docker image from the Jenkins agent
            sh "docker rmi ${DOCKER_IMAGE_NAME}:${env.BUILD_NUMBER}"
            sh "docker rmi ${DOCKER_IMAGE_NAME}:latest"
        }
    }
}