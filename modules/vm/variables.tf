//module
// see
//  - https://thenewstack.io/automate-k3s-cluster-installation-on-flatcar-container-linux/
//
variable "node_name" {
  description = "The name of the node to provision the VM"
  type        = string
}

variable "vm_description" {
  description = "The description to apply to the Proxmox description (free form)"
  type        = string
}


variable "tags" {
  type = list(string)
}


variable vm_id {
  description = "The Proxmox integer id of the VM"
  type        = number
}

variable vm_name {
  description = "The name of the virtual machine"
  type        = string
}


variable "configuration_root" {
  description = "The name of the datastore to store the ignition configuration"
  type        = string
}

variable "storage_root" {
  description = "The name of the datastore to store the root filesystem for the VM"
  type        = string
}

variable storage_path_mapping {
  description = "Mapping of storage name to a local path (this is to support local path name construction)"
  type = map(string)
}


variable "vm_index" {
  default = 1
  type    = number
}

variable "butane_conf" {
  description = "The name/path of the butane file used to configure the Flatcar VM upon first boot"
  type        = string
}
variable "butane_snippet_path" {
  description = "The base path to butane configuration file snippets"
  type        = string
}

variable butane_variables {
  description = "An optional map of additional variables to pass to the butane templates"
  type = map(string)
  default = {}
}

variable flatcar_image_id {
  description = "The local file id for the boot image"
  type        = string
}

variable cpu {
  description = "The VM cpu parameters"
  type = object({
    cores = optional(number, "1")
    type = optional(string, "qemu64")
  })
  default = {
    cores = 1
    type  = "qemu64"
  }
}

variable memory {
  description = "The VM memory parameters"
  type = object({
    dedicated = optional(number, "512")
    floating = optional(number, "0")
    shared = optional(number, "0")
  })
  default = {
  }
}


variable disks {
  description = "An optional list additional disks (these will be deleted with the VM when reprovisioned)"
  type = list(object({
    datastore_id = string
    //  interface    = string
    size = number
    cache = optional(string, "none")
    iothread = optional(bool, false)
    backup = optional(bool, true)
    discard = optional(string, "ignore")
    file_format = optional(string)
  }))
  default = []
}

variable persistent_disks {
  description = "An optional list of persistent disk parameters"
  type = list(object({
    datastore_id = string
    // interface    = string
    size = number
    cache = optional(string, "none")
    iothread = optional(bool, false)
    backup = optional(bool, true)
    discard = optional(string, "ignore")
    file_format = optional(string)
  }))
  default = []
}

variable network_devices {
  description = "An optional list network interfaces"
  type = list(object({
    bridge = optional(string, "vmbr0")
    mtu = optional(number, 1)
    vlan_id = optional(number, 0)
    mac_address = optional(string, null)
    queues = optional(number, null)

    enabled = optional(bool, true)
    disconnected = optional(bool, false)
    firewall = optional(bool, false)
  }))
}

variable directories {
  type = list(object({
    name = string # the name of the directory mapping
    cache = optional(string, "never") // "auto", "always", "never", "metadata"
    direct_io = optional(bool, false)
    expose_acl = optional(bool, false)
    expose_xattr = optional(bool, false)
  }))
}
