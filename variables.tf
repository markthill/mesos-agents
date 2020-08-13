variable "default_region" {
  default = "us-east-1"
}
variable "default_az" {
  default = "a"
}
variable "key_pair_name" {
  default = "ecs-key-pair"
}

variable "mesos_instance_type" {
  default = "t3.medium"
}
variable "cluster_id" {
}
variable "cluster_group" {type = string }
variable "group_version" {type = string }
variable "desired_capacity" {
  default = "3"
}
variable "minimum_capacity" {
  default = "0"
}
variable "maximum_capacity" {
  default = "4"
}
variable "availability_zones" {
  type    = map
  default = {
    "us-east-1" = ["us-east-1a", "us-east-1b", "us-east-1c"]
    "us-east-2" = ["us-east-2a", "us-east-2b", "us-east-2c"]
  }
}
variable "mesos_image_id" {
  type    = map
  default = {
    "us-east-1" = "ami-039a49e70ea773ffc"
    "us-east-2" = "ami-04781752c9b20ea41"
  }
}