

data "template_file" "user_data" {
    template = file("${path.root}/userdata/mesos.tpl")
}

//resource "aws_launch_configuration" "mesos_launch_config" {
//    name = "mesos_${var.mesos_type}_lc_${terraform.workspace}_${var.cluster_id}"
//    key_name = var.key_pair_name
//    image_id = var.mesos_image_id
//    iam_instance_profile = var.instance_profile_name
//    security_groups = var.security_groups
//    instance_type = var.instance_type
//    user_data = base64encode(data.template_file.user_data.template)
//
//    root_block_device {
//        volume_type = "gp2"
//        volume_size = 15
//    }
//}

resource "aws_launch_template" "agent" {
  name = "mesos_${var.mesos_type}_lt_${var.cluster_group}_group-${var.group_version}_${terraform.workspace}_${var.cluster_id}"
  image_id      = var.mesos_image_id
  instance_type = "t2.micro"
  key_name = var.key_pair_name
  user_data = base64encode(data.template_file.user_data.template)
  vpc_security_group_ids = var.security_groups
  iam_instance_profile {
    name = var.instance_profile_name
  }
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 15
    }
  }
}

resource "aws_autoscaling_group" "mesos_asg" {
    name = "mesos_${var.mesos_type}_asg_${var.cluster_group}_${var.group_version}_${terraform.workspace}_${var.cluster_id}"
    availability_zones = ["us-east-1b", "us-east-1c", "us-east-1d"]
    # launch_configuration = aws_launch_configuration.mesos_launch_config.name
    min_size = var.asg_min_size
    max_size = var.asg_max_size
    desired_capacity = var.asg_desired_capacity

    launch_template {
      id      =aws_launch_template.agent.id
      version = "$Latest"
    }

    tag {
        key                 = "Name"
        value               = "mesos_${var.mesos_type}_asg_${var.cluster_group}_group-${var.group_version}_${terraform.workspace}_${var.cluster_id}"
        propagate_at_launch = true
    }
    tag {
        key                 = "Tier"
        value               = "mesos-${var.mesos_type}"
        propagate_at_launch = true
    }
    tag {
        key                 = "ClusterId"
        value               = var.cluster_id
        propagate_at_launch = true
    }
    tag {
        key                 = "Mesos${var.mesos_type}Instance"
        value               = "mesos-${var.mesos_type}-${var.cluster_id}"
        propagate_at_launch = true
    }
    tag {
        key                 = "Environment"
        value               = terraform.workspace
        propagate_at_launch = true
    }
    tag {
        key                 = "ClusterGroup"
        value               = var.cluster_group
        propagate_at_launch = true
    }
    tag {
        key                 = "GroupVersion"
        value               = var.group_version
        propagate_at_launch = true
    }
}
