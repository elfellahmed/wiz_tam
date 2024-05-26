resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  #dhcp_options_id      = aws_vpc_dhcp_options.main.id

  tags = {
    Name    = "wiz-vpc"
    Project = "wiz"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name    = "main-private-subnet-1"
    Project = "wiz"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/tasky-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name    = "main-private-subnet-2"
    Project = "wiz"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/tasky-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "main-public-subnet-1"
    Project = "wiz"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/tasky-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.10.4.0/24"
  availability_zone = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "main-public-subnet-2"
    Project = "wiz"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/tasky-eks-cluster" = "shared"
  }
}

/* resource "aws_vpc_dhcp_options" "main" {
  domain_name         = "${var.region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "main-dhcp-options"
    Project = "wiz"
  }
}

resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = aws_vpc.main_vpc.id‚‚
  dhcp_options_id = aws_vpc_dhcp_options.main.id
} */

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name    = "main-igw"
    Project = "wiz"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "main-public-route-table"
    Project = "wiz"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "10.10.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name    = "main-private-route-table"
    Project = "wiz"
  }
}

resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "null_resource" "aws_auth_configmap" {
  provisioner "local-exec" {
    command = <<EOF
    kubectl apply -f - <<-EOF2
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: aws-auth
      namespace: kube-system
    data:
      mapRoles: |
        - rolearn: ${aws_iam_role.eks_node_role.arn}
          username: system:node:{{EC2PrivateDNSName}}
          groups:
            - system:bootstrappers
            - system:nodes
    EOF2
    EOF
  }

  depends_on = [
    aws_eks_node_group.tasky,
    module.eks
  ]
}

# EC2 Instance Connect Endpoint
#resource "aws_ec2_instance_connect_endpoint" "ec2_instance_connect" {
#  security_group_ids = [aws_security_group.mongodb_sg.id]
#  subnet_id         = aws_subnet.public_subnet_1.id
#  tags = {
#    Name    = "ec2-instance-connect"
#    Project = "wiz"
#  }
#}