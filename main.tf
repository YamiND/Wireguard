terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc8"
    }
  }
}

provider "proxmox" {
  pm_api_url = "${var.proxmox_api_host}"
  pm_tls_insecure = true 
}

resource "proxmox_vm_qemu" "wireguard" {
  name        = var.vm_name
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone  = true

  os_type = "cloud-init"
  cores   = var.cpu
  sockets = 1
  memory  = var.memory
  scsihw  = "virtio-scsi-pci"
  boot = "order=scsi0"
  bootdisk = "scsi0"
  agent = 1

  # Most cloud-init images require a serial device for their display
  serial {
    id = 0
  }

  disks {
    scsi {
        scsi0 {
          disk {
            size     = var.disk_size
            storage  = var.storage_pool
          }
        }
      }
      ide {
        ide2 {
            cloudinit {
                storage = "${var.cloudinit_cdrom_storage}"
            }
        }
      }
  }

  network {
    id = 0
    model = "virtio"
    bridge = var.network_bridge
  }

  ipconfig0 = "ip=${var.vm_ip}/${var.vm_cidr},gw=${var.gateway}"

  ciuser     = var.cloud_init_user
  cipassword = var.cloud_init_password
  sshkeys    = file("${var.ssh_pubkey_path}")
}

resource "null_resource" "ansible_provision" {
  depends_on = [proxmox_vm_qemu.wireguard]

  provisioner "local-exec" {
     command = <<EOT
      ssh-keygen -R ${var.vm_ip} || true

      until ssh -o StrictHostKeyChecking=no -i ${var.ssh_private_key_path} ${var.cloud_init_user}@${var.vm_ip} 'echo SSH ready'; do
        echo "Waiting for SSH..."
        sleep 5
      done

      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key ${var.ssh_private_key_path} -i "${var.vm_ip}," main.yml -e "ansible_user=${var.cloud_init_user}"
      EOT
  }
}