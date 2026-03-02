# Podman example

This example uses podman to run a container.  The nginx container is used
as a sample via Quadlet configuration file.

Flatcar Linux supports podman via a sysext. All that is required to provide the sysext
is to list in the file `/etc/flatcar/enabled-sysext.conf`. Flatcar Linux will
automatically download and enable the sysext.

The sample workload, which is nginx, is run from a Quadlet configuration, which
along with the policy file, will be deployed to the VM in the `/etc/containers`
directory.

Additional configuration performed includes:
  - disable containerd support
  - disable dockerd support
  - add a timer service to clean/prue orphaned podman containers


# Links

- https://www.flatcar.org/docs/latest/provisioning/sysext/
- https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html

