variable "vm_name" {}
variable "proxmox_node" {}
variable "proxmox_api_host" {}
variable "template_name" {}
variable "cpu" { default = 2 }
variable "memory" { default = 4096 }
variable "disk_size" { default = "40G" }
variable "storage_pool" {}
variable "network_bridge" {}
variable "vm_ip" {}
variable "vm_cidr" {}
variable "gateway" {}
variable "cloud_init_user" {}
variable "cloud_init_password" {}
variable "ssh_pubkey_path" {}
variable "cloudinit_cdrom_storage" {}
variable "ssh_private_key_path" {}