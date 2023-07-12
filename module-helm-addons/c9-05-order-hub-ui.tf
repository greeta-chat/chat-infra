resource "kubernetes_deployment_v1" "order_hub_ui_deployment" {
  depends_on = [kubernetes_deployment_v1.order_hub_api_deployment]
  metadata {
    name = "order-hub-ui"
    labels = {
      app = "order-hub-ui"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "order-hub-ui"
      }
    }
    template {
      metadata {
        labels = {
          app = "order-hub-ui"
        }
      }
      spec {
        container {
          image = "ghcr.io/greeta-order-hub/order-hub-ui"
          name  = "order-hub-ui"
          image_pull_policy = "Always"
          port {
            container_port = 4200
          }                                                                                          
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "order_hub_ui_hpa" {
  metadata {
    name = "order-hub-ui-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.order_hub_ui_deployment.metadata[0].name
    }
    target_cpu_utilization_percentage = 70
  }
}

resource "kubernetes_service_v1" "order_hub_ui_service" {
  metadata {
    name = "order-hub-ui"
  }
  spec {
    selector = {
      app = "order-hub-ui"
    }
    port {
      port = 4200
    }
  }
}
