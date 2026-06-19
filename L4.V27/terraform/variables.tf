variable "libvirt_uri" {
  description = "Libvirt URI. qemu:///system is the standard local KVM/QEMU daemon."
  type        = string
  default     = "qemu:///system"
}

variable "storage_pool" {
  description = "Existing libvirt storage pool for cloud images and VM disks."
  type        = string
  default     = "default"
}

variable "network_cidr" {
  description = "Private NAT network dedicated to the two laboratory VMs."
  type        = string
  default     = "192.168.124.0/24"
}

variable "worker_ip" {
  description = "Static IP for the worker node."
  type        = string
  default     = "192.168.124.10"
}

variable "db_ip" {
  description = "Static IP for the database node."
  type        = string
  default     = "192.168.124.20"
}

variable "gateway_ip" {
  description = "Gateway address assigned by libvirt's NAT network."
  type        = string
  default     = "192.168.124.1"
}

variable "ubuntu_cloud_image" {
  description = "Official Ubuntu 24.04 cloud image URL."
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "ssh_public_key_path" {
  description = "Path to the student's public SSH key; it is inserted by cloud-init for user ansible."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vm_memory_mib" {
  description = "Memory for each VM in MiB."
  type        = number
  default     = 2048
}

variable "vm_vcpus" {
  description = "Number of virtual CPUs for each VM."
  type        = number
  default     = 2
}

variable "disk_bytes" {
  description = "Root disk capacity for each VM. Cloud-init grows the guest partition on first boot."
  type        = number
  default     = 21474836480
}
