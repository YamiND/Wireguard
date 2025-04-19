# WireGuard VPN with Terraform & Ansible <!-- omit from toc -->

[![Terraform](https://img.shields.io/badge/Terraform-1.11-blue)](https://www.terraform.io/) [![Ansible](https://img.shields.io/badge/Ansible-2.15-green)](https://www.ansible.com/) [![Alma Linux](https://img.shields.io/badge/AlmaLinux-9-red)](https://almalinux.org/) [![License](https://img.shields.io/badge/License-GPLv3-lightgrey)](https://www.gnu.org/licenses/gpl-3.0.en.html)

A minimal, “no‑frills” deployment of a WireGuard VPN server on Proxmox using Terraform and Ansible. This setup spins up a VM template via Terraform and applies a WireGuard configuration via Ansible — no web UI or extra bells and whistles.

---

## Table of Contents <!-- omit from toc -->
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Terraform Setup](#terraform-setup)
- [Cloud‑Init Template Creation](#cloudinit-template-creation)
- [Terraform Deployment](#terraform-deployment)
- [Connecting Clients](#connecting-clients)


## Features

- **Automated VM provisioning** on Proxmox via Terraform  
- **Cloud‑Init** template creation for AlmaLinux 9  
- **Idempotent** Ansible playbook to install & configure WireGuard  
- **Client file generation** output of client `.conf` file for easy import  

---

## Prerequisites

- **Proxmox VE** (tested on v8.3.2)  
- **Terraform** ≥ 1.11.4 installed locally  
- **Ansible** ≥ 2.15.12 installed locally  

---

## Terraform Setup

To allow Terraform to interact with Proxmox, you need to create a user with appropriate privileges on a Proxmox node. Run the following commands on a Proxmox host:

```bash
# Create a role with the required privileges
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"

# Create a new user for Terraform access
pveum user add terraform-prov@pve --password SET_PASSWORD_HERE

# Assign the new role to the user at the root level
pveum aclmod / -user terraform-prov@pve -role TerraformProv

```

---

## Cloud‑Init Template Creation

To prepare an AlmaLinux 9 cloud-init template for use in Proxmox:

```bash
# Download the AlmaLinux 9 cloud image, I used a local mirror
wget https://mirrors.bmcc.edu/alma/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2

# Create a new VM (ID 9000) with 4GB RAM and a virtual NIC on the 'LAN' bridge
qm create 9000 --memory 4096 --net0 virtio,bridge=LAN --scsihw virtio-scsi-pci

# Import the downloaded QCOW2 image as a SCSI disk, replace "vSAN" with your storage pool name
qm set 9000 --scsi0 vSAN:0,import-from=/root/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2

# Attach a cloud-init drive, replace vSAN again to match storage name
qm set 9000 --ide2 vSAN:cloudinit

# Set the boot device to the imported SCSI disk
qm set 9000 --boot order=scsi0

# Enable serial console access
qm set 9000 --serial0 socket --vga serial0

# Convert the VM to a reusable template
qm template 9000

```

---

## Terraform Deployment

Before initializing and applying your Terraform configuration, export the required Proxmox credentials on your local machine:

```bash
export PM_USER="terraform-prov@pve"
export PM_PASS="SET_PASSWORD_HERE"
```

Now run the following commands:

```bash
terraform init
terraform apply
```

As part of the terraform apply an ansible script should run to provision your virtual machine with wireguard.

---

## Connecting Clients

After running the Terraform/Ansible playbook, a client configuration file will be exported to your local `~/Downloads` folder. This file should contain everything you need to connect your device to the VPN.

You should find a file in your `Downloads` folder with your ip address followed by wg.conf. You will need a wireguard client, and then import the data from the .conf file into your client. 

Should the connection fail, verify the server public key and client private key in your configuration file to what is in /etc/wireguard on your server. Also verify public IP/port forwarding is correct, or any external firewall rules that may be in the way.