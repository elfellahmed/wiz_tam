provider "aws" {
  region = var.region
}

# Create a custom VPC
resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "wiz-vpc"
    Project = "wiz"
  }
}

# Create public subnets for load balancer
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "public-subnet-a"
    Project = "wiz"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "public-subnet-b"
    Project = "wiz"
  }
}

# Create private subnets for application and database
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "private-subnet-a"
    Project = "wiz"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.4.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "private-subnet-b"
    Project = "wiz"
  }
}

# Create an internet gateway for the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
    Project = "wiz"
  }
}

# Create a route table for the public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
    Project = "wiz"
  }
}

# Associate the public subnets with the public route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Security group for the MongoDB instance
resource "aws_security_group" "mongodb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mongodb-sg"
    Project = "wiz"
  }
}

# Security group for the load balancer
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "lb-sg"
    Project = "wiz"
  }
}

# EC2 Instance for MongoDB
resource "aws_instance" "mongodb" {
  ami           = "ami-xyz"  # to be replaced by the right Mongo DB AMI
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_a.id
  security_groups = [aws_security_group.mongodb_sg.name]

  tags = {
    Name = "MongoDB"
    Project = "wiz"
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo apt-get update
            sudo apt-get install -y mongodb
            sudo systemctl start mongodb
            sudo systemctl enable mongodb
            EOF
}

# S3 Bucket for MongoDB Backups
resource "aws_s3_bucket_acl" "mongodb_backup_acl" {
  bucket = aws_s3_bucket.mongodb_backup.bucket
  acl    = "public-read"
}

resource "random_id" "bucket_id" {
  byte_length = 8
}


# EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "tasky-eks-cluster"
  cluster_version = "1.21"
  vpc_id          = aws_vpc.main.id
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

# EKS Node Group
module "eks_node_group" {
  source             = "terraform-aws-modules/eks/aws//modules/node_groups"
  cluster_name       = module.eks.cluster_id
  cluster_version    = "1.21"
  node_group_name    = "tasky-eks-node-group"
  node_group_subnets = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  node_group_version = "1.21"
  desired_capacity   = 2
  max_capacity       = 3
  min_capacity       = 1
  instance_type      = "t2.medium"
  key_name           = var.key_name  # Replace with your key pair name
}


# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "app-lb"
    Project = "wiz"
  }
}

# Target Group for the Load Balancer
resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    interval            = 30
    path                = "/"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "app-tg"
    Project = "wiz"
  }
}

# Listener for the Load Balancer
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

    tags = {
    Name = "app-tg"
    Project = "wiz"
  }
}

# Kubernetes Ingress Resource
resource "kubernetes_ingress" "app_ingress" {
  metadata {
    name      = "app-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
    }
  }

  spec {
    rule {
      http {
        path {
          path    = "/*"
          backend {
            service_name = "app-service"
            service_port = "8080"
          }
        }
      }
    }
  }
}