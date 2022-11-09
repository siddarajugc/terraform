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
resource "ibm_is_volume" "acadia_perf_volume" {
  name     = "${var.volume_name}-${random_string.rand_name.result}"
  profile  = var.VOLUME_PROFILE
  zone     = "${var.ZONE}"
  capacity = "${var.VOLUME_CAPACITY}"
}

resource "ibm_is_instance" "vsi3" {
  count        = var.instance_count
  name         = "${var.instance_name}-vsi3-${count.index}-${random_string.rand_name.result}"
  image        = var.IMAGE_ID
  profile      = "${var.INSTANCE_PROFILE}"
  vpc          = var.VPC_ID
  zone         = var.ZONE
  keys         = [data.ibm_is_ssh_key.sshkey.id]
  volumes = [ ibm_is_volume.acadia_perf_volume.id ]
  auto_delete_volume = true
  user_data    = templatefile(var.USER_DATA_FILE,{ region = var.REGION, group = var.group, zone = var.ZONE, ordinal = var.ordinal, sku = var.sku, service= var.service, test_provision = var.test_provision, test_terminate = var.test_terminate, test_data = var.test_data, destination = var.destination, uuid = var.uuid, access_key = var.IBMCLOUD_ACCESS_KEY_ID, secret_key = var.IBMCLOUD_SECRET_ACCESS_KEY, BS = var.BLOCK_SIZE, IODPTH = var.IODEPTH, NJOBS=var.NUMBER_JOBS, RUNTIME = var.RUNTIME, bucket_name=var.BUCKET_NAME })

  primary_network_interface {
    subnet = var.SUBNET_ID
  }
  timeouts {
    create = var.instance_create_timeout
    delete = var.instance_delete_timeout
  }
}
