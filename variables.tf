variable "key_pair_name" {
  default = "ecs-key-pair-us-east-1"
}
variable "mesos_image_id" {
  default = "ami-039a49e70ea773ffc"
}
variable "mesos_instance_type" {
  default = "t3.micro"
}
variable "cluster_id" {
  default = ""
}
variable "cluster_group" {type = string }
variable "group_version" {type = string }
variable "desired_capacity" {
  default = "1"
}
variable "minimum_capacity" {
  default = "0"
}
variable "maximum_capacity" {
  default = "4"
}
