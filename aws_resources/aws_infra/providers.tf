provider "aws" {
  region  = var.region
  profile = "iamadmin-prd"
}

# Kubernetes provider configuration
#provider "kubernetes" {
#  host                   = module.eks.cluster_endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#  #token                  = data.aws_eks_cluster_auth.cluster.token
#  exec {
#    api_version = "client.authentication.k8s.io/v1beta1"
#    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.id]
#    command     = "aws"
#  }

#}
