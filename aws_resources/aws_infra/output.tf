# EKS Cluster Outputs
output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes server version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "eks_cluster_certificate_authority_data" {
  description = "Nested attribute containing certificate-authority-data for your cluster. This is the base64 encoded certificate data required to communicate with your cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster. On 1.14 or later, this is the 'Additional security groups' in the EKS console"
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.eks_cluster_role.name
}

output "eks_cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "eks_cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by the EKS cluster on 1.14 or later. Referred to as 'Cluster security group' in the EKS console"
  value       = module.eks.cluster_primary_security_group_id
}

# EKS Node Group Outputs
output "eks_node_group_name" {
  description = "The name of the EKS node group"
  value       = aws_eks_node_group.tasky.node_group_name
}

output "eks_node_group_arn" {
  description = "The Amazon Resource Name (ARN) of the node group"
  value       = aws_eks_node_group.tasky.arn
}

output "eks_node_group_status" {
  description = "The status of the EKS node group"
  value       = aws_eks_node_group.tasky.status
}

output "eks_node_group_version" {
  description = "The Kubernetes version of the EKS node group"
  value       = aws_eks_node_group.tasky.version
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "The DNS name of the application load balancer"
  value       = aws_lb.app_alb.dns_name
}

# MongoDB Outputs
output "mongodb_instance_id" {
  description = "The ID of the MongoDB instance"
  value       = aws_instance.mongodb.id
}

output "mongodb_private_ip" {
  description = "The private IP address of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "mongodb_connection_string" {
  description = "The connection string for MongoDB"
  value       = "mongodb://appuser:apppassword@${aws_instance.mongodb.private_ip}:27017/mydatabase"
}

# S3 Bucket Outputs
output "mongodb_backup_bucket_name" {
  description = "The name of the S3 bucket for MongoDB backups"
  value       = aws_s3_bucket.mongodb_backup.bucket
}

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}
