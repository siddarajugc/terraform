
locals {
  fio_script_cfg = templatefile("cloud-init-script.tpl", {
        TARGETS    =  var.TARGETS,
        RW_MODE       = var.RW_MODE,
        LOOPS      = var.LOOPS,
        IODEPTH    = var.IODEPTH,
        JOBS       = var.NUMBER_JOBS,
        RUNTIME    = var.RUNTIME,
        RWMIX      = var.RWMIX,
        BLOCK_SIZE = var.BLOCK_SIZE,
        FIO_ENGINE = var.FIO_ENGINE,
        COS_ACCESS_KEY = var.IBMCLOUD_ACCESS_KEY_ID,
        COS_SECRET_KEY = var.IBMCLOUD_SECRET_ACCESS_KEY
        destination = var.destination
        BUCKET_NAME = var.BUCKET_NAME
        })
}

data "local_file" "install_packages" {
  filename = "${path.module}/cloud-init-packages.tpl"
}

data "local_file" "run_scripts" {
  filename = "${path.module}/cloud-init-run-script.tpl"
}

data "cloudinit_config" "cloud-init-config" {
  base64_encode = false
  gzip          = false

  part {
    content_type = "text/cloud-config"
    content      = data.local_file.install_packages.content
 }

 part {
    content_type = "text/cloud-config"
    content      = local.fio_script_cfg
 }

 part {
    content_type = "text/cloud-config"
    content = data.local_file.run_scripts.content
  }
}