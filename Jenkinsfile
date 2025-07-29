pipeline {
    agent any

    environment {
        IMAGE = "yourdockerhubusername/devops-demo"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/swapie2212/MYLAB-2.git', branch: 'main'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
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
                    sh 'docker tag $IMAGE:latest $IMAGE:latest'
                    sh 'docker push $IMAGE:latest'
                }
            }
        }

        stage('Publish to JFrog') {
            steps {
                sh 'curl -u $ART_USER:$ART_PASS -T target/demo-0.0.1-SNAPSHOT.jar "https://your-jfrog-url/artifactory/libs-release-local/demo-0.0.1-SNAPSHOT.jar"'
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
                sh 'helm install prometheus prometheus-community/prometheus -f helm/prometheus-grafana/prometheus-values.yaml || echo "Prometheus already installed"'
                sh 'helm install grafana grafana/grafana -f helm/prometheus-grafana/grafana-values.yaml || echo "Grafana already installed"'
            }
        }
    }
}