data "aws_ami" "ecs_os" {
  most_recent                   = true
  owners                        = ["amazon", "self"]

  filter {
    name                        = "name"
    values                      = ["amzn-ami*amazon-ecs-optimized"]
  }

  filter {
    name                        = "architecture"
    values                      = [var.AWS_INSTANCE_ARCH]
  }

  filter {
    name                        = "virtualization-type"
    values                      = ["hvm"]
  }
}


resource "aws_key_pair" "ecs_key_pair" {
  key_name                      = "${local.cluster_name}-key1"
  public_key                    = var.PUBLIC_KEY
}


resource "aws_launch_configuration" "ecs_lc" {
  for_each                      = var.STACKS
  name_prefix                   = "${var.ENV}_launch_configuration-${each.key}-"
  image_id                      = data.aws_ami.ecs_os.id
  instance_type                 = "${var.AWS_INSTANCE_TYPE}"
  lifecycle {
    create_before_destroy       = true
  }
  iam_instance_profile          = aws_iam_instance_profile.ecs_instance_role_profile.name
  security_groups               = [aws_security_group.hello_task_sg.id]
  key_name                      = aws_key_pair.ecs_key_pair.key_name
  user_data                     = <<EOF
#! /bin/bash
sudo apt-get update
sudo echo "ECS_CLUSTER=${local.cluster_name}-${each.key}" >> /etc/ecs/ecs.config
EOF
}


resource "aws_autoscaling_group" "ecs_asg1" {
  for_each                      = var.STACKS
  name                          = "ecs-asg1-${each.key}"
  launch_configuration          = aws_launch_configuration.ecs_lc[each.key].name
  min_size                      = 1
  max_size                      = 2
  desired_capacity              = 2
  health_check_type             = "ELB"
  health_check_grace_period     = 300
  vpc_zone_identifier           = aws_subnet.private_subnet.*.id

  target_group_arns             = [aws_lb_target_group.hello_tg1[each.key].arn]
  protect_from_scale_in         = true
  lifecycle {
    create_before_destroy       = true
  }
}