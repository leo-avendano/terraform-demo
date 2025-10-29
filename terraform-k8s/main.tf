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

module "webserver" {
  source      = "../modules/nginx-k8s"
  name        = "demo-nginx"
  image       = "nginx:alpine"
  port        = 80
  public_port = 30080
  site_dir    = abspath("${path.module}/../site")
}

output "node_port" {
  value = module.webserver.node_port
}


