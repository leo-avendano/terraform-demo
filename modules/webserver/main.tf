variable "runtime" {
  type    = string
  default = "docker" # one of: docker, k8s
}

variable "name" { type = string }
variable "image" { type = string }
variable "port" { type = number }
variable "site_dir" { type = string }

variable "docker_external_port" {
  type    = number
  default = 8080
}

variable "k8s_node_port" {
  type    = number
  default = 30080
}

 

module "docker" {
  count            = var.runtime == "docker" ? 1 : 0
  source           = "../nginx"
  name             = var.name
  image            = var.image
  port             = var.port
  public_port      = var.docker_external_port
  site_dir         = var.site_dir
}

module "k8s" {
  count           = var.runtime == "k8s" ? 1 : 0
  source          = "../nginx-k8s"
  name            = var.name
  image           = var.image
  port            = var.port
  public_port     = var.k8s_node_port
  site_dir        = var.site_dir
}

output "url" {
  value       = var.runtime == "docker" ? module.docker[0].url : null
  description = "HTTP URL (Docker runtime only)"
}

output "service_name" {
  value       = var.runtime == "k8s" ? module.k8s[0].service_name : null
  description = "K8s Service name (K8s runtime only)"
}

output "node_port" {
  value       = var.runtime == "k8s" ? module.k8s[0].node_port : null
  description = "K8s NodePort (K8s runtime only)"
}


