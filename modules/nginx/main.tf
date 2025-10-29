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
variable "port" { type = number }
variable "public_port" { type = number }
variable "site_dir" { type = string }

resource "docker_image" "nginx" {
  name         = var.image
  keep_locally = false
}

resource "docker_container" "nginx" {
  name  = var.name
  image = docker_image.nginx.image_id

  ports {
    internal = var.port
    external = var.public_port
  }

  volumes {
    host_path      = abspath(var.site_dir)
    container_path = "/usr/share/nginx/html"
    read_only      = true
  }
}

output "url" {
  value = "http://localhost:${var.public_port}"
}


