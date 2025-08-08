variable "aws_region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "devops-demo-eks"
}

variable "db_name" {
  default = "devopsdb"
}

variable "db_username" {
  default = "root"
}

variable "db_password" {
  default = "rootpassword" # Ideally use sensitive=true and store in Vault or AWS Secrets Manager
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = "DevOps"
}