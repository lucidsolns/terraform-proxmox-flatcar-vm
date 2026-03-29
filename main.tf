locals {
  /*
    Decide whether to use a simplified set of VM parameters, or the list provided (if any).

    Three options:
      - a list of 'vm' objects are provided by the caller
      - the caller asks for a count of VMs
      - a single VM object is created using the singleton values slightly mutated to make them unique
  */
  vms = (var.vms != null && length(var.vms) > 0) ? var.vms : [
    for i in range(var.vm_count) : {
      id          = var.vm_id + i
      name        = var.vm_count > 1 ? format("%s-%d", var.vm_name, i + 1) : var.vm_name
      description = var.vm_description
      butane_variables = {}
    }
  ]
}

/*
  This module mostly uses the 'vm' module once per 'count' virtual machines. This means
  the per VM terraform doesn't have to perform as many mutations.

  The flatcar Linux image retrieval is performed once, regardless of the number of instances
  of the virtual machine.

  Note: This looping with a count is a bit ugly. The plan is to have numeric indices on
  the child VM resources. If a map is used, then the indices become a number as a string.
  So to keep numeric indices, use a count, then index the data from `var.vms`. If the
  index type changes, then the persistent model resources would need to be destroyed
  which will cause a possible loss of data.
*/
module "vm" {
  source   = "./modules/vm"
  count = length(local.vms)
  // for_each = { for vm_index, vm in local.vms : vm_index => vm }

  node_name      = var.node_name
  vm_id          = local.vms[count.index].id
  vm_name        = local.vms[count.index].name
  vm_description = local.vms[count.index].description
  tags           = var.tags

  vm_index         = count.index
  cpu              = var.cpu
  memory           = var.memory
  disks            = var.disks
  persistent_disks = var.persistent_disks

  // If no network devices are provided, then put one default device
  // into the VM.  Use multi-queue for up to 8 cores to try to maximise
  // network bandwidth.
  network_devices = length(var.network_devices) > 0 ? var.network_devices : [
    {
      bridge  = var.bridge
      mtu     = 1
      vlan_id = var.vlan_id
      queues  = min(var.max_network_queues, var.cpu.cores)
    }
  ]
  directories = var.directories

  butane_conf = var.butane_conf
  butane_snippet_path = var.butane_snippet_path
  // Merge the global variable + the per VM variables + pre
  butane_variables = merge(
    var.butane_variables,
    local.vms[count.index].butane_variables,
    {
      "vm_id"    = local.vms[count.index].id
      "vm_name"  = local.vms[count.index].name
      "vm_count" = length(local.vms)
      "vm_index" = count.index
    })

  storage_root         = var.storage_root
  configuration_root   = coalesce(var.configuration_root, var.storage_root)
  storage_path_mapping = var.storage_path_mapping

  flatcar_image_id = proxmox_virtual_environment_download_file.flatcar_image.id
}
