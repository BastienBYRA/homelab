# Helm: Kube state metrics
resource "argocd_application" "ksm" {
  metadata {
    name      = "ksm"
    namespace = "argocd"
  }

  spec {
    destination {
      name = "in-cluster"
      namespace = "monitoring"

    }

    sync_policy {
        automated {
            self_heal = "true"
            prune = "true"
            allow_empty = "false"
        }
        sync_options = ["CreateNamespace=true"]
    }

    source {
      repo_url        = "https://prometheus-community.github.io/helm-charts"
      chart           = "kube-state-metrics"
      target_revision = "5.26.0"
      helm {
        release_name = "kube-state-metrics"
        value_files = ["$values/modules/monitoring/kube-state-metrics/values.yml"]
      }
    }

    source {
      repo_url        = "https://github.com/BastienBYRA/homelab.git"
      target_revision = "feat/setup-monitoring"
      ref             = "values"
      path            =  "modules/monitoring/prometheus/argo"
    }
  }
}

# Helm Prometheus
resource "argocd_application" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = "argocd"
  }

  spec {
    destination {
      name = "in-cluster"
      namespace = "monitoring"

    }

    sync_policy {
        automated {
            self_heal = "true"
            prune = "true"
            allow_empty = "false"
        }
        sync_options = ["CreateNamespace=true"]
    }

    source {
      repo_url        = "https://prometheus-community.github.io/helm-charts"
      chart           = "prometheus"
      target_revision = "25.27.0"
      helm {
        release_name = "prometheus"
        value_files = ["$values/modules/monitoring/prometheus/values.yml"]
      }
    }

    source {
      repo_url        = "https://github.com/BastienBYRA/homelab.git"
      target_revision = "feat/setup-monitoring"
      ref             = "values"
    }
  }
}