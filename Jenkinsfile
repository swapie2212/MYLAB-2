pipeline {
    agent any

    tools {
        maven 'MAVEN3'
    }

    environment {
        IMAGE = "swapie2212/devops-demo"
        EKS_CLUSTER_NAME = "mylab-eks"
        AWS_REGION = "ap-south-1"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/swapie2212/MYLAB-2.git', branch: 'main'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn -f backend/pom.xml clean install -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn -f backend/pom.xml sonar:sonar'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE:latest .'
            }
        }

        stage('Trivy Scan') {
            steps {
                sh 'trivy image $IMAGE:latest'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                    sh 'docker push $IMAGE:latest'
                }
            }
        }

        stage('Publish to JFrog') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'jfrog-creds', usernameVariable: 'ART_USER', passwordVariable: 'ART_PASS')]) {
                    sh 'curl -u $ART_USER:$ART_PASS -T target/demo-0.0.1-SNAPSHOT.jar "https://your-jfrog-url/artifactory/libs-release-local/demo-0.0.1-SNAPSHOT.jar"'
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
                sh 'kubectl apply -f k8s/deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
            }
        }

        stage('Install Monitoring') {
            steps {
                sh 'helm repo add prometheus-community https://prometheus-community.github.io/helm-charts'
                sh 'helm repo add grafana https://grafana.github.io/helm-charts'
                sh 'helm repo update'
                sh 'helm upgrade --install prometheus prometheus-community/prometheus -f helm/prometheus-grafana/prometheus-values.yaml'
                sh 'helm upgrade --install grafana grafana/grafana -f helm/prometheus-grafana/grafana-values.yaml'
            }
        }
    }
}
pipeline {
    agent any

    stages {
        stage('Trigger Jenkins Job') {
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/trigger-jenkins-job.yml',
                    inventory: 'ansible/inventory.ini',
                    extras: '-e "job_name=my-pipeline-job"'
                )
            }
        }
    }
}

    post {
        always {
            junit 'target/surefire-reports/*.xml'
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }