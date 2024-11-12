# Blog
resource "helm_release" "blog" {
  depends_on = [helm_release.externaldns]

  name              = "blog"
  chart             = "../modules/blog"
  create_namespace  = true
  namespace         = "blog"
  values            = [
    "${file("../modules/blog/values.yaml")}"
  ]
}