terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30.0"
    }
  }

  backend "s3" {
    bucket = "webinax"
    key    = "eks/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region
}

################################################################################
# VPC MODULE
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "devops-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

################################################################################
# EKS MODULE
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_types   = ["t3.medium"]
    }
  }
}

################################################################################
# SECURITY GROUPS
################################################################################

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow MySQL access within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "MySQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# DevOps Host Security Group
resource "aws_security_group" "devops_sg" {
  name        = "devops-sg"
  description = "Allow SSH and Web Traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-sg"
  }
}

################################################################################
# DEVOPS HOST (EC2)
################################################################################
resource "aws_instance" "devops_host" {
  ami                         = "ami-03f4878755434977f" # Amazon Linux 2023 in ap-south-1
  instance_type               = "t3.large"
  key_name                    = var.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "DevOps-Host"
  }

  depends_on = [module.vpc]
}


################################################################################
# RDS Subnet Group
################################################################################

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "devops-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "devops-rds-subnet-group"
  }
}

################################################################################
# RDS MODULE
################################################################################
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.0"

  identifier           = "devops-mysql"
  engine               = "mysql"
  engine_version       = "8.0"
  major_engine_version = "8.0"
  family               = "mysql8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  subnet_ids             = module.vpc.private_subnets

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "devops-mysql-db"
  }

  depends_on = [module.vpc]
}

################################################################################
# OUTPUTS
################################################################################
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}


