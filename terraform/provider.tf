provider "helm" {
  kubernetes {
    config_path = "../kubeconfig"
  }
}
provider "kubernetes" {
  config_path = "../kubeconfig"
}

terraform {
  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.0.3" # Use the latest version if available
    }
  }
}

provider "argocd" {
  server_addr = "argocd.bastienbyra.fr:443"
  username = var.ARGOCD_USERNAME
  password = var.ARGOCD_PASSWORD
}