resource "aws_lb" "hello_lb" {
  for_each              = var.STACKS
  name                  = "${var.ENV}-hello-lb-${each.key}"
  internal              = false
  load_balancer_type    = "application"
  subnets               = aws_subnet.public_subnet.*.id
  security_groups       = [aws_security_group.lb_sg1.id]

  access_logs {
    bucket              = aws_s3_bucket.bkt_logs_lb[each.key].bucket
    prefix              = "hello-lb-${each.key}"
    enabled             = true
  }

  tags = {
    Name                = "${var.ENV}-hello-lb-${each.key}"
    Environment         = "${var.ENV}"
  }

  depends_on            = [aws_s3_bucket.bkt_logs_lb]
}

resource "aws_lb_target_group" "hello_tg1" {
  for_each              = var.STACKS
  name                  = "hello-target-group-${each.key}"
  port                  = 80
  protocol              = "HTTP"
  vpc_id                = aws_vpc.vpc1.id
  target_type           = "instance"

  health_check {
    path                = "/"
    healthy_threshold   = 3
    timeout             = 30
    interval            = 300
    matcher             = "200,301,302"
  }
}

resource "aws_lb_listener" "hello_http_listener" {
  for_each              = var.STACKS
  load_balancer_arn     = aws_lb.hello_lb[each.key].id
  port                  = "80"
  protocol              = "HTTP"

  default_action {
    target_group_arn    = aws_lb_target_group.hello_tg1[each.key].id
    type                = "forward"
  }
}

resource "aws_lb_listener" "hello_https_listener" {
  for_each              = var.STACKS
  load_balancer_arn     = aws_lb.hello_lb[each.key].id
  port                  = "443"
  protocol              = "HTTPS"
  ssl_policy            = "ELBSecurityPolicy-2016-08"
  certificate_arn       = aws_acm_certificate.cert_domain.arn

  default_action {
    target_group_arn    = aws_lb_target_group.hello_tg1[each.key].id
    type                = "forward"
  }
  depends_on            = [aws_acm_certificate.cert_domain, aws_acm_certificate_validation.vld_domain, aws_route53_record.record_domain]
}

resource "aws_route53_record" "cname_lb" {
  for_each              = var.STACKS
  zone_id               = data.aws_route53_zone.zone_domain_external.zone_id
  name                  = "${each.key}"
  type                  = "CNAME"
  ttl                   = "5"
  weighted_routing_policy {
    weight              = 10
  }
  set_identifier        = "app-${each.key}"
  records               = [aws_lb.hello_lb[each.key].dns_name]
}

resource "aws_route53_record" "svc_domain" {
  zone_id                   = data.aws_route53_zone.zone_domain_external.zone_id
  name                      = "${var.SERVICE_DOMAIN}"
  type                      = "CNAME"
  ttl                       = "5"
  weighted_routing_policy {
    weight                  = 10
  }
  set_identifier            = "svcdomain"
  records                   = [aws_lb.hello_lb[var.SERVICE_STACK].dns_name]
}
