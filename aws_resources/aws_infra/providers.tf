provider "aws" {
  region  = var.region
  profile = "iamadmin-prd"
}

#K8s provider v2
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.local_file.kubeconfig_token.content
}

## Kubernetes provider configuration
#provider "kubernetes" {
#  host                   = module.eks.cluster_endpoint
#  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#  #token                  = data.aws_eks_cluster_auth.cluster.token
#  exec {
#    api_version = "client.authentication.k8s.io/v1beta1"
#    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
#    command     = "aws"
#  }
#}
