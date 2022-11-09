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
# number  = false
 special = false
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.SSH_KEY_NAME
}

resource "ibm_is_instance" "vsi3" {
  count        = var.instance_count
  name         = "${var.instance_name}-vsi3-${count.index}-aio-iop128-tcm"
  image        = var.IMAGE_ID
  profile      = "${var.INSTANCE_PROFILE}"
  vpc          = var.VPC_ID
  zone         = var.ZONE
  keys         = [data.ibm_is_ssh_key.sshkey.id]
  volumes      = var.VOLUME_ID
  user_data = "${data.cloudinit_config.cloud-init-config.rendered}"
  auto_delete_volume = false

  primary_network_interface {
    subnet = var.SUBNET_ID
  }
  timeouts {
    create = var.instance_create_timeout
    delete = var.instance_delete_timeout
  }
}

#resource "ibm_is_instance_volume_attachment" "example" {
#  instance = ibm_is_instance.vsi3.id
#
#  count        = var.volume_count
#  name         = "volume-attach-${count.index}"
#  volume       = var.VOLUME_ID[count.index]
##  volume       = var.VOLUME_ID
#
#  // it is recommended to keep the delete_volume_on_attachment_delete as false here otherwise on deleting attachment, existing volume will also get deleted
#
#  delete_volume_on_attachment_delete = false
#  delete_volume_on_instance_delete   = false
#}