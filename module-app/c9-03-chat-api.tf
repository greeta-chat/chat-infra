resource "kubernetes_config_map_v1" "chat_config" {
  metadata {
    name      = "chat-config"
    labels = {
      app = "chat-api"
    }
  }

  data = {
    "chat-api.yml" = file("${path.module}/app-conf/chat-api.yml")
  }
}


resource "kubernetes_deployment_v1" "chat_api_deployment" {
  depends_on = [kubernetes_deployment_v1.chat_postgres_deployment]
  metadata {
    name = "chat-api"
    labels = {
      app = "chat-api"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "chat-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "chat-api"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8081"
        }        
      }
      spec {
        volume {
          name = "chat-config-volume"    
          config_map {
            name = "chat-config"
          }
        }
        
        container {
          image = "ghcr.io/greeta-chat/chat-api"
          name  = "chat-api"
          image_pull_policy = "Always"
          port {
            container_port = 8080
          }
          env {
            name  = "SPRING_CONFIG_LOCATION"
            value = "classpath:application.properties,file:/config-repo/chat-api.yml"
          }

          volume_mount {
            name       = "chat-config-volume"
            mount_path = "/config-repo"
          }


        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "chat_api_hpa" {
  metadata {
    name = "chat-api-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.chat_api_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 70
  }
}

resource "kubernetes_service_v1" "chat_api_service" {
  metadata {
    name = "chat-api"
  }
  spec {
    selector = {
      app = "chat-api"
    }
    port {
      port = 8080
    }
  }
}
