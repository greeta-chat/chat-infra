resource "kubernetes_ingress_v1" "ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "simple-fanout-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "kubernetes.io/ingress.class" =  "nginx"
    }
  }

  spec {
    ingress_class_name = "nginx"

    default_backend {
     
      service {
        name = "chat-api"
        port {
          number = 8080
        }
      }
    }     

    rule {
      host = "chat.greeta.net"
      http {

        path {
          backend {
            service {
              name = "chat-api"
              port {
                number = 8080
              }
            }
          }

          path = "/"
          path_type = "Prefix"
        }
      }
    }
    
  }
}

