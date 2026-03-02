/*
 * The API requires credentials. Use an API key (c.f. username/password), by going to the
 * web UI 'Datacenter' -> 'Permissions' -> 'API Tokens' and create a new set of credentials.
 *
*/
variable "pm_api_url" {
  description = "The proxmox api endpoint"
  default     = "https://proxmox:8006/api2/json"
}


variable "pm_user" {
  description = "A username for password based authentication of the Proxmox API"
  type        = string
  default     = "root@pam"
}

variable "pm_password" {
  description = "A password for password based authentication of the Proxmox API"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_username" {
  description = "The SSH username used when performing commands that require SSH access to Proxmox"
  default     = "root"
  type        = string
}

// see
//  - https://thenewstack.io/automate-k3s-cluster-installation-on-flatcar-container-linux/
variable "node_name" {
  description = "The name of the node in the proxmox cluster to provision the VM"
  default = "proxmox"
}

variable vm_id {
  description = "The Proxmox integer id of the VM"
  default = 9999
}

variable "bridge" {
  default = "vmbr0"
  type=string
}

variable "vlan_id" {
  default = 128
  type = number
}

variable "storage_images" { default = "vmroot" }
variable "storage_root" { default = "vmroot" }
variable "storage_data" { default = "vmdata" }
variable storage_path_mapping {
  description = "Mapping of storage name to a local path"
  type = map(string)
  default = {
    "vmroot" = "/droplet/vmroot"
  }
}

