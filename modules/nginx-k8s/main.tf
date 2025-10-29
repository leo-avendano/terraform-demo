terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

variable "name" { type = string }
variable "image" { type = string }
variable "port" { type = number }
variable "public_port" { type = number }
variable "site_dir" { type = string }
variable "namespace" {
  type    = string
  default = "default"
}

resource "kubernetes_config_map" "web_content" {
  metadata {
    name      = "${var.name}-content"
    namespace = var.namespace
  }
  data = {
    "index.html" = file(abspath("${var.site_dir}/index.html"))
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = var.name
      }
    }
    template {
      metadata {
        labels = {
          app = var.name
        }
      }
      spec {
        container {
          name  = "nginx"
          image = var.image

          port {
            container_port = var.port
          }

          volume_mount {
            name       = "web-content"
            mount_path = "/usr/share/nginx/html"
            read_only  = true
          }
        }

        volume {
          name = "web-content"
          config_map {
            name = kubernetes_config_map.web_content.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = "${var.name}-svc"
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }
  spec {
    selector = {
      app = var.name
    }
    type = "NodePort"

    port {
      port        = 80
      target_port = var.port
      node_port   = var.public_port
      protocol    = "TCP"
    }
  }
}

output "service_name" {
  value = kubernetes_service.nginx.metadata[0].name
}

output "node_port" {
  value = kubernetes_service.nginx.spec[0].port[0].node_port
}


