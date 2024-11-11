terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

variable "region" {
  description = "Region to deploy resources in"
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Size of the droplet"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "database_size" {
  description = "Size of the database cluster"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

resource "digitalocean_database_cluster" "grafana_db" {
  name       = "grafana-db"
  engine     = "pg"
  version    = "13"                    # PostgreSQL version
  region     = var.region
  size       = var.database_size
  node_count = 1                       # Single node (adjust as needed)
}

# resource "digitalocean_droplet" "grafana" {
#   name   = "grafana"
#   region = var.region
#   size   = var.droplet_size
#   image  = "ubuntu-22-04-x64"

#   # Optional: Add user data to initialize Grafana installation
#   user_data = <<-EOF
#               #!/bin/bash
#               apt-get update
#               apt-get install -y grafana
#               systemctl start grafana-server
#               EOF
# }

# This should become the web scraper
# resource "digitalocean_app" "golang-sample" {
#   spec {
#     name   = "golang-sample"
#     region = "ams"

#     service {
#       name               = "go-service"
#       environment_slug   = "go"
#       instance_count     = 1
#       instance_size_slug = "professional-xs"

#       git {
#         repo_clone_url = "https://github.com/digitalocean/sample-golang.git"
#         branch         = "main"
#       }
#     }

#     env {
#       key = "EXAMPLE"
#       value = "ciao"
#     }
#   }
# }

# This should become the grafana instance to use as a backend admin panel
resource "digitalocean_app" "grafana" {
  spec {
    name   = "golang-sample"
    region = "ams"

    service {
      name               = "go-service"
      environment_slug   = "go"
      instance_count     = 1
      instance_size_slug = "professional-xs"

      git {
        repo_clone_url = "https://github.com/digitalocean/sample-golang.git"
        branch         = "main"
      }
    }

    env {
      key = "DATABASE_URL"
      value = digitalocean_database_cluster.grafana_db.host
    }
  }
}

# Create the DigitalOcean project
resource "digitalocean_project" "eventful" {
  name        = "eventful"
  purpose     = "This project contains resources for the eventful app"
  environment = "development"
  resources   = [
    # digitalocean_droplet.grafana.urn,
    digitalocean_database_cluster.grafana_db.urn,
    digitalocean_app.grafana.urn
  ]
}