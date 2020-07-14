terraform {
  backend "s3" {
    bucket = "terraform-remote-state-mesos"
    region = "us-east-1"
  }
}

//data "terraform_remote_state" "agent-group" {
//  backend = "s3"
//  config = {
//    bucket = "terraform-remote-state-mesos"
//    key    = "cluster/mesos/${var.cluster_group}.tfstate"
//    region = "us-east-1"
//    dynamodb_table = "terraform-state-locking"
//  }
//}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_vpc" "default_vpc" {
  tags = { "Default" = "true" }
}

data "aws_subnet" "subnet_us_east_1d" {
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.default_vpc.id}"] # insert value here
  }
  filter {
    name = "availability-zone"
    values = ["us-east-1d"]
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_iam_instance_profile" "mesos_ec2_instance_profile" {
  name = "mesos_ec2_instance_profile_${terraform.workspace}"
}

data "aws_security_group" "mesos_security_group" {
  tags = { "Name" = "mesos-shared-security-group_${terraform.workspace}" }
}

module "mesos-agent" {
    source = "./modules/agent"

    mesos_type = "Agent"
    mesos_image_id = var.mesos_image_id
    key_pair_name = var.key_pair_name
    instance_profile_name = data.aws_iam_instance_profile.mesos_ec2_instance_profile.name
    security_groups = [data.aws_security_group.mesos_security_group.id]
    instance_type = var.mesos_instance_type
    cluster_id = "c328d8515ddb214d"
    asg_min_size = var.minimum_capacity
    asg_max_size = var.maximum_capacity
    asg_desired_capacity = var.desired_capacity
    cluster_group = var.cluster_group
    group_version = var.group_version
    environment = terraform.workspace
}