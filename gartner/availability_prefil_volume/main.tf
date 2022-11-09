provider "ibm" {
  ibmcloud_api_key   = var.CLOUD_API_KEY
  region             = var.REGION
}
terraform {
  required_providers {
        ibm = {
          source = "IBM-Cloud/ibm"
          version = "1.42.0"
        }
      }
  }

resource "random_string" "rand_name" {
 length  = 8
 upper   = false
 #number  = false
 special = false
}

resource "ibm_is_volume" "acadia_prefil_volume" {
  count    = var.VOLUME_COUNT
  name     = "${var.volume_name}-${count.index}-${random_string.rand_name.result}"
  profile  = var.VOLUME_PROFILE
  zone     = "${var.ZONE}"
  iops     = var.IOPS
  capacity = "${var.VOLUME_CAPACITY}"
}
