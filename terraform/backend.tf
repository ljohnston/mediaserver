terraform {

  #
  # NOTE: the namespace here is not my tenancy namespace, but
  # the bucket namespace randomly assigned by OCI when the bucket
  # gets created. Use 'oci os bucket get --bucket-name=...' to
  # find the namespace.
  #

  backend "oci" {
    bucket               = "terraform-state"
    namespace            = "axwrl1op9z5o"
    region               = "us-phoenix-1"
    key                  = "terraform.tfstate"

    auth                 = "APIKey"

    workspace_key_prefix = "mediaserver"
  }
}

