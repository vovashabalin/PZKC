terraform {
  required_version = ">= 1.6.0"

  # v0.8 uses the stable legacy schema required by the cloud-init disk resource.
  # Provider v0.9 changed the schema incompatibly, therefore the version is pinned.
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}
