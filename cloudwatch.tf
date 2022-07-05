resource "aws_cloudwatch_log_group" "cw_log_group" {
  for_each          = var.STACKS
  name              = "/ecs/hello-app-${each.key}"

  tags = {
    Name            = "${var.ENV}-cw-log-group-${each.key}"
    Environment     = "${var.ENV}"
  }
}