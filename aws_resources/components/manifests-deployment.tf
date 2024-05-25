# Kubernetes Deployment
resource "kubernetes_manifest" "my_app_deployment" {
  manifest = yamldecode(file("${path.module}/../components/manifests/app-manifest.yaml"))
}

# Kubernetes Service
resource "kubernetes_manifest" "my_app_service" {
  manifest = yamldecode(file("${path.module}/../components/manifests/service-manifest.yaml"))
}

# Kubernetes Ingress
resource "kubernetes_manifest" "my_app_ingress" {
  manifest = yamldecode(file("${path.module}/../components/manifests/ingress-manifest.yaml"))
}