resource "aws_security_group" "lb_sg1" {
  name                  = "${var.ENV}-lb_sg1"
  description           = "ECS Security Group"
  vpc_id                = aws_vpc.vpc1.id

  ingress {
    from_port           = 80
    to_port             = 80
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
  }
  ingress {
    from_port           = 443
    to_port             = 443
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
  }
  egress {
    from_port           = 0
    to_port             = 65535
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
  }
  tags = {
    Name                = "LoadBalancer Security Group"
  }
}

resource "aws_security_group" "hello_task_sg" {
  name                  = "hello-task-security-group"
  vpc_id                = aws_vpc.vpc1.id

  ingress {
    protocol            = "tcp"
    from_port           = 80
    to_port             = 80
    security_groups     = [aws_security_group.lb_sg1.id]
  }

  egress {
    protocol            = "-1"
    from_port           = 0
    to_port             = 0
    cidr_blocks         = ["0.0.0.0/0"]
  }
  tags = {
    Name                = "HelloApp ECS Task Security Group"
  }
}

