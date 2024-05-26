variable "region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

#variable "mongodb_key_name" {
#  description = "The name of the SSH key pair for the MongoDB instance"
#  default = "ssh-mongodb-key"
#}

#variable "public_mongodb_key_path" {
#  description = "The path to the public key file to use for the MongoDB key pair"
#  type        = string
#  default     = "~/.ssh/ssh-mongodb-key.pub"
#}

variable "eks_key_name" {
  description = "Name of the key pair"
  default     = "ssh-eks-key"
}

variable "public_eks_key_path" {
  description = "The path to the public key file to use for the EKS key pair"
  type        = string
  default     = "~/.ssh/ssh-eks-key.pub"
}