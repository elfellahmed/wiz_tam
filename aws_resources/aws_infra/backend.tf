terraform {
  backend "s3" {
    bucket = "simo-wiz-tam-tfstate-bucket"
    key = "./terraform.tfstate"
    region = "eu-central-1"
  }
}