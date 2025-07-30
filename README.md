# MYLAB-2: DevOps 3-Tier Project

## Tech Stack
- Spring Boot (Backend)
- MySQL (Database)
- HTML (Frontend)
- Jenkins + SonarQube + Trivy (CI/CD)
- Kubernetes + Helm (Deployment)
- AWS + Terraform (Infra-as-Code)

## Setup Guide
1. **Provision Infra:**
   ```bash
   cd terraform && terraform init && terraform apply
   ```
2. **Ansible EC2 Provisioning:**
   ```bash
   cd ansible && ansible-playbook -i inventory.ini playbook.yml
   ```
3. **Build & Deploy (CI/CD):**
   Jenkins will:
   - Run tests & sonar
   - Build docker image
   - Trivy scan
   - Push to DockerHub & JFrog
   - Deploy to EKS

4. **Monitor:**
   Prometheus & Grafana via Helm.