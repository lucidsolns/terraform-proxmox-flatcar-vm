locals {
  // see: https://stable.release.flatcar-linux.net/amd64-usr/4230.2.1/
  FLATCAR_BASE_IMAGE_URL      = "https://${var.flatcar_channel}.release.flatcar-linux.net/${var.flatcar_architecture}-usr/${var.flatcar_version}"
  FLATCAR_OS_IMAGE_FILENAME   = "flatcar_production_qemu_uefi_image.img"
  FLATCAR_OS_IMAGE_URL        = "${local.FLATCAR_BASE_IMAGE_URL}/${local.FLATCAR_OS_IMAGE_FILENAME}"
  FLATCAR_OS_IMAGE_DIGEST_URL = "${local.FLATCAR_BASE_IMAGE_URL}/${local.FLATCAR_OS_IMAGE_FILENAME}.DIGESTS"
  FLATCAR_UEFI_VARS_IMAGE_URL = "${local.FLATCAR_BASE_IMAGE_URL}/flatcar_production_qemu_uefi_efi_vars.qcow2"
  FLATCAR_UEFI_CODE_IMAGE_URL = "${local.FLATCAR_BASE_IMAGE_URL}/flatcar_production_qemu_uefi_secure_efi_code.qcow2"
  FLATCAR_BASE_FILENAME       = "flatcar-${var.flatcar_architecture}-${var.flatcar_channel}-${var.flatcar_version}"
}

/**
  Download the specific Flatcar Linux QEMU EFI images to the local machine. This is
  a one off operation that takes a few minutes.

  Note: Although the doc's indicate, that `.bz2` decompression is supported, this is not
  the case at the time of writing (July 2025). The main larger image doesn't compress
  much, so getting compressed images is of limited value.

  WARNING: Importing Disks is not enabled by default in new Proxmox installations. You
  need to enable them in the 'Datacenter>Storage' section of the proxmox interface
  before first using this resource with content_type = "import".

  To get this to 'work', manually edit `/etc/pve/storage.cfg` and add 'import' to the
  `content` attribute for the filesystem type storage


   The image is around half a gigabyte in size, but the actual image has
   a size of approximately 8.5 gigabytes, which means the resulting VM must
   have a disk size no smaller than 8.5GB.

    ```sh
    # qemu-img info flatcar-amd64-stable-4230.2.1-image.qcow2
    image: flatcar-amd64-stable-4230.2.1-image.qcow2
    file format: qcow2
    virtual size: 8.49 GiB (9116319744 bytes)
    disk size: 487 MiB
    cluster_size: 65536
    Format specific information:
        compat: 0.10
        compression type: zlib
        refcount bits: 16
    Child node '/file':
        filename: flatcar-amd64-stable-4230.2.1-image.qcow2
        protocol type: file
        file length: 490 MiB (513277952 bytes)
        disk size: 487 MiB
    ```

  see:
      - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file
      - https://github.com/bpg/terraform-provider-proxmox/issues/860
      - https://git.proxmox.com/?p=pve-storage.git;a=blob;f=PVE/API2/Storage/Status.pm;h=b838461db4b6d2076689ab72f861bfa4d9ee7923;hb=refs/heads/master
 */
resource "proxmox_virtual_environment_download_file" "flatcar_image" {
  content_type        = "import"
  datastore_id        = local.storage_images
  node_name           = var.node_name
  url                 = local.FLATCAR_OS_IMAGE_URL
  file_name           = "${local.FLATCAR_BASE_FILENAME}-image.qcow2"
  overwrite           = false
  overwrite_unmanaged = true
  checksum_algorithm  = "sha512"
  checksum            = module.flatcar_image_digest.digest
  upload_timeout      = var.image_transfer_timeout
}

/*
  Using the flatcar '.DIGEST' file, get the sha512 digest for the OS image
*/
module "flatcar_image_digest" {
  source    = "./modules/digest"
  url       = local.FLATCAR_OS_IMAGE_DIGEST_URL
  filename  = local.FLATCAR_OS_IMAGE_FILENAME
  algorithm = "SHA512"
}

resource "proxmox_virtual_environment_download_file" "flatcar_uefi_vars" {
  count = 0 // disable for now, as UEFI vars are not able to be provisioned

  content_type        = "import"
  datastore_id        = local.storage_images
  node_name           = var.node_name
  url                 = local.FLATCAR_UEFI_VARS_IMAGE_URL
  file_name           = "${local.FLATCAR_BASE_FILENAME}-uefi_vars.qcow2"
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_download_file" "flatcar_uefi_code" {
  count = 0 // disable for now, as UEFI code are not able to be provisioned

  content_type        = "import"
  datastore_id        = local.storage_images
  node_name           = var.node_name
  url                 = local.FLATCAR_UEFI_CODE_IMAGE_URL
  file_name           = "${local.FLATCAR_BASE_FILENAME}-uefi_code.qcow2"
  overwrite_unmanaged = true
}

