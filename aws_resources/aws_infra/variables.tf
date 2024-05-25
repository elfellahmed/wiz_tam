variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the key pair"
  default     = "ssh-eks-key"
}

variable "public_key_path" {
  description = "The path to the public key file to use for the EC2 key pair"
  type        = string
  default     = "~/.ssh/ssh-eks-key.pub"
}