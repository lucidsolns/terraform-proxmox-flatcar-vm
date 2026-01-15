
output "FLATCAR_BASE_IMAGE_URL" {
  description = <<EOT
      The base http URL for the version of Flatcar Linux, where the image is downloaded from.

      This can be used to download official sysext images (that are not part of the bakery) and
      other distribution files.

      Note: The path has no trailing slash.

      example:
        - https://stable.release.flatcar-linux.net/amd64-usr/4459.2.2
        - https://stable.release.flatcar-linux.net/amd64-usr/current
  EOT

  value = local.FLATCAR_BASE_IMAGE_URL
}
