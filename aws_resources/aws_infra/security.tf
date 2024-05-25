
# Create EC2 Key Pair
resource "aws_key_pair" "eks_key_pair" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
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

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}