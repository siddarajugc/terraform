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

variable "api_key" {
  default = ""
}

variable "generation" {
  default = 2
}

variable "name_prefix" {
  default = ""
}

variable "region" {
  default = ""
}

variable "pubkey" {
  default  = ""
}

variable "key_name" {
  description = "Public SSH keys path to be included in the ~/.ssh/authorized_keys file for the default user on the instance. "
  default  = ""
}

variable "vpc_id" {
  description = "VPC"
  default = ""
}

#variable "subnet1_id" {
#  description = "subnet"
#  default = ""
#}

#variable "subnet2_id" {
#  description = "subnet"
#  default = ""
#}

variable "subnet3_id" {
  description = "subnet"
  default = ""
}

#variable "zone1" {
#  default = ""
#}

#variable "zone2" {
#  default = ""
#}

variable "zone3" {
  default = "us-south-3"
}

variable "image_id" {
  default = ""
}

variable "profile" {
  default = ""
}

variable "user_data" {
  description = "Provide your own base64-encoded data to be used by Cloud-Init to run custom scripts or provide custom Cloud-Init configuration. "
  default     = ""
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

# variable "wait_delete" {
#   description = "Wait before delete flag"
#   default     = false
# }
