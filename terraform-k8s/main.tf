terraform {
  required_version = ">= 1.4.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
  config_context = "minikube"
}

module "nginx" {
  source           = "../modules/nginx-k8s"
  name             = "demo-nginx"
  image            = "nginx:alpine"
  internal_port    = 80
  node_port        = 30080
  index_html_path  = abspath("${path.module}/../site/index.html")
  namespace        = "default"
}

output "node_port" {
  value = module.nginx.node_port
}


