resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "dev-vcn"
  dns_label      = "devvcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "internet-gateway"
}

# We can't replace the default security list on the VCN
# so we'll update it with the rules we need.

resource "oci_core_default_security_list" "default_sl" {
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    description = "Allow all outgoing traffic"
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    description = "Allow SSH"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = var.vcn_cidr
    description = "Allow HTTP within VCN"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.private_cidr
  }
}

#
# Public network config.
#

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  display_name   = "public_rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id

  cidr_block                 = "10.0.0.0/24"
  display_name               = "public-subnet"
  route_table_id             = oci_core_route_table.public_rt.id
  prohibit_public_ip_on_vnic = false
}

#
# Private network config.
#

data "oci_core_vnic_attachments" "nat_vnic_attachments" {
  depends_on = [oci_core_instance.nat]

  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  instance_id         = oci_core_instance.nat.id
}

data "oci_core_vnic" "nat_vnic" {
  vnic_id = data.oci_core_vnic_attachments.nat_vnic_attachments.vnic_attachments[0].vnic_id
}

data "oci_core_private_ips" "nat_private_ips" {
  vnic_id = data.oci_core_vnic.nat_vnic.id
}

resource "oci_core_route_table" "private_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  display_name   = "private_rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.nat_private_ips.private_ips[0].id
  }
}

resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.private_cidr
  display_name               = "private-subnet"
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_security_list.private_sl.id]
  prohibit_public_ip_on_vnic = true
  dns_label                  = "private"
}

resource "oci_core_security_list" "private_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id

  display_name   = "private_subnet_security_list"

  ingress_security_rules {
    source   = var.vcn_cidr
    protocol = "6"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    source   = var.vcn_cidr
    protocol = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    source   = var.vcn_cidr
    protocol = "6"
    tcp_options {
      min = 32400
      max = 32400
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}
