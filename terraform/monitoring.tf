# Helm: Kube state metrics
resource "argocd_application" "ksm" {
  depends_on = [helm_release.argocd]
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
    #   path            =  "modules/monitoring/prometheus/argo"
    }
  }
}

# Helm Prometheus
resource "argocd_application" "prometheus" {
  depends_on = [argocd_application.ksm]
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

        # Pour que l'argo application soit update s'il y a des changements dans le fichier values.yml
        parameter {
          name = "valueschecksum"
          value = filemd5("../modules/monitoring/prometheus/values.yml") 
        }
      }
    }

    source {
      repo_url        = "https://github.com/BastienBYRA/homelab.git"
      target_revision = "feat/setup-monitoring"
      ref             = "values"
    }
  }
}

# Helm Grafana
resource "argocd_application" "grafana" {
  depends_on = [argocd_application.ksm]
  metadata {
    name      = "grafana"
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
      repo_url        = "https://grafana.github.io/helm-charts"
      chart           = "grafana"
      target_revision = "8.5.8"
      helm {
        release_name = "grafana"
        value_files = ["$values/modules/monitoring/grafana/values.yml"]

        # Pour que l'argo application soit update s'il y a des changements dans le fichier values.yml
        parameter {
          name = "valueschecksum"
          value = filemd5("../modules/monitoring/grafana/values.yml") 
        }
      }
    }

    source {
      repo_url        = "https://github.com/BastienBYRA/homelab.git"
      target_revision = "feat/setup-monitoring"
      ref             = "values"
    }
  }
}

# Promtail
resource "argocd_application" "promtail" {
  depends_on = [argocd_application.grafana]
  metadata {
    name      = "promtail"
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
      repo_url        = "https://grafana.github.io/helm-charts"
      chart           = "promtail"
      target_revision = "6.16.6"
      helm {
        release_name = "promtail"
        value_files = ["$values/modules/monitoring/promtail/values.yml"]

        # Pour que l'argo application soit update s'il y a des changements dans le fichier values.yml
        parameter {
          name = "valueschecksum"
          value = filemd5("../modules/monitoring/promtail/values.yml") 
        }
      }
    }

    source {
      repo_url        = "https://github.com/BastienBYRA/homelab.git"
      target_revision = "feat/setup-monitoring"
      ref             = "values"
    }
  }
}

# Loki
resource "argocd_application" "lokistandalone" {
  depends_on = [argocd_application.promtail]
  metadata {
    name      = "lokistandalone"
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
      repo_url        = "https://grafana.github.io/helm-charts"
      chart           = "loki"
      target_revision = "6.19.0"
      helm {
        release_name = "lokistandalone"
        value_files = ["$values/modules/monitoring/loki/values.yml"]

        # Pour que l'argo application soit update s'il y a des changements dans le fichier values.yml
        parameter {
          name = "valueschecksum"
          value = filemd5("../modules/monitoring/loki/values.yml") 
        }
      }
    }

    source {
      repo_url        = "https://github.com/BastienBYRA/homelab.git"
      target_revision = "feat/setup-monitoring"
      ref             = "values"
    }
  }
}

# http://loki.monitoring.svc.cluster.local:3100