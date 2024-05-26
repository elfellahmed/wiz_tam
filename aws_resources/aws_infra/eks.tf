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
  vpc_id          = aws_vpc.main_vpc.id
  subnet_ids      = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  enable_cluster_creator_admin_permissions = true
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
  tags = {
    Name    = "tasky-eks-cluster"
    Project = "wiz"
  }
}

# EKS Managed Node Group
resource "aws_eks_node_group" "tasky" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "tasky"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"

  remote_access {
    ec2_ssh_key = aws_key_pair.eks_key_pair.key_name
    source_security_group_ids = [aws_security_group.eks_worker_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonS3ReadOnlyAccess,
  ]

  tags = {
    Name    = "tasky-eks-node-group"
    Project = "wiz"
  }
}
