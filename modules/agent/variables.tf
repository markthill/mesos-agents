variable "mesos_type" { type = string}
variable "mesos_image_id" { type = string}
variable "key_pair_name" { type = string }
variable "instance_profile_name" { type = string}
variable "security_groups" { type = list(string) }
variable "instance_type" { type = string}
variable "cluster_id" { type = string }
variable "cluster_group" { type = string }
variable "group_version" { type = string }
variable "asg_min_size" {
    type = string
    default = 1
}
variable "asg_max_size" {
    type = string
    default = 4
}
variable "asg_desired_capacity" {
    type = string
    default = 1
}
variable "environment" { type = string }
variable "azs" {type = list}
variable "region" { type = string }