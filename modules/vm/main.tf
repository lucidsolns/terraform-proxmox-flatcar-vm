/**
  A virtual machine resource to accompany the persistent disks, using the flatcar image.

  Given this is a Flatcar Linux VM, that is booted via UEFI, a large number of the
  VM parameters are fixed.

  see:
    - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
 */
resource "proxmox_virtual_environment_vm" "vm" {
  vm_id       = var.vm_id
  name        = var.vm_name
  description = var.vm_description
  node_name   = var.node_name

  tags = var.tags

  memory {
    dedicated = var.memory.dedicated
    shared    = var.memory.shared
    floating  = var.memory.floating
  }

  agent {
    enabled = true
  }

  stop_on_destroy = true
  on_boot         = true
  bios            = "ovmf"
  efi_disk {
    datastore_id = var.storage_root
    // import_from  = proxmox_virtual_environment_download_file.flatcar_uefi_vars.id
    type = "4m"
  }
  boot_order = ["virtio0"]

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }
  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.cpu.cores
    type  = var.cpu.type
  }
  scsi_hardware = "virtio-scsi-single"

  // Create the VM disks from an ordered list of disks. They aren't created in the various
  // blocked, otherwise the ordering will be lost in the state file, then when the configuration
  // is reapplied, there are inconsistencies due to the reordering.  The local variables below
  // will construct the ordered sets of disks into a list so they are applied here in one block.
  //
  // The order of the disks is:
  //   virtio0 is the Flatcar OS disk
  //   virtio1..N are additional disks for the VM that will be deleted when the VM is reprovisioned
  //   virtioN+1...M are persistent disks from the secondary VM
  dynamic "disk" {
    for_each = local.ordered_disks
    iterator = disk

    content {
      interface         = disk.value.interface
      datastore_id      = disk.value.datastore_id
      size              = try(disk.value.size, null)
      file_format       = try(disk.value.file_format, null)
      iothread          = try(disk.value.iothread, null)
      discard           = try(disk.value.discard, null)
      import_from       = try(disk.value.import_from, null)
      backup            = try(disk.value.backup, null)
      path_in_datastore = try(disk.value.path_in_datastore, null)
    }
  }

  dynamic "network_device" {
    for_each = var.network_devices
    iterator = nic

    content {
      model = "virtio"
      bridge = nic.value.bridge
      vlan_id = nic.value.vlan_id
      mtu = nic.value.mtu
      mac_address = nic.value.mac_address
      queues = nic.value.queues

      enabled = nic.value.enabled
      disconnected = nic.value.disconnected
      firewall = nic.value.firewall
    }
  }

  dynamic "virtiofs" {
    for_each = var.directories
    iterator = map

    content {
      mapping = map.value.name
      cache = map.value.cache
      direct_io = map.value.direct_io
      expose_acl = map.value.expose_acl
      expose_xattr = map.value.expose_xattr
    }
  }

  // Directly set the KVM/Qemu firmware configuration. Don't use cloud-init, provide
  // the butane via Qemu firmware configuration as a file in a snippet.
  //
  // WARNING: This is has a requirement to provision as a root user. This is mentioned
  //          in the proxmox bug tracker:
  //     > we'll never be able to allow arbitrary qemu arguments as non-root user, because
  //     > with that you could do all sorts of things (e.g. passing through /dev/sda as
  //     > blockdevice, giving you at least read access to the whole hypervisor)
  //
  //  When/if the Proxmox hypervisor exposes direct support for setting fw_cfg values
  //  from a string or file then the root requirement would be avoided. More importantly
  //  the path to a file variable, could be mapped by proxmox using a storage path
  //  rather than a absolute path on a specific Proxmox node.
  //
  // see:
  // - https://github.com/bpg/terraform-provider-proxmox/pull/205
  // - https://www.flatcar.org/docs/latest/provisioning/ignition/specification/
  // - https://bugzilla.proxmox.com/show_bug.cgi?id=4068
  // - https://www.qemu.org/docs/master/specs/fw_cfg.html#externally-provided-items
  kvm_arguments = "-fw_cfg name=opt/org.flatcar-linux/config,file=${module.butane_storage_map.path}"

  lifecycle {
    // see: https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#replace_triggered_by
    replace_triggered_by = [
      proxmox_virtual_environment_file.flatcar_butane,
      null_resource.disk_length_trigger
    ]
  }
}

locals {

  # Boot disk (always first)
  boot_disk = [
    {
      interface    = "virtio0"
      datastore_id = var.storage_root
      iothread     = true
      discard      = "on"
      size         = 10
      import_from  = var.flatcar_image_id
      backup       = false
    }
  ]

  // Add the additional (lifecycle not fixed) non-persistent disks (second)
  //
  // Take the configuration provided and merge it with a fixed interface name
  disks = [
    for idx, disk in var.disks : merge(
      disk,
      {
        interface = "virtio${1 + idx}" # skip virtio0 used by boot disk above
      }
    )
  ]

  // Reference each of the disks in the persistent storage VM that is created
  // as a place to hold and managed the disks.
  //
  // Only provision those disks if there are some provisioned (otherwise the
  // whole VM will not be present).
  persistent_disks = length(proxmox_virtual_environment_vm.persistent_disk) > 0 ? [
    for idx, disk in proxmox_virtual_environment_vm.persistent_disk[0].disk : {
      interface         = "virtio${1 + length(var.disks) + idx}"
      datastore_id      = disk["datastore_id"]
      path_in_datastore = disk["path_in_datastore"]
      file_format       = disk["file_format"]
      size              = disk["size"]
      iothread          = disk["iothread"]
      discard           = disk["discard"]
    }
  ] : []

  # Merge all into one ordered list
  ordered_disks = concat(local.boot_disk, local.disks, local.persistent_disks)
}


/**
    Create a VM for the purpose of holding disks that are never deleted (persistent data).

    This is a particularly cunning plan adopted by the 'bpg' proxmox provider
    that works well enough until proxmox has the concept of protected disks.

    The terraform 'prevent_destroy' lifecycle flag is hard to workaround when
    the resource is in a module and the disk really needs to be deleted. If one
    of the disks needs to be deleted, then do that manually in proxmox is likely
    to be easiest way. By putting the disks into a single VM, a bulk deleted
    of all disks for a VM should be possible as a group (c.f. creating a VM
    per persistent disk).

    see:
      - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#example-attached-disks

 */
resource "proxmox_virtual_environment_vm" "persistent_disk" {
  // Only provision the persistent disks VM if there are persistent disks
  count = length(var.persistent_disks) > 0 ? 1 : 0

  name        = "${var.vm_name}-disks"
  description = "Persistent data disk for VM ${var.vm_id} '${var.vm_name}' - DO NOT DELETE"
  node_name   = var.node_name
  tags = ["persistent-storage"]
  vm_id       = (var.vm_id * 10)+ 1000000
  started     = false
  on_boot     = false
  boot_order = []

  dynamic "disk" {
    for_each = var.persistent_disks
    iterator = disk
    content {
      interface = "scsi${disk.key}"  // the name isn't really used, so use a scsi prefix
      datastore_id = disk.value.datastore_id
      size         = disk.value.size
      iothread     = disk.value.iothread
      discard      = disk.value.discard
      backup       = disk.value.backup
      file_format  = disk.value.file_format
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

/**
    Use a path mapping to determine the absolute path of the ignition script
    in the snippets storage.
 */
module "butane_storage_map" {
  source = "./storage-map"

  storage_id  = proxmox_virtual_environment_file.flatcar_butane.id
  storage_map = var.storage_path_mapping
}

/**
  Put the ignition JSON into a snippet.

  This ignition goes through a translation from:
      1. a main butane YAML file
      2. a set of optional butane YAML snippet files
      3. all files are then translated as a Terraform template, with the following parameters:
          - vm_id
          - vm_name
          - vm_index (zero based)
          - vm_count
          - ... plus any provided template parameters
      4. translated to JSON

  see:
    - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file
 */
resource "proxmox_virtual_environment_file" "flatcar_butane" {
  content_type = "snippets"
  datastore_id = var.configuration_root
  node_name    = var.node_name

  source_raw {
    data      = data.butane_config.butane.ignition
    file_name = "vm-${var.vm_id}.butane.json"
  }
}


/**
  Use the 'KeisukeYamashita' provider to convert the butane YAML configuration
  to an ignition JSON configuration.

  The provider uses a more modern version of the butane source directly
  in the provider that the 'ct' provider.

  Each instance of the VM (if there are multiple) will get their own
  customised ignition.

  see:
    - https://registry.terraform.io/providers/KeisukeYamashita/butane/latest/docs/data-sources/config#files_dir-2
    - https://github.com/KeisukeYamashita/terraform-provider-butane
    - https://github.com/coreos/butane
    - https://www.flatcar.org/docs/latest/provisioning/config-transpiler/configuration/
    - https://www.flatcar.org/docs/latest/provisioning/ignition/specification/
 */
data "butane_config" "butane" {
  content = templatefile(var.butane_conf, var.butane_variables)
  strict = true
  pretty = true
  files_dir = var.butane_snippet_path
}

/**
    Setup a trigger for when the number of disks changes, so that the
    VM is reprovisioned.

    By reprovisioning the disks, the Butane/Ignition will be rerun.
 */
resource "null_resource" "disk_length_trigger" {
  triggers = {
    disk_count = length(var.disks)
    disks_serialized = jsonencode(var.persistent_disks)
  }
}
