terraform {
  required_version = "> 1.12.0"
  required_providers {
    proxmox = {
      /**
        The parent module is expected to load and configure the proxmox provider credentials.
        Given Butane/Ignition support requires root access for `fw_cfg` support with the
        QEMU args, the options for authentication are limited.

        see:
          - https://registry.terraform.io/providers/bpg/proxmox/latest/docs
       */

      source  = "bpg/proxmox"
      version = ">= 0.97.1"
    }
    /*
        see:
          - https://registry.terraform.io/providers/hashicorp/http/latest
    */
    http = {
      source = "hashicorp/http"
      version = ">= 3.5.0"
    }
  }
}
