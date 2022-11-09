provider "ibm" {
  ibmcloud_api_key   = var.api_key
  region             = var.region
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
  name = var.key_name
}

##
## zone1:
##
#resource "ibm_is_instance" "vsi1" {
#  count        = var.instance_count
#  name         = "${var.instance_name}-vsi1-${count.index}-${random_string.rand_name.result}"
#  image        = var.image_id
#  profile      = var.profile
#  vpc          = var.vpc_id
#  zone         = var.zone1
#  wait_before_delete = var.wait_delete
#  keys         = [data.ibm_is_ssh_key.sshkey.id]
#  user_data    = templatefile("./user-data.tpl",{region = var.region, zone = var.zone1, group = var.group, ordinal = var.ordinal, sku = var.sku, service= var.service, test_provision = var.test_provision, test_terminate = var.test_terminate, test_data = var.test_data, destination = var.destination, uuid = var.uuid, access_key = var.IBMCLOUD_ACCESS_KEY_ID, secret_key = var.IBMCLOUD_SECRET_ACCESS_KEY})
#
#  primary_network_interface {
#    subnet = var.subnet1_id
#    # security_groups = [ibm_is_security_group.sg1.id]
#  }
#  timeouts {
#    create = var.instance_create_timeout
#    delete = var.instance_delete_timeout
#  }
#}


#
# zone2:
#
//resource "ibm_is_instance" "vsi2" {
//  count        = var.instance_count
//  name         = "${var.instance_name}-vsi2-${count.index}-${random_string.rand_name.result}"
//  image        = var.image_id
//  profile      = var.profile
//  vpc          = var.vpc_id
//  zone         = var.zone2
//  wait_before_delete = var.wait_delete
//  keys         = [data.ibm_is_ssh_key.sshkey.id]
//  user_data    = templatefile("./user-data.tpl",{region = var.region, group = var.group, zone = var.zone2, ordinal = var.ordinal, sku = var.sku, service= var.service, test_provision = var.test_provision, test_terminate = var.test_terminate, test_data = var.test_data, destination = var.destination, uuid = var.uuid, access_key = var.IBMCLOUD_ACCESS_KEY_ID, secret_key = var.IBMCLOUD_SECRET_ACCESS_KEY})
//
//  primary_network_interface {
//    subnet = var.subnet2_id
//  }
//  timeouts {
//    create = var.instance_create_timeout
//    delete = var.instance_delete_timeout
//  }
//}


#
# zone3:
#

resource "ibm_is_floating_ip" "vsi3_floating_ip" {
  name = "fip-gartner"
  target = ibm_is_instance.vsi3.0.primary_network_interface.0.id
  tags   = [ "acadia_vsi_2_vpc" ]
}
resource "ibm_is_security_group" "vsi3_security_group" {
  name = "sg-gartner"
  vpc  = var.vpc_id
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
    group     = ibm_is_security_group.vsi3_security_group.id
    direction = "inbound"
    remote    = "0.0.0.0/0"

    tcp {
      port_min = 22
      port_max = 22
    }
}
resource "ibm_is_security_group_rule" "vsi3_security_group_rule_tcp_http" {
  group     = ibm_is_security_group.vsi3_security_group.id
  direction = "inbound"
  tcp {
      port_min = 8080
      port_max = 8080
  }
}
resource "ibm_is_security_group_rule" "tcp_80" {
  group     = ibm_is_security_group.vsi3_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "tcp_443" {
  group     = ibm_is_security_group.vsi3_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "tcp_53" {
  group     = ibm_is_security_group.vsi3_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "udp_443" {
  group     = ibm_is_security_group.vsi3_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "ssh" {
  group     = ibm_is_security_group.vsi3_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "ping" {
  group     = ibm_is_security_group.vsi3_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
  }
}

resource "ibm_is_instance" "vsi3" {
  count        = var.instance_count
  name         = "${var.instance_name}-vsi3-${count.index}-${random_string.rand_name.result}"
  image        = var.image_id
  profile      = var.profile
  vpc          = var.vpc_id
  zone         = var.zone3
#   wait_before_delete = var.wait_delete
  keys         = [data.ibm_is_ssh_key.sshkey.id]
  user_data    = templatefile("./user-data.tpl",{region = var.region, group = var.group, zone = var.zone3, ordinal = var.ordinal, sku = var.sku, service= var.service, test_provision = var.test_provision, test_terminate = var.test_terminate, test_data = var.test_data, destination = var.destination, uuid = var.uuid, access_key = var.IBMCLOUD_ACCESS_KEY_ID, secret_key = var.IBMCLOUD_SECRET_ACCESS_KEY})

  primary_network_interface {
    subnet = var.subnet3_id
  }
  timeouts {
    create = var.instance_create_timeout
    delete = var.instance_delete_timeout
  }
}

