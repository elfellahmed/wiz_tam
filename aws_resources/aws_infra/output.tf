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

output "mongodb_private_ip" {
  description = "The private IP address of the MongoDB instance"
  value       = aws_instance.mongodb.private_ip
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
  value       = module.eks.eks_managed_node_groups["default"].id
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.app_lb.dns_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}
