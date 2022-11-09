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

variable "VOLUME_COUNT" {
  description = "Number of volumes to launch. "
  default     = 1
}

variable "VOLUME_CAPACITY" {
   type = number
   description = "destination for the record"
}

variable "volume_name" {
  type        = string
  default = "perf-volume"
  description = "destination for the record"
}
variable "VOLUME_PROFILE" {
  default = ""
}

variable "ZONE" {
  default = "us-south-1"
}
variable "IOPS" {
   type = number
   description = "destination for the record"
}
