terraform {

  /**

    see:
      - https://registry.terraform.io/providers/bpg/proxmox/latest/docs
   */
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.85.1"
    }

    /**
       see:
         - https://registry.terraform.io/providers/KeisukeYamashita/butane/latest
         - https://github.com/KeisukeYamashita/terraform-provider-butane
     */
    butane = {
      source = "KeisukeYamashita/butane"
      version = ">= 0.1.4"
    }

    /*
      see:
        - https://registry.terraform.io/providers/hashicorp/null/latest
    */
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.4"
    }
  }
}
