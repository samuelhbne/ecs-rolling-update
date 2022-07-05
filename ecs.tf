locals {
  cluster_name                      = "${var.ENV}-hello-cluster"
}  


resource "aws_ecs_cluster" "hello_cluster" {
  for_each                          = var.STACKS
  name                              = "${local.cluster_name}-${each.key}"
  //capacity_providers                = [aws_ecs_capacity_provider.cap_provider[each.key].name]

  setting {
    name                            = "containerInsights"
    value                           = "enabled"
  }

  tags = {
    Name                            = "${var.ENV}-hello-cluster-${each.key}"
    Environment                     = "${var.ENV}"
  }
}

resource "aws_ecs_cluster_capacity_providers" "hello_cluster_capacity_providers" {
  for_each                          = var.STACKS
  cluster_name                      = aws_ecs_cluster.hello_cluster[each.key].name
  capacity_providers                = [aws_ecs_capacity_provider.cap_provider[each.key].name]

  default_capacity_provider_strategy {
    base                            = 1
    weight                          = 100
    capacity_provider               = aws_ecs_capacity_provider.cap_provider[each.key].name
  }
}

resource "aws_ecs_capacity_provider" "cap_provider" {
  for_each                          = var.STACKS
  name                              = "cap-provider-${each.key}"
  auto_scaling_group_provider {
    auto_scaling_group_arn          = aws_autoscaling_group.ecs_asg1[each.key].arn
    managed_termination_protection  = "ENABLED"

    managed_scaling {
      status                        = "ENABLED"
      instance_warmup_period        = 300
      minimum_scaling_step_size     = 1
      maximum_scaling_step_size     = 2
      target_capacity               = 2
    }
  }
}


resource "aws_ecs_task_definition" "hello_ecs_td" {
  for_each                          = var.STACKS
  family                            = "hello-app-${each.key}"
  network_mode                      = "bridge"
  requires_compatibilities          = ["EC2"]
  cpu                               = 256
  memory                            = 512

  container_definitions             = <<DEFINITION
[
  {
    "name": "hello-app-${each.key}",
    "image": "nginx:${each.value}",
    "cpu": 256,
    "memory": 512,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": { 
        "awslogs-group" : "/ecs/hello-app-${each.key}",
        "awslogs-region": "${var.AWS_REGION}"
      }
    }
  }
]
DEFINITION
}


resource "aws_ecs_service" "hello_service" {
  for_each                          = var.STACKS
  name                              = "hello-service-${each.key}"
  cluster                           = aws_ecs_cluster.hello_cluster[each.key].id
  task_definition                   = aws_ecs_task_definition.hello_ecs_td[each.key].arn
  desired_count                     = 1
  launch_type                       = "EC2"

  ordered_placement_strategy {
    type                            = "binpack"
    field                           = "cpu"
  }
/*
  network_configuration {
    security_groups                 = [aws_security_group.hello_task_sg.id]
    subnets                         = aws_subnet.private_subnet.*.id
  }
*/
  load_balancer {
    target_group_arn                = aws_lb_target_group.hello_tg1[each.key].id
    container_name                  = "hello-app-${each.key}"
    container_port                  = 80
  }

  lifecycle {
    ignore_changes                  = [desired_count]
  }

  depends_on                        = [aws_lb_listener.hello_http_listener, aws_lb_listener.hello_https_listener]
}