provider "libvirt" {
  uri = var.libvirt_uri
}

locals {
  prefix         = "mywebapp-v27"
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
}

resource "libvirt_network" "lab" {
  name      = "${local.prefix}-net"
  mode      = "nat"
  domain    = "lab4.internal"
  addresses = [var.network_cidr]

  dhcp {
    enabled = false
  }

  dns {
    enabled    = true
    local_only = true
  }

  # Provider 0.8 can report a server-side DHCP default even with DHCP disabled.
  lifecycle {
    ignore_changes = [dhcp[0].enabled]
  }
}

resource "libvirt_volume" "ubuntu_base" {
  name   = "${local.prefix}-ubuntu-24.04-base.qcow2"
  pool   = var.storage_pool
  source = var.ubuntu_cloud_image
  format = "qcow2"
}

resource "libvirt_volume" "worker_root" {
  name           = "${local.prefix}-worker.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.ubuntu_base.id
  format         = "qcow2"
  size           = var.disk_bytes
}

resource "libvirt_volume" "db_root" {
  name           = "${local.prefix}-db.qcow2"
  pool           = var.storage_pool
  base_volume_id = libvirt_volume.ubuntu_base.id
  format         = "qcow2"
  size           = var.disk_bytes
}

resource "libvirt_cloudinit_disk" "worker" {
  name           = "${local.prefix}-worker-cloudinit.iso"
  pool           = var.storage_pool
  user_data      = templatefile("${path.module}/cloud-init-worker.yaml.tftpl", {
    ssh_public_key = local.ssh_public_key
    worker_ip      = var.worker_ip
    db_ip          = var.db_ip
  })
  network_config = templatefile("${path.module}/network-worker.yaml.tftpl", {
    worker_ip  = var.worker_ip
    gateway_ip = var.gateway_ip
  })
}

resource "libvirt_cloudinit_disk" "db" {
  name           = "${local.prefix}-db-cloudinit.iso"
  pool           = var.storage_pool
  user_data      = templatefile("${path.module}/cloud-init-db.yaml.tftpl", {
    ssh_public_key = local.ssh_public_key
    worker_ip      = var.worker_ip
    db_ip          = var.db_ip
  })
  network_config = templatefile("${path.module}/network-db.yaml.tftpl", {
    db_ip      = var.db_ip
    gateway_ip = var.gateway_ip
  })
}

resource "libvirt_domain" "worker" {
  name        = "${local.prefix}-worker"
  memory      = var.vm_memory_mib
  vcpu        = var.vm_vcpus
  autostart   = true
  qemu_agent  = true
  cloudinit   = libvirt_cloudinit_disk.worker.id

  disk {
    volume_id = libvirt_volume.worker_root.id
  }

  network_interface {
    network_id = libvirt_network.lab.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  lifecycle {
    ignore_changes = [nvram, disk[0].wwn]
  }
}

resource "libvirt_domain" "db" {
  name        = "${local.prefix}-db"
  memory      = var.vm_memory_mib
  vcpu        = var.vm_vcpus
  autostart   = true
  qemu_agent  = true
  cloudinit   = libvirt_cloudinit_disk.db.id

  disk {
    volume_id = libvirt_volume.db_root.id
  }

  network_interface {
    network_id = libvirt_network.lab.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  lifecycle {
    ignore_changes = [nvram, disk[0].wwn]
  }
}
