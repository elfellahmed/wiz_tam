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

  eks_managed_node_groups = {
    tasky = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = var.instance_type
      capacity_type    = "ON_DEMAND"
      subnet_ids      = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
      key_name         = aws_key_pair.eks_key_pair.key_name
      iam_role_arn     = aws_iam_role.eks_node_role.arn
      allowed_security_group_ids = [aws_security_group.eks_worker_sg.id]
      #remote_access {
      #  ec2_ssh_key = "eks-terraform-key"
      #}
      depends_on = [
        aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
        aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.eks_node_AmazonS3ReadOnlyAccess,
      ] 
    }
  }
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