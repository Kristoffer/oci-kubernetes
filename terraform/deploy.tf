resource "kubernetes_deployment" "nginx_deployment" {
  metadata {
    name = "nginx"
    labels = {
      app = "nginx"
    }
    namespace = kubernetes_namespace.test.id
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx"
          name  = "nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_service" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.test.id
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      target_port = 80
      node_port   = 31600
    }
    type = "NodePort"
  }
}
