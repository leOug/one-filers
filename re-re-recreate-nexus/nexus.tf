terraform{
    required_providers {
    nexus = {
      source = "datadrivers/nexus"
      version = "2.6.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

provider "nexus" {
  # I am using Traefik in order to use https with a valid certificate, so I do not need insecure
  # insecure = true
  password = var.nexus_admin_password
  url      = var.nexus_url
  username = "admin"
}

variable "nexus_url" {
  description = "The url that nexus is accessible"
  type = string
  default = "https://nexus.doma.in"
}

variable "nexus_admin_password" {
  description = "The admin password for Nexus"
  type = string
  default = "83f43c14-4c82-46f0-a5e4-72bf5ee1e6f2"
}

resource "nexus_security_anonymous" "system" {
  enabled = false
  user_id = "anonymous"
}

resource "nexus_blobstore_file" "docker-internal" {
  name = "docker-internal"
  path = "/nexus-data/docker-internal"

  soft_quota {
    limit = 32212254720
    type  = "spaceRemainingQuota"
  }
}

resource "nexus_blobstore_file" "dockerhub" {
  name = "dockerhub"
  path = "/nexus-data/dockerhub"

  soft_quota {
    limit = 32212254720
    type  = "spaceRemainingQuota"
  }
}

resource "nexus_blobstore_file" "docker-group" {
  name = "docker-group"
  path = "/nexus-data/docker-group"

  soft_quota {
    limit = 1024000000
    type  = "spaceRemainingQuota"
  }
}

data "nexus_blobstore_file" "docker-internal" {
  name = nexus_blobstore_file.docker-internal.name
}

data "nexus_blobstore_file" "dockerhub" {
  name = nexus_blobstore_file.dockerhub.name
}

data "nexus_blobstore_file" "docker-group" {
  name = nexus_blobstore_file.docker-group.name
}

resource "nexus_repository_docker_hosted" "internal" {
  name = "internal"

  docker {
    force_basic_auth = true
    http_port        = 8083
    https_port       = 8483
    v1_enabled       = false
  }

  storage {
    blob_store_name                = data.nexus_blobstore_file.docker-internal.name
    strict_content_type_validation = true
    write_policy                   = "ALLOW"
  }
}

resource "nexus_repository_docker_proxy" "dockerhub" {
  name = "dockerhub"

  docker {
    force_basic_auth = false
    http_port        = 8082
    v1_enabled       = false
  }

  docker_proxy {
    index_type = "HUB"
  }

  storage {
    blob_store_name                = data.nexus_blobstore_file.dockerhub.name
    strict_content_type_validation = true
  }

  proxy {
    remote_url       = "https://registry-1.docker.io"
    content_max_age  = 1440
    metadata_max_age = 1440
  }

  negative_cache {
    enabled = true
    ttl     = 1440
  }

  http_client {
    blocked    = false
    auto_block = true
  }
}

resource "nexus_repository_docker_group" "docker-group" {
  name   = "docker-group"
  online = true

  docker {
    force_basic_auth = false
    http_port        = 8084
    https_port       = 8484
    v1_enabled       = false
    subdomain        = "docker-group"
  }

  group {
    member_names = [
      nexus_repository_docker_hosted.internal.name,
      nexus_repository_docker_proxy.dockerhub.name
    ]
    # Removed because this is NOT a pro nexus installation
    # writable_member = nexus_repository_docker_hosted.internal.name
  }

  storage {
    blob_store_name                = data.nexus_blobstore_file.docker-group.name
    strict_content_type_validation = true
  }
}

output "docker-hosted-internal-url" {
  value = "${var.nexus_url}/repository/${nexus_repository_docker_hosted.internal.id}/"
}

output "docker-proxy-dockerhub-url" {
  value = "${var.nexus_url}/repository/${nexus_repository_docker_proxy.dockerhub.id}/"
}

output "docker-group-url" {
  value = "${var.nexus_url}/repository/${nexus_repository_docker_group.docker-group.id}/"
}

resource "nexus_security_user" "extra-admin" {
  userid    = "extra-admin"
  firstname = "Extra"
  lastname  = "Admin"
  email     = "extra-admin@example.com"
  password  = "admin123"
  roles     = ["nx-admin"]
  status    = "active"
}

resource "nexus_security_role" "docker-group-read" {
  description = "Users with this role can read (pull) from the docker registries that are in the docker group"
  name        = "${nexus_repository_docker_group.docker-group.name}-read"
  privileges = [
    "nx-repository-view-docker-${nexus_repository_docker_group.docker-group.name}-*",
  ]
  roleid = "${nexus_repository_docker_group.docker-group.name}-read"
}

resource "nexus_security_role" "docker-internal-write" {
  description = "Users with this role can write (push) to the hosted docker registries"
  name        = "docker-${nexus_repository_docker_hosted.internal.name}-write"
  privileges = [
    "nx-repository-view-docker-${nexus_repository_docker_hosted.internal.name}-*",
  ]
  roleid = "docker-${nexus_repository_docker_hosted.internal.name}-write"
}
