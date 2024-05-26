terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.51.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
  }  
  backend "s3" {
    bucket = "simo-wiz-tam-tfstate-bucket-eu-west-1"
    key = "./terraform.tfstate"
    region = "eu-west-1"
  }
}