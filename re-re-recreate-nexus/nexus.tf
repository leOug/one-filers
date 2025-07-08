terraform{
    required_providers {
    nexus = {
      source = "datadrivers/nexus"
      version = "2.6.0"
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


resource "nexus_repository_docker_hosted" "internal" {
  depends_on = [nexus_blobstore_file.docker-internal]
  name = "internal"

  docker {
    force_basic_auth = true
    http_port        = 8082
    # https_port       = 8483
    v1_enabled       = false
  }

  storage {
    blob_store_name                = nexus_blobstore_file.docker-internal.name
    strict_content_type_validation = true
    write_policy                   = "ALLOW"
  }
}

resource "nexus_repository_docker_proxy" "dockerhub" {
  depends_on = [nexus_blobstore_file.dockerhub]
  name = "dockerhub"

  docker {
    force_basic_auth = false
    http_port        = 8083
    v1_enabled       = false
  }

  docker_proxy {
    index_type = "HUB"
  }

  storage {
    blob_store_name                = nexus_blobstore_file.dockerhub.name
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
  depends_on = [nexus_blobstore_file.docker-group]
  name   = "docker-group"
  online = true

  docker {
    force_basic_auth = false
    http_port        = 8084
    v1_enabled       = false
  }

  group {
    member_names = [
      nexus_repository_docker_proxy.dockerhub.name,
      nexus_repository_docker_hosted.internal.name,
    ]
    # Removed because this is NOT a pro nexus installation
    # writable_member = nexus_repository_docker_hosted.internal.name
  }

  storage {
    blob_store_name                = nexus_blobstore_file.docker-group.name
    strict_content_type_validation = true
  }
}

resource "nexus_security_realms" "active-realms" {
  active = [
    "NexusAuthenticatingRealm",
    "DockerToken",
  ]
}

resource "nexus_security_role" "docker-group-read" {
  depends_on = [nexus_repository_docker_group.docker-group]
  description = "Users with this role can read (pull) from the docker registries that are in the docker group"
  name        = "${nexus_repository_docker_group.docker-group.name}-read"
  privileges = [
    "nx-repository-view-docker-${nexus_repository_docker_group.docker-group.name}-*",
  ]
  roleid = "${nexus_repository_docker_group.docker-group.name}-read"
}

resource "nexus_security_role" "docker-internal-read" {
    depends_on = [nexus_repository_docker_hosted.internal]
  description = "Users with this role can read the hosted docker registries"
  name        = "docker-${nexus_repository_docker_hosted.internal.name}-read"
  privileges = [
    "nx-repository-view-docker-${nexus_repository_docker_hosted.internal.name}-read",
  ]
  roleid = "docker-${nexus_repository_docker_hosted.internal.name}-read"
}

resource "nexus_security_role" "docker-internal-write" {
  depends_on = [nexus_repository_docker_hosted.internal]
  description = "Users with this role can write (push) to the hosted docker registries"
  name        = "docker-${nexus_repository_docker_hosted.internal.name}-write"
  privileges = [
    "nx-repository-view-docker-${nexus_repository_docker_hosted.internal.name}-edit",
  ]
  roleid = "docker-${nexus_repository_docker_hosted.internal.name}-write"
}

resource "nexus_security_role" "docker-internal-delete" {
  depends_on = [nexus_repository_docker_hosted.internal]
  description = "Users with this role can delete from the hosted docker registries"
  name        = "docker-${nexus_repository_docker_hosted.internal.name}-delete"
  privileges = [
    "nx-repository-view-docker-${nexus_repository_docker_hosted.internal.name}-delete",
  ]
  roleid = "docker-${nexus_repository_docker_hosted.internal.name}-delete"
}

resource "nexus_security_role" "normal-user" {
  description = "A generic User role that has basic privileges for all repositories"
  name   = "normal-user"
  privileges = [
    "nx-repository-view-*-*-browse",
    "nx-healthcheck-read",
    "nx-search-read",
  ]
  roleid = "normal-user"
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


resource "nexus_security_user" "ci-bot" {
  depends_on = [
    nexus_security_role.normal-user,
    nexus_blobstore_file.docker-group,
    nexus_blobstore_file.docker-internal,
    nexus_blobstore_file.dockerhub
  ]
  userid    = "ci-bot"
  firstname = "Continuous Integration"
  lastname  = "Bot"
  email     = "ci-bot@example.com"
  password  = "continuous123"
  roles     = [
    nexus_security_role.normal-user.roleid,
    nexus_security_role.docker-group-read.roleid,
    nexus_security_role.docker-internal-read.roleid,
    nexus_security_role.docker-internal-write.roleid
  ]
  status    = "active"
}

