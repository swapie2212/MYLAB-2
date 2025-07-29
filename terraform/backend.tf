terraform {
  backend "s3" {
    bucket = "mylab-statefile-bucket"
    key    = "eks/terraform.tfstate"
    region = "ap-south-1"
  }
}