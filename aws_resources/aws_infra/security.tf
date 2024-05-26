
# Create EKS Key Pair
resource "aws_key_pair" "eks_key_pair" {
  key_name   = var.eks_key_name
  public_key = file(var.public_eks_key_path)
}

# Create MongoDB Key Pair
resource "aws_key_pair" "mongodb_key_pair" {
  key_name   = var.mongodb_key_name
  public_key = file(var.public_mongodb_key_path)
}

# Security Group for MongoDB EC2 instance
resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb-sg"
  description = "Security group for MongoDB instance"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
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
    Name    = "mongodb-sg"
    Project = "wiz"
    "kubernetes.io/cluster/tasky-eks-cluster" = "shared"
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main_vpc.id

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
    Name    = "alb-sg"
    Project = "wiz"
    "kubernetes.io/cluster/tasky-eks-cluster" = "shared"
  }
}

# Security Group for EKS Control Plane
resource "aws_security_group" "eks_control_plane_sg" {
  name        = "eks-control-plane-sg"
  description = "EKS Control Plane Security Group"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow worker nodes to communicate with control plane"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_subnet_1.cidr_block, aws_subnet.private_subnet_2.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "kubernetes.io/cluster/tasky-eks-cluster" = "shared"
  }
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "eks_worker_sg" {
  name        = "eks-worker-sg"
  description = "EKS Worker Nodes Security Group"
  vpc_id      = aws_vpc.main_vpc.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "kubernetes.io/cluster/tasky-eks-cluster" = "shared"
    Project = "wiz"
  }
}
resource "aws_security_group_rule" "eks_worker_ingress_control_plane" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_control_plane_sg.id
  security_group_id        = aws_security_group.eks_worker_sg.id
  description              = "Allow communication with control plane"
}

resource "aws_security_group_rule" "eks_worker_ingress_worker" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_sg.id
  security_group_id        = aws_security_group.eks_worker_sg.id
  description              = "Allow communication between worker nodes"
}

resource "aws_security_group_rule" "eks_worker_ingress_app" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_worker_sg.id
  description       = "Allow application-specific traffic"
}

#SG for VPC Endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc_endpoints-sg"
  description = "VPC Endpoints Security Group"
  vpc_id      = aws_vpc.main_vpc.id

  tags = {
    Name    = "vpc-endpoint-sg"
    Project = "wiz"
  }
}

resource "aws_security_group_rule" "vpc_endpoint_sg_rule_1" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.10.0.0/16"]
  security_group_id = aws_security_group.vpc_endpoint_sg.id
}

resource "aws_security_group_rule" "vpc_endpoint_sg_rule_2" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.10.0.0/16"]
  security_group_id = aws_security_group.vpc_endpoint_sg.id
}

resource "aws_security_group_rule" "vpc_endpoint_sg_rule_3" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["10.10.0.0/16"]
  security_group_id = aws_security_group.vpc_endpoint_sg.id
}

resource "aws_security_group_rule" "vpc_endpoint_sg_rule_4" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc_endpoint_sg.id
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
