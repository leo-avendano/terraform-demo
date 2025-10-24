terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

variable "name" { type = string }
variable "image" { type = string }
variable "internal_port" { type = number }
variable "external_port" { type = number }
variable "host_content_dir" { type = string }

resource "docker_image" "nginx" {
  name         = var.image
  keep_locally = false
}

resource "docker_container" "nginx" {
  name  = var.name
  image = docker_image.nginx.image_id

  ports {
    internal = var.internal_port
    external = var.external_port
  }

  volumes {
    host_path      = var.host_content_dir
    container_path = "/usr/share/nginx/html"
    read_only      = true
  }
}

output "url" {
  value = "http://localhost:${var.external_port}"
}


