/**
    An example of running a container workload (nginx) with podman in a Flatcar
    Linux VM on proxmox.
 */
module "podman" {
  source  = "lucidsolns/flatcar-vm/proxmox"
  version = "1.0.15"

  vm_name        = "podman-sample"
  vm_description =<<EOF
     A Flatcar Linux VM with podman running Nginx as a sample container workload.

      **This VM can be deleted**
EOF
  vm_id          = var.vm_id
  node_name      = var.node_name
  tags           = ["nginx", "flatcar", "podman"]
  cpu = {
    cores = 2
    type  = "x86-64-v3"
  }
  memory = {
    dedicated = 1000
  }

  butane_conf         = "${path.module}/butane.tftpl"
  butane_snippet_path = "${path.module}/config"
  butane_variables = {
    IMAGE_NAME = "nginx:latest"
  }
  bridge  = var.bridge
  vlan_id = var.vlan_id

  storage_images       = var.storage_images
  storage_root         = var.storage_root
  storage_path_mapping = var.storage_path_mapping
}

