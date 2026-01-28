data "external" "client_ip" {
  program = ["sh", "-c", "echo \"{\\\"ip\\\": \\\"$(curl -s ifconfig.me)\\\"}\""]
}

resource "oci_bastion_bastion" "this" {
  compartment_id   = var.compartment_ocid
  name             = "dev-bastion"
  bastion_type     = "STANDARD"
  target_subnet_id = oci_core_subnet.private.id
  client_cidr_block_allow_list = [
    "10.0.0.0/16",
    "${data.external.client_ip.result.ip}/32"
  ]
}

resource "oci_bastion_session" "http_forward" {
  display_name           = "http-port-forward"
  bastion_id             = oci_bastion_bastion.this.id
  key_type               = "PUB"
  session_ttl_in_seconds = 10800

  key_details {
    public_key_content = file(var.public_key_path)
  }

  target_resource_details {
    session_type                         = "PORT_FORWARDING"
    target_resource_port                 = 80
    target_resource_id                   = oci_core_instance.app.id
  }
}

resource "oci_bastion_session" "ssh_forward" {
  display_name           = "ssh-port-forward"
  bastion_id             = oci_bastion_bastion.this.id
  key_type               = "PUB"
  session_ttl_in_seconds = 10800

  key_details {
    public_key_content = file(var.public_key_path)
  }

  target_resource_details {
    session_type                         = "PORT_FORWARDING"
    target_resource_port                 = 22
    target_resource_id                   = oci_core_instance.app.id
  }
}

resource "oci_bastion_session" "plex_forward" {
  display_name           = "plex-port-forward"
  bastion_id             = oci_bastion_bastion.this.id
  key_type               = "PUB"
  session_ttl_in_seconds = 10800

  key_details {
    public_key_content = file(var.public_key_path)
  }

  target_resource_details {
    session_type                         = "PORT_FORWARDING"
    target_resource_port                 = 32400
    target_resource_id                   = oci_core_instance.app.id
  }
}

