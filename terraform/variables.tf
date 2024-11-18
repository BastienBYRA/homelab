variable ARGOCD_USERNAME {
  type        = string
  default     = "admin"
  description = "ArgoCD username"
}

variable ARGOCD_PASSWORD {
  type        = string
  description = "ArgoCD password"
  sensitive = true
}
