variable "IBMCLOUD_ACCESS_KEY_ID" {
    description = "target access key"
    default = ""
    type = string
 }

variable "IBMCLOUD_SECRET_ACCESS_KEY" {
    description = "secret for access key"
    default = ""
    type = string
}

variable "uuid" {
  default = ""
}

variable "CLOUD_API_KEY" {
  default = ""
}

variable "generation" {
  default = 2
}

variable "name_prefix" {
  default = ""
}

variable "REGION" {
  default = ""
}

variable "pubkey" {
  default  = ""
}

variable "SSH_KEY_NAME" {
  description = "Public SSH keys path to be included in the ~/.ssh/authorized_keys file for the default user on the instance. "
  default  = ""
}

variable "VPC_ID" {
  description = "VPC"
  default = ""
}
variable "SUBNET_ID" {
  description = "subnet"
  default = ""
}
variable "ZONE" {
  default = "us-south-3"
}

variable "IMAGE_ID" {
  default = ""
}

variable "INSTANCE_PROFILE" {
  default = ""
}

variable "USER_DATA_FILE" {
  description = "Provide your own base64-encoded data to be used by Cloud-Init to run custom scripts or provide custom Cloud-Init configuration. "
  default     = ""
  type = string
}

variable "source_type" {
  description = "The source type for the instance. "
  default     = "image"
}

variable "instance_create_timeout" {
  description = "Timeout setting for creating instance. "
  default     = "300s"
}

variable "instance_delete_timeout" {
  description = "Timeout setting for creating instance. "
  default     = "180s"
}

variable "instance_count" {
  description = "Number of instances to launch. "
  default     = 1
}

variable "instance_name" {
  description = "Name of instances to launch. "
  default     = "acadia-terraform-gartner"
}

variable "service" {
  type        = string
  description = "service for testing"
  default     = ""
}

variable "sku" {
  type        = string
  description = "sku for testing"
  default     = ""
}

variable "group" {
  type        = number
  description = "group number"
}

variable "ordinal" {
  type        = number
  description = "ordinal number"
}

variable "test_provision" {
  type        = string
  description = "test type for resource provision"
}

variable "test_terminate" {
  type        = string
  description = "test type for resource terminate"
}

variable "test_data" {
  type        = string
  description = "test type for resource data"
}

variable "COS_END_POINT" {
  type        = string
  description = "destination for the record"
}

#variable "VOLUME_CAPACITY" {
#   type = number
#   description = "destination for the record"
#}

variable "volume_name" {
  type        = string
  default = "gartner-volume"
  description = "destination for the record"
}
variable "VOLUME_PROFILE" {
  default = ""
}
variable "vol_iops" {
  default = 500
  type = number
}

variable "BLOCK_SIZE" {
    description = "block size for FIO jobs"
    default = "4k"
}

variable "IODEPTH" {
   description = "The io depth to use"
   type = string
   default = "128"
}

variable "NUMBER_JOBS" {
    description = "number of jobs for fio jobs"
    default = "1"
    type = string
}

variable "RUNTIME" {
   description = "Run time for fio"
   type = number
   default = 5
}
variable "BUCKET_NAME" {
    description = "number of COS bucket"
    default = ""
}
variable "VOLUME_ID" {
  description = "Volume ID's"
  type        = list(string)
}
variable "volume_count" {
    description = "number of volumes"
    default =2
    type = number

}

variable "TARGETS" {
   description = "The target disks"
   type = string
   default = "/dev/vdd"
}

variable "RW_MODE" {
   description = "Modes to run fio in"
   type = string
   default = "randread"
}

variable "JOBS" {
   description = "Number of jobs"
   type = string
   default = "1"
}

variable "RWMIX" {
   description = "The read write mix for the run."
   type = string
   default = "50 50"
}

variable "LOOPS" {
    description = "Number of times the benchmark is run"
    default =1
    type = number

}

variable "FIO_ENGINE" {
    description = "The fio engine to use"
    default = "libaio"
    type = string
}
