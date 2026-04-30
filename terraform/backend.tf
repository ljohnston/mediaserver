terraform {

  #
  # NOTE: the namespace here is not a tenancy namespace, but
  # the bucket namespace randomly assigned by OCI when the bucket
  # gets created. Use 'oci os bucket get --bucket-name=...' or the
  # OCI console to get the namespace.
  #

  backend "oci" {
    bucket               = "terraform-state"
    namespace            = "axwrl1op9z5o"
    region               = "us-phoenix-1"
    key                  = "terraform.tfstate"

    # All the details required for auth are set as TF_VAR_...
    # variables via tf.sh.
    auth                 = "APIKey"

    workspace_key_prefix = "mediaserver"
  }
}

