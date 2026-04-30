variable "region" {
  type = string
  default = "us-phoenix-1"
}

variable "availability_domain" {
  type = string
  default = "moIN:PHX-AD-3"
}

variable "compartment_ocid" {
  type = string
  default = "ocid1.tenancy.oc1..aaaaaaaarnrgcvyg3cirwqaxisiexplp3igeehmvpqfc2mzohckp7km6fv5q"
}

# These vars read from ~/.oci/config (see tf.sh) {{
variable "user_ocid" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "key_file" {
  type = string
}
# }}

variable "private_key_path" {
  type = string
  default = "~/.ssh/id_ed25519"
}

variable "public_key_path" {
  type = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "local_http_forward_port" {
  type = number
  default = 9080
}

variable "local_ssh_forward_port" {
  type  = number
  default = 9022
}

variable "local_plex_forward_port" {
  type  = number
  default = 32400
}

variable "vcn_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "private_cidr" {
  type = string
  default = "10.0.1.0/24"
}

variable "vnic_private_ip" {
  type = string
  default = "10.0.0.10"
}

