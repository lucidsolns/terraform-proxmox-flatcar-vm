/**
  An example empty VM. No disks, one default NIC
 */
module "empty" {
  # source = "../.."
  source  = "lucidsolns/flatcar-vm/proxmox"
  version = "1.0.15"

  node_name      = var.node_name
  vm_name        = "empty.local"
  vm_description = "A Flatcar Container Linux VM"
  vm_id          = 9999
  tags = ["sample", "flatcar"]
  cpu = {
    cores = 2
  }
  memory = {
    dedicated = 1000
  }

  butane_conf         = "${path.module}/empty.bu.tftpl"
  butane_snippet_path = "${path.module}/config"

  bridge = var.bridge
  vlan_id = var.vlan_id

  storage_images = var.storage_name
  storage_root   = var.storage_name
  storage_path_mapping = {
    "${var.storage_name}" = var.storage_path
  }
}

