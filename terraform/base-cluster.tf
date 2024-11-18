# Cilium : Pour gérer le networking du cluster (notamment la génération des external-ip)
resource "helm_release" "cilium" {
  name              = "cilium"
  repository        = "https://helm.cilium.io/"
  chart             = "cilium"
  version           = "1.16.3"
  create_namespace  = true
  namespace         = "cilium"
  values            = [
    "${file("../modules/cilium/values.yaml")}"
  ]
}
# Ip pool pour Cilium
resource "kubernetes_manifest" "cilium-ippool" {
  manifest = {
    "apiVersion" = "cilium.io/v2alpha1"
    "kind"       = "CiliumLoadBalancerIPPool"
    "metadata" = {
      "name" = "cillium-pool"
    }
    "spec" = {
      "blocks" = [
        {
          "start" = "107.155.122.60"
          "stop"  = "107.155.122.60"
        }
      ]
      "allowFirstLastIPs" = "No"
    }
  }
}

# Cert Manager : Gérer les certificats SSL
resource "helm_release" "cert-manager" {
  depends_on = [helm_release.cilium]
  name              = "cert-manager"
  repository        = "https://charts.jetstack.io"
  chart             = "cert-manager"
  version           = "v1.16.1"
  create_namespace  = true
  namespace         = "cert-manager"
  values            = [
    "${file("../modules/cert-manager/values.yaml")}"
  ]
}
resource "kubernetes_manifest" "letsencrypt_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-prod"
      # ClusterIssuer ne peut pas etre mis dans un namespace
      # "namespace" = "cert-manager"
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "email"  = "byra.bastien@gmail.com"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-prod"
        }
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "ingressClassName" = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}
resource "kubernetes_manifest" "letsencrypt_issuer_staging" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-staging"
      # ClusterIssuer ne peut pas etre mis dans un namespace
      # "namespace" = "cert-manager"
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-staging-v02.api.letsencrypt.org/directory"
        "email"  = "byra.bastien@gmail.com"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-staging"
        }
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "ingressClassName" = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}

# NGINX Ingress Controller : Pour complémenter Cilium + Avoir un point d'accès
resource "helm_release" "ingress-nginx" {
  depends_on = [helm_release.cert-manager]
  name              = "ingress-nginx"
  repository        = "oci://ghcr.io/nginxinc/charts/"
  chart             = "nginx-ingress"
  version           = "1.4.1"
  create_namespace  = true
  namespace         = "ingress-nginx"
}




# ExternalDNS : Pour gérer la création automatique des noms de domaine
### /!\ Le secret est sur mon PC local, (pour l'instant)
### /!\ Besoin d'un namespace pour s'assurer que le namespace existe avant d'ajouter le secret dedans
resource "kubernetes_namespace" "externaldns_namespace" {
  depends_on = [helm_release.ingress-nginx]
  # depends_on = [helm_release.cilium]
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
    OVH_APPLICATION_KEY     = yamldecode(file("../modules/externaldns/credentials.yaml"))["OVH_APPLICATION_KEY"]
    OVH_APPLICATION_SECRET  = yamldecode(file("../modules/externaldns/credentials.yaml"))["OVH_APPLICATION_SECRET"]
    OVH_CONSUMER_KEY        = yamldecode(file("../modules/externaldns/credentials.yaml"))["OVH_CONSUMER_KEY"]
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
    "${file("../modules/externaldns/values.yaml")}"
  ]
}

# # Prometheus Stack : Pour monitorer mon serveur et mon cluster
# resource "helm_release" "prometheus-stack" {
#   depends_on = [helm_release.externaldns]

#   name              = "prometheus-stack"
#   repository        = "https://prometheus-community.github.io/helm-charts"
#   chart             = "kube-prometheus-stack"
#   version           = "66.1.0"
#   create_namespace  = true
#   namespace         = "prometheus-stack"
#   values            = [
#     "${file("../modules/prometheus-stack/values.yaml")}"
#   ]
# }

# ArgoCD
resource "helm_release" "argocd" {
  depends_on = [helm_release.externaldns]
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true
  namespace = "argocd"
  values            = [
    "${file("../modules/argocd/values.yaml")}"
  ]
}

# # Kubernetes API
# resource "helm_release" "kubeapi" {
#   depends_on = [helm_release.externaldns]
#   name              = "kubeapi"
#   chart             = "../modules/kubeapi"
#   create_namespace  = true
#   namespace         = "kubeapi"
#   values            = [
#     "${file("../modules/kubeapi/values.yaml")}"
#   ]
# }