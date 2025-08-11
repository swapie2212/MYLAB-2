pipeline {
    agent any

    tools {
        maven 'MAVEN3'
    }

    environment {
        IMAGE_BACK = "swapie2212/devops-backend"
        IMAGE_FRONT = "swapie2212/devops-frontend"
        EKS_CLUSTER_NAME = "devops-demo-eks"
        AWS_REGION = "ap-south-1"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/swapie2212/MYLAB-2.git', branch: 'feature'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn -f backend/pom.xml clean install -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_LOGIN')]) {
                    withSonarQubeEnv('SonarQube') {
                        sh "mvn -f backend/pom.xml sonar:sonar -Dsonar.login=${SONAR_LOGIN}"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_BACK:latest -f backend/Dockerfile backend/'
                sh 'docker build -t $IMAGE_FRONT:latest -f frontend/Dockerfile frontend/'
            }
        }

        stage('Trivy Scan') {
            steps {
                sh 'trivy image $IMAGE_BACK:latest'
                sh 'trivy image $IMAGE_FRONT:latest'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                    sh 'docker push $IMAGE_BACK:latest'
                    sh 'docker push $IMAGE_FRONT:latest'
                }
            }
        }

        stage('Publish to JFrog') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'jfrog-creds', usernameVariable: 'ART_USER', passwordVariable: 'ART_PASS')]) {
                    sh 'curl -u $ART_USER:$ART_PASS -T backend/target/demo-0.0.1-SNAPSHOT.jar "https://swapie2212.jfrog.io/artifactory/devops-generic-local/backend/demo-0.0.1-SNAPSHOT.jar"'
                    }
            }
        }

        stage('Configure kubectl') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh 'aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION'
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    script {
                        sh 'kubectl apply -f k8s/mysql-deployment.yaml'
                        sh 'kubectl wait --for=condition=ready pod -l app=mysql --timeout=60s'
                        sh 'kubectl apply -f k8s/backend-deployment.yaml'
                        sh 'kubectl apply -f k8s/frontend-deployment.yaml'
                        sh 'kubectl apply -f k8s/service.yaml'
                    }
                }
            }
        }

        stage('Install Monitoring') {
            steps {
                // Add Helm repos and update
                sh 'helm repo add prometheus-community https://prometheus-community.github.io/helm-charts'
                sh 'helm repo add grafana https://grafana.github.io/helm-charts'
                sh 'helm repo update'

                // Install Prometheus and Grafana with values
                sh 'helm upgrade --install prometheus prometheus-community/prometheus -f helm/prometheus-grafana/prometheus-values.yaml'
                sh 'helm upgrade --install grafana grafana/grafana -f helm/prometheus-grafana/grafana-values.yaml'

                // Deploy Grafana dashboard ConfigMap after Grafana is installed
                sh 'kubectl apply -f helm/prometheus-grafana/grafana-dashboard-configmap.yaml'
            }
        }
    }
}
