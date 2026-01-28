locals {
  cloud_init_script = <<-SCRIPT
    #!/bin/bash
    set -e
    iptables -F
    iptables -X
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -s ${var.vcn_cidr} -j ACCEPT
    netfilter-persistent save

    # The always free amd OCI instances only have 1GB of memory.
    # Add swap and set docker compose resource limits to help.
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

    echo "set -o vi" >> /home/ubuntu/.bashrc

    echo "Private instance initialization complete."
SCRIPT

  nat_cloud_init_script = <<-SCRIPT
    #!/bin/bash
    set -euxo pipefail

    # Enable IPv4 forwarding
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-nat.conf
    sysctl --system

    # Clear existing FORWARD rules
    iptables -F FORWARD
    iptables -t nat -F POSTROUTING

    # NAT: MASQUERADE for private subnet
    iptables -t nat -A POSTROUTING -s "${var.private_cidr}" -o ens3 -j MASQUERADE

    # Allow traffic from private subnet to anywhere
    iptables -A FORWARD -s "${var.private_cidr}" -j ACCEPT

    # Allow return traffic from anywhere to private subnet (stateful)
    iptables -A FORWARD -d "${var.private_cidr}" -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Optional: Reject anything else explicitly (adds clarity)
    iptables -A FORWARD -j REJECT --reject-with icmp-host-prohibited

    # Persist rules
    netfilter-persistent save

    echo "set -o vi" >> /home/ubuntu/.bashrc

    echo "NAT instance initialization complete."
SCRIPT

  volumes = {
    "disk1" = { size = 50, display_name = "data" }
    "disk2" = { size = 50, display_name = "snapraid_parity" }
    "disk3" = { size = 50, display_name = "snapraid_data1" }
    "disk4" = { size = 50, display_name = "snapraid_data2" }
  }
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "app" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "private-app"
  shape               = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.public_key_path)
    user_data           = base64encode(local.cloud_init_script)
  }
}

resource "oci_core_volume" "volumes" {
  for_each            = local.volumes
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = each.value.display_name
  size_in_gbs         = each.value.size
}

resource "oci_core_volume_attachment" "data_volume_attach" {
  for_each        = oci_core_volume.volumes
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.app.id
  volume_id       = each.value.id
}

resource "oci_core_instance" "nat" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "nat-instance"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 1
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.public.id
    assign_public_ip       = true
    skip_source_dest_check = true
    private_ip             = var.vnic_private_ip
  }

  metadata = {
    ssh_authorized_keys = file(var.public_key_path)
    user_data           = base64encode(local.nat_cloud_init_script)
  }
}


