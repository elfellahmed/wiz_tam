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

# EC2 Instance for MongoDB
resource "aws_instance" "mongodb" {
  ami           = "ami-02e136e904f3da870"  # CentOS 6 - outdated and dont receive sec updates anymore
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
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

module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  role_name                        = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks.cluster_id]
  
}

# EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
  cluster_name    = "tasky-eks-cluster"
  cluster_version = "1.29"
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
}
  vpc_id          = aws_vpc.main.id
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  eks_managed_node_groups = {
    tasky = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = var.instance_type
      capacity_type    = "ON_DEMAND"
      key_name         = var.key_name
    }
  }
  enable_cluster_creator_admin_permissions = true
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
