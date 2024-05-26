# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "tasky-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name    = "tasky-load-balancer"
    Project = "wiz"
  }
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"

  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name    = "app-tg"
    Project = "wiz"
    "kubernetes.io/cluster/tasky-eks-cluster" = "shared"
  }
}

# Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  tags = {
    Name    = "http-listener"
    Project = "wiz"
  }
}

# EC2 Instance for MongoDB
resource "aws_instance" "mongodb" {
  ami           = "ami-42e84f2d"  # outdated  Centos 6
  instance_type = var.instance_type
  #key_name      = var.mongodb_key_name
  subnet_id     = aws_subnet.private_subnet_1.id
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

