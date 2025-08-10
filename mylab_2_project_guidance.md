# MYLAB-2 Project: Build and Execution Guidance

This document provides a step-by-step guide for building and executing the **MYLAB-2** project using Terraform, Ansible, Jenkins, Docker, and Kubernetes.

---

## 📌 Prerequisites

1. **Create an S3 Bucket**

   - Purpose: To store the Terraform state file.
   - Action: Update the bucket name and key path in the `terraform` backend configuration.

2. **Create EC2 Key Pair**

   - Manually generate a key pair in AWS.
   - Update the key name in the Terraform configuration.

---

## 🚀 Execution Guidance

### 1. Infrastructure Creation (Terraform)

Navigate to the Terraform directory:

```bash
cd MYLAB-2/terraform
```

Run the following commands:

```bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

This process will:

- Create an EKS cluster with 2 worker nodes.
- Create an EC2 instance (DevOps-Host) for Jenkins, SonarQube, Docker, and CLI tools.
- Create required Security Groups and networking.

---

### 2. Configuration Management (Ansible)

After Terraform finishes:

#### i. Update Ansible Inventory

- Edit `MYLAB-2/ansible/inventory.ini`:
  - Replace `<DevOps-Host-IP>` with the public IP of the created EC2 instance.
  - Replace `<key-file>` with the path to your PEM key file.

#### ii. Copy PEM File

Place your `.pem` file in your WSL machine under `~/.ssh/`.
chmod 400 ~/.ssh/mylab-key.pem

#### iii. Run the Playbook

Navigate to the Ansible directory:

```bash
cd MYLAB-2/ansible
ansible-playbook -i inventory.ini playbook.yml
```

> ⚠️ Note: On first run, Jenkins plugin installation may be skipped due to missing credentials. Manually login to Jenkins using `admin` as username and password, then re-run the playbook.

---


sudo sysctl -w vm.max_map_count=262144
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
docker restart sonarqube


### 3. Manual Jenkins Configuration

After Jenkins and SonarQube installation:

1. **Maven Setup**

   - Manage Jenkins → Global Tool Configuration
   - Add Maven:
     - Name: `MAVEN3`
     - Version: `3.9.6`
     - Check: "Install Automatically"

2. **Add Jenkins Credentials**

   - AWS Credentials
     - Kind: AWS Credentials
     - Access Key, Secret Key
     - ID: `aws-credentials`
   - DockerHub Credentials
     - Kind: Username & Password
     - Use DockerHub username and token
     - ID: `dockerhub-creds`
   - JFrog Credentials
     - Kind: Username & Password
     - Use JFrog username and token
     - ID: `jfrog-creds`
   - Sonar Token
     - Kind: Secret Text
     - Token generated from Sonar UI
     - ID: `SONAR_TOKEN`

3. **Sonar URL**

   - Access Sonar at: `http://<DevOps-Host-IP>:9000`

4. **JFrog Path**

   - Use the following in your Jenkins pipeline for publishing:
     ```
     https://swapie2212.jfrog.io/artifactory/devops-generic-local/backend/demo-0.0.1-SNAPSHOT.jar
     ```

---

### 4. CI/CD Pipeline for Build and Deployment

1. **Create a New Jenkins Pipeline Job**

   - Use pipeline script from source or paste your `Jenkinsfile`.

2. **Run the Pipeline**

   - This will:
     - Build the Spring Boot project
     - Perform SonarQube analysis
     - Scan image with Trivy
     - Push Docker image to DockerHub
     - Deploy to EKS

3. **Monitoring with Grafana**

   - Monitor EKS cluster resources via Prometheus & Grafana.

---

## ✅ Summary Checklist

| Task                                | Status |
| ----------------------------------- | ------ |
| S3 Bucket Created & Terraform Setup | ✅      |
| Key Pair Created                    | ✅      |
| Terraform Infra Deployed            | ✅      |
| Ansible Inventory Updated           | ✅      |
| Ansible Playbook Executed           | ✅      |
| Jenkins Configured Manually         | ✅      |
| Jenkins Pipeline Created & Run      | ✅      |
| Monitoring Setup (Grafana)          | ✅      |

---

For any questions or configuration issues, feel free to review log outputs or validate infrastructure via AWS Console.

---

Happy DevOps-ing! 🚀



1. 🔧 Make EKS Cluster Endpoint Public (temporarily for testing)

In the AWS Console:

    Go to EKS > Your Cluster > Networking

    Look for API Server Endpoint Access

    Select:

        ✅ Public Access

        ✅ Allow access from your Jenkins EC2 IP/CIDR

    Important: This opens your EKS control plane to the internet — restrict access to only your Jenkins IP range (not 0.0.0.0/0).