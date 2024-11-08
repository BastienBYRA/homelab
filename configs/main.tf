provider "helm" {
  kubernetes {
    config_path = "../kubeconfig"
  }
}
provider "kubernetes" {
  config_path = "../kubeconfig"
}

### /!\ Le secret est en mon PC local, c'est (pour l'instant)
# Besoin d'un namespace pour assurer le namespace existe avant d'ajouter le secret dedans
resource "kubernetes_namespace" "externaldns_namespace" {
  metadata {
    annotations = {
      name = "externaldns"
    }
    name = "externaldns"
  }
}
resource "kubernetes_secret" "externaldns_secret" {
  depends_on = [kubernetes_namespace.externaldns_namespace]

  metadata {
    name      = "external-dns-secret"
    namespace = "externaldns"
  }
  data = {
    OVH_APPLICATION_KEY     = yamldecode(file("./apps/externaldns/credentials.yaml"))["OVH_APPLICATION_KEY"]
    OVH_APPLICATION_SECRET  = yamldecode(file("./apps/externaldns/credentials.yaml"))["OVH_APPLICATION_SECRET"]
    OVH_CONSUMER_KEY        = yamldecode(file("./apps/externaldns/credentials.yaml"))["OVH_CONSUMER_KEY"]
  }
}
resource "helm_release" "externaldns" {
  depends_on = [kubernetes_secret.externaldns_secret]

  name              = "externaldns"
  repository        = "https://kubernetes-sigs.github.io/external-dns/"
  chart             = "external-dns"
  version           = "1.15.0"
  create_namespace  = true
  namespace         = "externaldns"
  values            = [
    "${file("./apps/externaldns/values.yaml")}"
  ]
}