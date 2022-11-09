variable "IBMCLOUD_ACCESS_KEY_ID" {
    description = "target access key"
    default = ""
 }

variable "IBMCLOUD_SECRET_ACCESS_KEY" {
    description = "secret for access key"
    default = ""
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
variable "SUBNET_ID_1" {
  description = "subnet"
  default = ""
}
variable "SUBNET_ID_2" {
  description = "subnet"
  default = ""
}
variable "SUBNET_ID_3" {
  description = "subnet"
  default = ""
}
variable "ZONE1" {
  default = "us-south-1"
}

variable "ZONE2" {
  default = "us-south-2"
}
variable "ZONE3" {
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

variable "destination" {
  type        = string
  description = "destination for the record"
}

variable "VOLUME_CAPACITY" {
   type = number
   description = "destination for the record"
}

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
    default = ""
}

variable "IODEPTH" {
    description = "iodepth for FIO jobs"
    default = ""
}

variable "NUMBER_JOBS" {
    description = "number of jobs for fio jobs"
    default = ""
}

variable "RUNTIME" {
    description = "number of jobs for fio jobs"
    default = ""
}
variable "BUCKET_NAME" {
    description = "number of COS bucket"
    default = ""
}
