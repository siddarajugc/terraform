output "VSI_ID" {
  value = ibm_is_instance.vsi3[*]
}
 output "cloud-init-cruft" {
  value = "${data.cloudinit_config.cloud-init-config.rendered}"
 }

#output "vsi-floating-ip" {
#  value = "${ibm_is_floating_ip.vsi3_floating_ip.address}"
#}