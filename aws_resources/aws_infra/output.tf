output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_a_id" {
  description = "The ID of the public subnet A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "The ID of the public subnet B"
  value       = aws_subnet.public_b.id
}

output "private_subnet_a_id" {
  description = "The ID of the private subnet A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "The ID of the private subnet B"
  value       = aws_subnet.private_b.id
}

output "mongodb_instance_id" {
  description = "The ID of the MongoDB instance"
  value       = aws_instance.mongodb.id
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket for MongoDB backups"
  value       = aws_s3_bucket.mongodb_backup.bucket
}

output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_node_group_id" {
  description = "The ID of the EKS node group"
  value       = module.eks_node_group.node_group_id
}
