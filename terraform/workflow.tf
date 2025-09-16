# # Harbor
# resource "helm_release" "harbor" {
#   depends_on = [helm_release.cert-manager]
#   name              = "harbor"
#   repository        = "https://helm.goharbor.io"
#   chart             = "harbor"
#   version           = "1.16.2"
#   create_namespace  = true
#   namespace         = "harbor"
#   values            = [
#     "${file("../modules/harbor/values.yaml")}"
#   ]
# }

# # Headlamp
# resource "helm_release" "headlamp" {
#   depends_on = [helm_release.cert-manager]
#   name              = "headlamp"
#   repository        = "https://kubernetes-sigs.github.io/headlamp/"
#   chart             = "headlamp"
#   version           = "0.30.1"
#   create_namespace  = true
#   namespace         = "headlamp"
#   values            = [
#     "${file("../modules/headlamp/values.yaml")}"
#   ]
# }