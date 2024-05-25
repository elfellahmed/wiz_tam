provider "aws" {
  region = var.region
}

# Create EC2 Key Pair
resource "aws_key_pair" "eks_key_pair" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
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

resource "aws_iam_role" "mongodb_role" {
  name = "MongoDBAdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mongodb_role_policy" {
  role       = aws_iam_role.mongodb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "mongodb_instance_profile" {
  name = "MongoDBInstanceProfile"
  role = aws_iam_role.mongodb_role.name
}

# EC2 Instance for MongoDB
resource "aws_instance" "mongodb" {
  ami           = "ami-02e136e904f3da870"  # CentOS 6 - outdated and dont receive sec updates anymore
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_a.id
  security_groups = [aws_security_group.mongodb_sg.name]
  iam_instance_profile        = aws_iam_instance_profile.mongodb_instance_profile.name

  tags = {
    Name = "MongoDB"
    Project = "wiz"
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y
            sudo yum install -y epel-release
            sudo yum install -y wget
            sudo yum install aws-cli

            # Add MongoDB 3.6 repository
            cat <<EOF2 | sudo tee /etc/yum.repos.d/mongodb-org-3.6.repo
            [mongodb-org-3.6]
            name=MongoDB Repository
            baseurl=https://repo.mongodb.org/yum/redhat/6/mongodb-org/3.6/x86_64/
            gpgcheck=1
            enabled=1
            gpgkey=https://www.mongodb.org/static/pgp/server-3.6.asc
            EOF2

            # Install MongoDB 3.6
            sudo yum install -y mongodb-org

            # Start MongoDB and enable on boot
            sudo systemctl start mongod
            sudo systemctl enable mongod

            # Wait for MongoDB to start
            sleep 20

            # Create MongoDB admin user
            mongo --eval 'db.getSiblingDB("admin").createUser({user: "admin", pwd: "adminpassword", roles: [{role: "root", db: "admin"}]})'

            # Create MongoDB application user
            mongo --eval 'db.getSiblingDB("mydatabase").createUser({user: "appuser", pwd: "apppassword", roles: [{role: "readWrite", db: "mydatabase"}]})'

            # Enable MongoDB authentication
            sudo sed -i '/#security:/a\\  authorization: "enabled"' /etc/mongod.conf

            # Restart MongoDB to apply changes
            sudo systemctl restart mongod

            # Wait for MongoDB to start
            sleep 20

            # Output connection string to a file
            PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
            echo "mongodb://appuser:apppassword@$PRIVATE_IP:27017/mydatabase" > /home/ec2-user/mongodb_connection_string.txt
            
            cat <<'EOF3' > /home/ec2-user/mongo_backup.sh
            #!/bin/bash
            TIMESTAMP=\$(date +%F-%H%M)
            BACKUP_NAME="mongo-backup-\$TIMESTAMP"
            sudo mongodump --out /home/ec2-user/\$BACKUP_NAME
            aws s3 cp /home/ec2-user/\$BACKUP_NAME s3://${aws_s3_bucket.mongodb_backup.bucket}/\$BACKUP_NAME --recursive
            EOF3

            # Make backup script executable
            chmod +x /home/ec2-user/mongo_backup.sh

            # Schedule cron job for backups
            echo "0 0,12 * * * /home/ec2-user/mongo_backup.sh" | sudo tee -a /etc/crontab
            EOF
}

# S3 Bucket for MongoDB Backups
resource "aws_s3_bucket" "mongodb_backup" {
  bucket = "mongodb-backup-bucket-${random_id.bucket_id.hex}"

  tags = {
    Name = "mongodb-backup-bucket"
    Project = "wiz"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 8
}

# Set bucket ACL to private (default)
resource "aws_s3_bucket_acl" "mongodb_backup_acl" {
  bucket = aws_s3_bucket.mongodb_backup.bucket
  acl    = "private"
}

# Bucket Policy to allow public read access and listing
resource "aws_s3_bucket_policy" "mongodb_backup_policy" {
  bucket = aws_s3_bucket.mongodb_backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.mongodb_backup.arn}/*"
      },
      {
        Sid       = "PublicListBucket"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = "${aws_s3_bucket.mongodb_backup.arn}"
      }
    ]
  })
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
  desired_capacity   = 2
  max_capacity       = 3
  min_capacity       = 1
  instance_type      = "t2.medium"
  key_name           = var.key_name
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# Create Kubernetes Secret for MongoDB connection string
resource "kubernetes_secret" "mongodb_connection_string" {
  metadata {
    name = "mongodb-connection-string"
  }

  data = {
    connection-string = "mongodb://appuser:apppassword@${aws_instance.mongodb.private_ip}:27017/mydatabase"
  }

  type = "Opaque"
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "tasky-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "tasky-app-lb"
    Project = "wiz"
  }
}

# Target Group for the Load Balancer
resource "aws_lb_target_group" "app_tg" {
  name        = "tasky-app-tg"
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
    Name = "tasky-app-tg"
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
    Name = "tasky-app-tg"
    Project = "wiz"
  }
}

# Kubernetes Deployment
resource "kubernetes_manifest" "my_app_deployment" {
  manifest = yamldecode(file("${path.module}/../components/manifests/app-manifest.yaml"))
}

# Kubernetes Service
resource "kubernetes_manifest" "my_app_service" {
  manifest = yamldecode(file("${path.module}/../components/manifests/service-manifest.yaml"))
}

# Kubernetes Ingress
resource "kubernetes_manifest" "my_app_ingress" {
  manifest = yamldecode(file("${path.module}/../components/manifests/ingress-manifest.yaml"))
}