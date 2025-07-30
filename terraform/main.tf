terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "devops-vpc"
  cidr = "172.31.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["172.31.1.0/24", "172.31.2.0/24"]
  public_subnets  = ["172.31.101.0/24", "172.31.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.29.0" # Downgraded from 19.20.0 to avoid unsupported fields in provider

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.medium"]
    }
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.0.0"

  identifier        = "devops-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  db_subnet_group_name   = module.vpc.database_subnet_group
  subnet_ids             = module.vpc.private_subnets

  publicly_accessible = false
  skip_final_snapshot = true
}

resource "aws_instance" "devops_host" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.devops_sg.id]
  subnet_id                   = aws_subnet.public_1.id
  associate_public_ip_address = true

  tags = {
    Name = "DevOps-Host"
  }
}

resource "aws_security_group" "devops_sg" {
  name        = "devops-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_subnet" "public_1" {
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}