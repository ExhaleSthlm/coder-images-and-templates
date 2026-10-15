terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 2.19"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.3"
    }
  }
}

provider "coder" {}
provider "kubernetes" {}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  # renovate: datasource=docker depName=ghcr.io/exhalesthlm/coder-images-and-templates/esp-dev
  workspace_image = "ghcr.io/exhalesthlm/coder-images-and-templates/esp-dev:main@sha256:dc0721ee25235486c7adf509c7d9897ff787359e9202e631269be127d5ec8313"
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  default      = "4"
  mutable      = true

  option {
    name  = "2 cores"
    value = "2"
  }
  option {
    name  = "4 cores"
    value = "4"
  }
  option {
    name  = "8 cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  default      = "8"
  mutable      = true

  option {
    name  = "4 GiB"
    value = "4"
  }
  option {
    name  = "8 GiB"
    value = "8"
  }
  option {
    name  = "16 GiB"
    value = "16"
  }
}

data "coder_parameter" "disk_size" {
  name         = "disk_size"
  display_name = "Workspace storage"
  type         = "number"
  default      = "40"
  mutable      = false

  validation {
    min = 20
    max = 200
  }
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"

  startup_script = <<-EOT
    set -eu
    mkdir -p /config/workspace
    git config --global init.defaultBranch main
  EOT

  metadata {
    display_name = "CPU Usage"
    key          = "cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "memory_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Workspace Disk"
    key          = "workspace_disk"
    script       = "coder stat disk --path /config"
    interval     = 60
    timeout      = 1
  }
}

resource "coder_app" "desktop" {
  agent_id     = coder_agent.main.id
  slug         = "desktop"
  display_name = "ESP Development Desktop"
  icon         = "/icon/code.svg"
  url          = "http://localhost:3000"
  subdomain    = false
  share        = "owner"
  open_in      = "slim-window"

  healthcheck {
    url       = "http://localhost:3000"
    interval  = 5
    threshold = 36
  }
}

resource "kubernetes_persistent_volume_claim_v1" "workspace" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-workspace"
    namespace = "coder-workspaces"
    labels = {
      "app.kubernetes.io/name"    = "coder-workspace"
      "app.kubernetes.io/part-of" = "coder"
      "backup.myk8s.se/volume"    = "true"
      "com.coder.resource"        = "true"
      "com.coder.workspace.id"    = data.coder_workspace.me.id
      "com.coder.workspace.name"  = data.coder_workspace.me.name
      "com.coder.user.id"         = data.coder_workspace_owner.me.id
      "com.coder.user.username"   = data.coder_workspace_owner.me.name
    }
  }
  wait_until_bound = false

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "replicated"
    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "workspace" {
  count            = data.coder_workspace.me.start_count
  wait_for_rollout = false

  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = "coder-workspaces"
    labels = {
      "app.kubernetes.io/name"    = "coder-workspace"
      "app.kubernetes.io/part-of" = "coder"
      "com.coder.resource"        = "true"
      "com.coder.workspace.id"    = data.coder_workspace.me.id
      "com.coder.workspace.name"  = data.coder_workspace.me.name
      "com.coder.user.username"   = data.coder_workspace_owner.me.name
    }
  }

  spec {
    replicas = 1
    strategy { type = "Recreate" }

    selector {
      match_labels = {
        "com.coder.workspace.id" = data.coder_workspace.me.id
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "coder-workspace"
          "app.kubernetes.io/part-of" = "coder"
          "com.coder.resource"        = "true"
          "com.coder.workspace.id"    = data.coder_workspace.me.id
          "com.coder.workspace.name"  = data.coder_workspace.me.name
          "com.coder.user.username"   = data.coder_workspace_owner.me.name
        }
      }

      spec {
        automount_service_account_token  = false
        termination_grace_period_seconds = 30

        security_context {
          fs_group               = 1000
          fs_group_change_policy = "OnRootMismatch"
        }

        container {
          name  = "desktop"
          image = local.workspace_image

          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "PGID"
            value = "1000"
          }
          env {
            name  = "TZ"
            value = "Europe/Stockholm"
          }
          env {
            name  = "TITLE"
            value = "ESP Dev - ${data.coder_workspace.me.name}"
          }
          env {
            name  = "PIXELFLUX_WAYLAND"
            value = "true"
          }
          env {
            name  = "AUTO_GPU"
            value = "true"
          }
          env {
            name  = "SELKIES_USE_CPU"
            value = "false"
          }
          env {
            name  = "MAX_RES"
            value = "3840x2160"
          }
          env {
            name  = "START_DOCKER"
            value = "false"
          }

          port {
            name           = "desktop"
            container_port = 3000
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu                  = "500m"
              memory               = "2Gi"
              "gpu.intel.com/i915" = "1"
            }
            limits = {
              cpu                  = data.coder_parameter.cpu.value
              memory               = "${data.coder_parameter.memory.value}Gi"
              "gpu.intel.com/i915" = "1"
            }
          }

          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "workspace"
            mount_path = "/config"
          }
          volume_mount {
            name       = "shm"
            mount_path = "/dev/shm"
          }
        }

        container {
          name    = "coder-agent"
          image   = local.workspace_image
          command = ["sh", "-c", coder_agent.main.init_script]

          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          env {
            name  = "HOME"
            value = "/config"
          }

          resources {
            requests = { cpu = "100m", memory = "256Mi" }
            limits   = { cpu = "1", memory = "1Gi" }
          }

          security_context {
            run_as_user                = 1000
            run_as_group               = 1000
            run_as_non_root            = true
            allow_privilege_escalation = false
            capabilities { drop = ["ALL"] }
          }

          volume_mount {
            name       = "workspace"
            mount_path = "/config"
          }
        }

        volume {
          name = "workspace"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.workspace.metadata[0].name
          }
        }

        volume {
          name = "shm"
          empty_dir {
            medium     = "Memory"
            size_limit = "2Gi"
          }
        }
      }
    }
  }
}
