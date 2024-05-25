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