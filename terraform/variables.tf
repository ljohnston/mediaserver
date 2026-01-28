variable "region" {
  default = "us-phoenix-1"
}

variable "availability_domain" {
  default = "moIN:PHX-AD-3"
}

variable "tenancy_ocid" {
  default = "ocid1.tenancy.oc1..aaaaaaaarnrgcvyg3cirwqaxisiexplp3igeehmvpqfc2mzohckp7km6fv5q"
}

variable "compartment_ocid" {
  default = "ocid1.tenancy.oc1..aaaaaaaarnrgcvyg3cirwqaxisiexplp3igeehmvpqfc2mzohckp7km6fv5q"
}

variable "user_ocid" {
  default = "ocid1.user.oc1..aaaaaaaamkm3fyxom6ydpd3aqld45gm3u2rrsg2m6j2k65xoeuunwablvbsa"
}

variable "fingerprint" {
  default = "7b:94:d4:46:e3:ae:83:b8:89:db:99:6b:ee:fd:0d:4e"
}

variable "private_key_path" {
  default = "~/.ssh/id_ed25519"
}

variable "public_key_path" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "local_http_forward_port" {
  default = 9080
}

variable "local_ssh_forward_port" {
  default = 9022
}

variable "local_plex_forward_port" {
  default = 32400
}

variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

variable "private_cidr" {
  default = "10.0.1.0/24"
}

variable "vnic_private_ip" {
  default = "10.0.0.10"
}

