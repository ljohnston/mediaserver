terraform {
  required_version = ">= 1.3"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
}

# All of these read from ~/.oci/config (see tf.sh).
# NOTE: 'private_key_path' here is the OCI pem key, not to be confused
#       with the variable 'private_key_path', which is our ssh key.
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.key_file
  region           = var.region
}

