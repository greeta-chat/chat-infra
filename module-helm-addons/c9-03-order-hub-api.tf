resource "kubernetes_config_map_v1" "order_hub_config" {
  metadata {
    name      = "order-hub-config"
    labels = {
      app = "order-hub-api"
    }
  }

  data = {
    "order-hub-api.yml" = file("${path.module}/app-conf/order-hub-api.yml")
  }
}


resource "kubernetes_deployment_v1" "order_hub_api_deployment" {
  depends_on = [kubernetes_deployment_v1.order_hub_postgres_deployment]
  metadata {
    name = "order-hub-api"
    labels = {
      app = "order-hub-api"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "order-hub-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "order-hub-api"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "8081"
        }        
      }
      spec {
        volume {
          name = "order-hub-config-volume"    
          config_map {
            name = "order-hub-config"
          }
        }
        
        container {
          image = "ghcr.io/greeta-order-hub/order-hub-api"
          name  = "order-hub-api"
          image_pull_policy = "Always"
          port {
            container_port = 8081
          }
          env {
            name  = "SPRING_CONFIG_LOCATION"
            value = "file:/config-repo/order-hub-api.yml"
          }

          volume_mount {
            name       = "order-hub-config-volume"
            mount_path = "/config-repo"
          }


        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "order_hub_api_hpa" {
  metadata {
    name = "order-hub-api-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.order_hub_api_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 70
  }
}

resource "kubernetes_service_v1" "order_hub_api_service" {
  metadata {
    name = "order-hub-api"
  }
  spec {
    selector = {
      app = "order-hub-api"
    }
    port {
      port = 8081
    }
  }
}
