terraform {
  required_version = ">= 1.4.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
provider "docker" {
  # borrar esta linea cuando no se use colima
  host = "unix://${pathexpand("~/.colima/default/docker.sock")}"
}

module "webserver" {
  source      = "../modules/nginx"
  name        = "demo-nginx"
  image       = "nginx:alpine"
  port        = 80
  public_port = 8080
  site_dir    = abspath("${path.module}/../site")
}


