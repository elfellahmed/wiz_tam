resource "aws_vpc_endpoint" "ec2" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "ec2:*",
        "Resource": "*"
      }
    ]
  }
  EOF

  tags = {
    Name = "ec2-endpoint"
    Project = "wiz"
  }
}

resource "aws_vpc_endpoint" "eks" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${var.region}.eks"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "ec2:*",
        "Resource": "*"
      }
    ]
  }
  EOF
  
  tags = {
    Name = "eks-endpoint"
    Project = "wiz"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "ec2:*",
        "Resource": "*"
      }
    ]
  }
  EOF
  
  tags = {
    Name = "ecr-api-endpoint"
    Project = "wiz"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "ec2:*",
        "Resource": "*"
      }
    ]
  }
  EOF
  
  tags = {
    Name = "ecr-dkr-endpoint"
    Project = "wiz"
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "ec2:*",
        "Resource": "*"
      }
    ]
  }
  EOF
  
  tags = {
    Name = "sts-endpoint"
    Project = "wiz"
  }
}

resource "aws_vpc_endpoint" "elasticloadbalancing" {
  vpc_id       = aws_vpc.main_vpc.id
  vpc_endpoint_type = "Interface"
  service_name = "com.amazonaws.${var.region}.elasticloadbalancing"
  subnet_ids   = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "ec2:*",
        "Resource": "*"
      }
    ]
  }
  EOF
  
  tags = {
    Name = "elb-endpoint"
    Project = "wiz"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_route_table.id,
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "s3-endpoint"
    Project = "wiz"
  }
}
