output "bastion_http_forward_command" {
  value = replace(
    replace(
      oci_bastion_session.http_forward.ssh_metadata.command,
      "<privateKey>",
      var.private_key_path
    ),
    "<localPort>",
    var.local_http_forward_port)
}

output "bastion_ssh_forward_command" {
  value = replace(
    replace(
      oci_bastion_session.ssh_forward.ssh_metadata.command,
      "<privateKey>",
      var.private_key_path
    ),
    "<localPort>",
    var.local_ssh_forward_port)
}

output "bastion_plex_forward_command" {
  value = replace(
    replace(
      oci_bastion_session.plex_forward.ssh_metadata.command,
      "<privateKey>",
      var.private_key_path
    ),
    "<localPort>",
    var.local_plex_forward_port)
}

output "instance_private_ip" {
  value = oci_core_instance.app.private_ip
}

output "nat_instance_public_ip" {
  value = oci_core_instance.nat.public_ip
}


